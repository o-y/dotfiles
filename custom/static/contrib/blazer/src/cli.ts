import chalk from 'chalk';
import { getAffectedTargetsForCommit, expandTargets } from './lib/workflow';
import { runExecution } from './lib/engine';
import { getTargetStatus } from './lib/reconciliation';

/**
 * Creates a writer that prepends a prefix to each line of output.
 */
function createPrefixedWriter(prefix: string, prefixColor: (s: string) => string, contentColor: (s: string) => string = (s) => s) {
  let atStartOfLine = true;
  return (data: string) => {
    if (!data) return;
    const lines = data.split('\n');
    for (let i = 0; i < lines.length; i++) {
      // Don't print prefix for a trailing empty line if we just ended with a newline
      if (atStartOfLine && (i < lines.length - 1 || lines[i].length > 0)) {
        process.stdout.write(prefixColor(prefix));
        atStartOfLine = false;
      }
      
      if (lines[i].length > 0) {
        process.stdout.write(contentColor(lines[i]));
      }
      
      if (i < lines.length - 1) {
        process.stdout.write('\n');
        atStartOfLine = true;
      }
    }
  };
}

/**
 * Handles the purely CLI-based blazer execution.
 */
export async function runCLI(commit: string, flags: { build?: string[], test?: string[], coverage?: number }) {
  console.log(chalk.cyan.bold(`\nEvaluating targets for commit: `) + chalk.white(commit));
  
  let targets = await getAffectedTargetsForCommit(commit, (data) => {
    process.stdout.write(chalk.dim(data));
  });

  if (flags.coverage && flags.coverage > 0) {
    console.log(chalk.yellow(`\nExpanding targets with radius coverage ${flags.coverage}%...`));
    targets = await expandTargets(targets, flags.coverage, (data) => {
      process.stdout.write(chalk.dim(data));
    });
  }

  const buildTargets = (flags.build && flags.build.length > 0) ? flags.build : (flags.test && flags.test.length > 0 ? [] : targets.buildTargets);
  const testTargets = (flags.test && flags.test.length > 0) ? flags.test : (flags.build && flags.build.length > 0 ? [] : targets.testTargets);

  if (buildTargets.length === 0 && testTargets.length === 0) {
    console.log(chalk.yellow('\nNo affected targets found.'));
    return;
  }

  console.log(chalk.cyan.bold(`\nExecuting ${buildTargets.length} builds and ${testTargets.length} tests in parallel...\n`));

  let buildSponge = '';
  let testSponge = '';

  const buildWriter = createPrefixedWriter('[BUILD] ', chalk.cyan);
  const buildErrWriter = createPrefixedWriter('[BUILD] ', chalk.cyan, chalk.dim);
  const testWriter = createPrefixedWriter('[TEST]  ', chalk.magenta);
  const testErrWriter = createPrefixedWriter('[TEST]  ', chalk.magenta, chalk.dim);

  const { buildStatusMap, testStatusMap, buildCode, testCode } = await runExecution(buildTargets, testTargets, {
    onBuildStdout: buildWriter,
    onBuildStderr: buildErrWriter,
    onTestStdout: testWriter,
    onTestStderr: testErrWriter,
    onBuildSponge: (link) => { buildSponge = link; },
    onTestSponge: (link) => { testSponge = link; },
  });

  // Final Summary
  console.log(chalk.white.bold('\n' + '─'.repeat(60)));
  console.log(chalk.white.bold('   EXECUTION SUMMARY'));
  console.log(chalk.white.bold('─'.repeat(60)));

  const allTargets = Array.from(new Set([...buildTargets, ...testTargets])).sort();
  let passed = 0, failed = 0, unknown = 0;

  for (const target of allTargets) {
    const status = getTargetStatus(target, buildTargets, testTargets, buildStatusMap, testStatusMap, true);
    
    let statusText = status;
    let color = chalk.gray;

    if (status === 'SUCCESSFUL') {
      passed++;
      statusText = 'PASS';
      color = chalk.green;
    } else if (status === 'FAILED' || status === 'BROKEN') {
      failed++;
      color = chalk.red;
    } else {
      unknown++;
    }

    console.log(`   ${color(`[${statusText.padEnd(7)}]`)} ${target}`);
  }

  console.log(chalk.white.bold('─'.repeat(60)));
  console.log(
    '   ' +
    chalk.green.bold(`${passed} passed`) + ', ' + 
    chalk.red.bold(`${failed} failed`) + 
    (unknown > 0 ? `, ${chalk.yellow.bold(`${unknown} unknown (SAFE TO IGNORE)`)}` : '')
  );
  
  if (buildSponge || testSponge) {
    console.log(chalk.white.bold('─'.repeat(60)));
    if (buildSponge) console.log(chalk.cyan.bold('   BUILD Sponge: ') + chalk.cyan.underline(buildSponge));
    if (testSponge)  console.log(chalk.magenta.bold('   TEST Sponge:  ') + chalk.magenta.underline(testSponge));
  }
  
  console.log(chalk.white.bold('─'.repeat(60)) + '\n');

  if (failed > 0 || (buildCode !== 0 && buildCode !== null) || (testCode !== 0 && testCode !== null)) {
    process.exit(1);
  }
}
