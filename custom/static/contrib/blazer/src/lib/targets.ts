import { dirname, join, isAbsolute } from 'node:path';
import { $ } from 'bun';
import { blazeQueryAsync } from './blaze';

export interface AffectedTargets {
  buildTargets: string[];
  testTargets: string[];
}

/**
 * Finds the nearest ancestor Bazel package for a given file.
 */
async function getPackageForFile(workspace: string, file: string): Promise<string | null> {
  let dir = dirname(file);
  while (dir !== '.' && dir !== '/' && dir !== '') {
    if (await Bun.file(join(workspace, dir, 'BUILD')).exists()) {
      return dir === '.' ? '//' : `//${dir}`;
    }
    dir = dirname(dir);
  }
  
  if (await Bun.file(join(workspace, 'BUILD')).exists()) return '//';
  return null;
}

/**
 * Queries depserver for affected targets based on modified files.
 */
async function runDepServer(files: string[], onOutput?: (data: string) => void): Promise<AffectedTargets> {
  if (files.length === 0) return { buildTargets: [], testTargets: [] };

  const workspace = process.cwd();
  const absoluteFiles = files.map(f => isAbsolute(f) ? f : join(workspace, f));
  
  onOutput?.(`[DepServer] Evaluating ${files.length} changed files...\n`);

  const query = async (args: string[]): Promise<string[]> => {
    const out = await $`/google/bin/releases/depserver-contrib-tools/affected_targets/affected_targets ${args} ${absoluteFiles}`.cwd(workspace).quiet().nothrow();
    const stdout = out.text();
    const stderr = out.stderr.toString('utf-8');
    
    if (onOutput && stderr) onOutput(stderr);
    
    if (out.exitCode === 0) {
      return stdout.trim().split('\n').filter(l => l.startsWith('//'));
    }
    throw new Error(`exited with code ${out.exitCode}.\n${stderr}`);
  };

  const [testTargets, buildTargets] = await Promise.all([
    query(['--test_only=true']),
    query(['--test=false', '--bin=true', '--lib=true'])
  ]);

  return { buildTargets, testTargets };
}

/**
 * Resolves local graph extensions using blaze query to find reverse dependencies
 * for modified files enclosed within local packages.
 */
async function runBlazeQuery(files: string[], onOutput?: (data: string) => void): Promise<AffectedTargets> {
  if (files.length === 0) return { buildTargets: [], testTargets: [] };

  const workspace = process.cwd();
  const filePkgs = (await Promise.all(
    files.map(async file => {
      const pkg = await getPackageForFile(workspace, file);
      if (!pkg) return null;
      const pkgPath = pkg === '//' ? '' : pkg.substring(2);
      const relPath = pkgPath === '' ? file : file.substring(pkgPath.length + 1);
      return { pkg, target: `${pkg}:${relPath}` };
    })
  )).filter(Boolean) as { pkg: string; target: string }[];

  if (filePkgs.length === 0) {
    onOutput?.(`[Blaze Query] No BUILD packages enclosing the modified files.\n`);
    return { buildTargets: [], testTargets: [] };
  }

  const queryParts = filePkgs.map(fp => `rdeps(${fp.pkg}:all, ${fp.target})`);
  const queryExpr = `kind(".* rule", ${queryParts.join(' + ')})`;

  onOutput?.(`[Blaze Query] Evaluating ${filePkgs.length} local graph extensions...\n`);

  const output = await blazeQueryAsync(queryExpr, ['--output=label_kind', '--keep_going', '--order_output=no'], onOutput);
  
  const buildTargets: string[] = [];
  const testTargets: string[] = [];
  
  for (const line of output.split(/[\r\n]+/).map(l => l.trim()).filter(Boolean)) {
    const match = line.match(/^(\S+(?: \S+)*?)\s+rule\s+(.*)$/);
    if (match) {
      if ((match[1] || '').includes('test')) testTargets.push(match[2] || '');
      else buildTargets.push(match[2] || '');
    }
  }

  return { buildTargets, testTargets };
}

/**
 * Aggregates build/test targets from all available graph resolution systems.
 */
