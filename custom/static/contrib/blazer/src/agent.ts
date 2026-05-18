import chalk from 'chalk';
import { getAffectedTargetsForCommit, expandTargets } from './lib/workflow';
import { runExecution } from './lib/engine';
import { getTargetStatus, type DetailedTargetResult, type TargetStatus, getSpongeId } from './lib/reconciliation';
import { readFileSync, existsSync } from 'fs';
import { getChangedFiles, getCommitInfo } from './lib/jj';
import os from 'os';

/**
 * Normalizes file:// URIs to local absolute paths.
 */
function normalizePath(uri: string): string {
  return uri.startsWith('file://') ? uri.slice(7) : uri;
}

/**
 * Attempts to read the tail of a log file for diagnostic context.
 */
function getLogTail(path: string, lines = 50): string {
  if (!existsSync(path)) return '';
  try {
    const content = readFileSync(path, 'utf-8');
    return content.split('\n').slice(-lines).join('\n');
  } catch {
    return '';
  }
}

/**
 * Handles the 'blazer agent' command for LLM consumption.
 * Outputs Newline-Delimited JSON (NDJSON) for real-time progression.
 */
export async function runAgent(commit: string, flags: { build?: string[], test?: string[], coverage?: number, dryRun?: boolean }) {
  const startTime = Date.now();
  
  // 1. Initial Start Event with System Info
  process.stdout.write(JSON.stringify({ 
    type: 'start', 
    commit, 
    system: {
      user: os.userInfo().username,
      hostname: os.hostname(),
      cwd: process.cwd(),
      platform: os.platform(),
      arch: os.arch(),
    },
    timestamp: new Date().toISOString() 
  }) + '\n');

  // 2. Resolve commit metadata and changed files
  const revisionToQuery = (commit === 'p4base' || commit === '@-') ? '@' : commit;
  
  const [changedFiles, commitLog] = await Promise.all([
    getChangedFiles(commit),
    getCommitInfo(revisionToQuery)
  ]);

  process.stdout.write(JSON.stringify({ 
    type: 'metadata', 
    commit: commitLog,
    changedFilesCount: changedFiles.length,
    changedFiles 
  }) + '\n');

  // 3. Resolve affected targets (Initial discovery)
  const discoveryStartTime = Date.now();
  process.stdout.write(JSON.stringify({ type: 'status', message: 'Evaluating graph extension (Blaze Query)...' }) + '\n');
  
  const targets = await getAffectedTargetsForCommit(commit);
  const discoveryDuration = Date.now() - discoveryStartTime;
  
  let finalTargets = targets;
  if (flags.coverage && flags.coverage > 0) {
    const expansionStartTime = Date.now();
    process.stdout.write(JSON.stringify({ type: 'status', message: `Expanding targets with radius coverage ${flags.coverage}%...` }) + '\n');
    finalTargets = await expandTargets(targets, flags.coverage);
    process.stdout.write(JSON.stringify({ type: 'status', message: `Expansion complete in ${Date.now() - expansionStartTime}ms` }) + '\n');
  }

  const buildTargets = (flags.build && flags.build.length > 0) ? flags.build : (flags.test && flags.test.length > 0 ? [] : finalTargets.buildTargets.map(t => t.label));
  const testTargets = (flags.test && flags.test.length > 0) ? flags.test : (flags.build && flags.build.length > 0 ? [] : finalTargets.testTargets.map(t => t.label));

  if (flags.dryRun) {
    process.stdout.write(JSON.stringify({
      type: 'discovery',
      commit,
      buildTargets,
      testTargets,
      discoveryDurationMs: discoveryDuration
    }) + '\n');
    return;
  }

  process.stdout.write(JSON.stringify({ 
    type: 'execution_start', 
    buildCount: buildTargets.length, 
    testCount: testTargets.length 
  }) + '\n');

  let buildSponge = '';
  let testSponge = '';
  let lastUpdateCount = -1;

  const executionStartTime = Date.now();
  const executionResult = await runExecution(buildTargets, testTargets, {
    onBuildSponge: (link) => { 
      buildSponge = link;
      process.stdout.write(JSON.stringify({ type: 'sponge', phase: 'build', link }) + '\n');
    },
    onTestSponge: (link) => { 
      testSponge = link;
      process.stdout.write(JSON.stringify({ type: 'sponge', phase: 'test', link }) + '\n');
    },
    onStatusUpdate: (bMap, tMap) => {
      const allDone = [...bMap.values(), ...tMap.values()].filter(s => s !== 'PENDING' && s !== 'UNKNOWN');
      const finished = allDone.length;
      
      if (finished > lastUpdateCount) {
        lastUpdateCount = finished;
        process.stdout.write(JSON.stringify({
          type: 'progress',
          passed: allDone.filter(s => s === 'SUCCESSFUL').length,
          failed: allDone.filter(s => s === 'FAILED' || s === 'BROKEN').length,
          skipped: allDone.filter(s => s === 'SKIPPED').length,
          finished,
          total: buildTargets.length + testTargets.length,
          elapsedMs: Date.now() - executionStartTime,
          timestamp: new Date().toISOString()
        }) + '\n');
      }
    },
    extraArgs: ['--noshow_progress', '--noshow_loading_progress']
  });

  const labelToKind = new Map<string, string>();
  [...finalTargets.buildTargets, ...finalTargets.testTargets].forEach(t => labelToKind.set(t.label, t.kind));

  const mapToResult = (label: string, statusMap: Map<string, TargetStatus>, detailedMap: Map<string, DetailedTargetResult>) => {
    const status = statusMap.get(label) || 'UNKNOWN';
    const detailed = detailedMap ? detailedMap.get(label) : undefined;
    
    // Filter for local files that actually exist
    const localOutputs = (detailed?.outputFiles || [])
      .filter(uri => uri.startsWith('file://'))
      .map(uri => uri.slice(7))
      .filter(p => existsSync(p));

    const result: any = {
      label,
      kind: labelToKind.get(label) || 'unknown_rule',
      status,
      outputFiles: localOutputs,
      testSummary: detailed?.testSummary
    };

    if (status === 'FAILED' || status === 'BROKEN') {
      const logFile = localOutputs.find((f: string) => f.endsWith('.log'));
      if (logFile) {
        result.failureTail = getLogTail(logFile);
      }
    }
    return result;
  };

  const finalResults = {
    type: 'result',
    commit,
    system: {
      user: os.userInfo().username,
      hostname: os.hostname(),
      cwd: process.cwd(),
    },
    buildSponge,
    testSponge,
    buildExitCode: executionResult.buildCode,
    testExitCode: executionResult.testCode,
    durationsMs: {
      total: Date.now() - startTime,
      discovery: discoveryDuration,
      execution: Date.now() - executionStartTime,
    },
    builds: buildTargets.sort().map(label => mapToResult(label, executionResult.buildStatusMap, executionResult.buildDetailedMap)),
    tests: testTargets.sort().map(label => mapToResult(label, executionResult.testStatusMap, executionResult.testDetailedMap))
  };

  process.stdout.write(JSON.stringify(finalResults, null, 2) + '\n');

  if (executionResult.buildCode !== 0 || executionResult.testCode !== 0) {
    process.exit(1);
  }
}