export async function getAffectedTargets(files: string[], onOutput?: (data: string) => void): Promise<AffectedTargets> {
  const [depServerRes, blazeQueryRes] = await Promise.all([
    runDepServer(files, onOutput).catch(e => {
       onOutput?.(`[blazer] DepServer failed: ${e.message}\n`);
       return { buildTargets: [], testTargets: [] };
    }),
    runBlazeQuery(files, onOutput).catch(e => {
       onOutput?.(`[blazer] Blaze Query failed: ${e.message}\n`);
       return { buildTargets: [], testTargets: [] };
    })
  ]);

  const builds = new Set([...depServerRes.buildTargets, ...blazeQueryRes.buildTargets]);
  const tests = new Set([...depServerRes.testTargets, ...blazeQueryRes.testTargets]);

  onOutput?.(`[blazer] Synthesized unique ${builds.size} build targets and ${tests.size} test targets.\n`);

  return {
    buildTargets: Array.from(builds).sort(),
    testTargets: Array.from(tests).sort()
  };
}

/**
 * Computes a localized search scope for a set of packages.
 * For each package, it includes the package tree and its parent tree.
 */
function getLocalScopes(pkgs: Set<string>): string[] {
  const scopes = new Set<string>();
  for (const pkg of pkgs) {
    if (!pkg.startsWith('//')) continue;
    scopes.add(`${pkg}/...`);
    
    // Go up one level if possible for better proximity (siblings of the package)
    const parts = pkg.split('/');
    if (parts.length > 3) {
      const parent = parts.slice(0, -1).join('/');
      scopes.add(`${parent}/...`);
    }
  }
  // Sort by specificity and take only a few to avoid complex query expressions
  const sorted = Array.from(scopes).sort((a, b) => a.length - b.length);
  return sorted.slice(0, 10);
}

/**
 * Expands the set of affected targets by finding rdeps and sampling them.
 */
export async function expandAffectedTargets(
  targets: string[], 
  coverage: number, 
  onOutput?: (data: string) => void
): Promise<string[]> {
  if (targets.length === 0 || coverage === 0) return [];

  const targetSet = new Set(targets);
  const pkgs = new Set<string>();
  for (const t of targets) {
    const pkg = t.split(':')[0];
    if (pkg) pkgs.add(pkg);
  }

  // 1. Determine local scopes for faster rdeps search
  const localScopes = getLocalScopes(pkgs);
  const scopeExpr = localScopes.length > 0 ? localScopes.join(' + ') : '//...';

  onOutput?.(`[Expansion] Searching for proximity targets in ${localScopes.length} local trees...\n`);

  // 2. Build query for immediate rdeps and siblings
  // Using set() and limiting roots to avoid overly long command lines
  const rootSample = targets.length > 100 ? targets.slice(0, 100) : targets;
  const roots = `set(${rootSample.join(' ')})`;
  
  // Combine siblings and direct rdeps within identified local scopes
  const rdepsQuery = `rdeps(${scopeExpr}, ${roots}, 1)`;
  const siblingQuery = pkgs.size > 0 ? Array.from(pkgs).map(p => `${p}:*`).join(' + ') : 'set()';
  
  const queryExpr = `kind(".* rule", (${rdepsQuery}) + (${siblingQuery}))`;

  const output = await blazeQueryAsync(queryExpr, ['--output=label_kind', '--keep_going', '--order_output=no'], onOutput);
  
  const discovered = new Set<string>();
  for (const line of output.split(/[\r\n]+/).map(l => l.trim()).filter(Boolean)) {
    const match = line.match(/^(\S+(?: \S+)*?)\s+rule\s+(.*)$/);
    if (match) {
      const label = match[2] || '';
      if (label && !targetSet.has(label)) {
        discovered.add(label);
      }
    }
  }

  const discoveredList = Array.from(discovered);
  onOutput?.(`[Expansion] Found ${discoveredList.length} potential new targets.\n`);

  if (coverage >= 100) return discoveredList;

  // 3. Sampling logic with stable pseudo-random selection
  const targetCount = Math.ceil(discoveredList.length * (coverage / 100));
  
  // Simple deterministic shuffle based on string content to keep it stable-ish
  const sorted = discoveredList.sort((a, b) => {
    const hashA = a.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const hashB = b.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return hashA - hashB || a.localeCompare(b);
  });

  return sorted.slice(0, targetCount);
}
