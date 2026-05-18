import { dirname, join, isAbsolute } from 'node:path';
import { $ } from 'bun';
import { blazeQueryAsync } from './blaze';

export interface TargetInfo {
  label: string;
  kind: string;
}

export interface AffectedTargets {
  buildTargets: TargetInfo[];
  testTargets: TargetInfo[];
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

  const query = async (args: string[]): Promise<TargetInfo[]> => {
    const out = await $`/google/bin/releases/depserver-contrib-tools/affected_targets/affected_targets ${args} ${absoluteFiles}`.cwd(workspace).quiet().nothrow();
    const stdout = out.text();
    const stderr = out.stderr.toString('utf-8');
    
    if (onOutput && stderr) onOutput(stderr);
    
    if (out.exitCode === 0) {
      return stdout.trim().split('\n')
        .filter(l => l.startsWith('//'))
        .map(label => ({ label, kind: 'unknown_rule' }));
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
  
  const buildTargets: TargetInfo[] = [];
  const testTargets: TargetInfo[] = [];
  
  for (const line of output.split(/[\r\n]+/).map(l => l.trim()).filter(Boolean)) {
    const match = line.match(/^(\S+(?: \S+)*?)\s+rule\s+(.*)$/);
    if (match) {
      const kind = match[1] || 'unknown_rule';
      const label = match[2] || '';
      if (kind.includes('test')) testTargets.push({ label, kind });
      else buildTargets.push({ label, kind });
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

  const merge = (a: TargetInfo[], b: TargetInfo[]) => {
    const map = new Map<string, string>();
    [...a, ...b].forEach(t => {
      // Prefer non-unknown kinds
      if (!map.has(t.label) || map.get(t.label) === 'unknown_rule') {
        map.set(t.label, t.kind);
      }
    });
    return Array.from(map.entries())
      .map(([label, kind]) => ({ label, kind }))
      .sort((x, y) => x.label.localeCompare(y.label));
  };

  const builds = merge(depServerRes.buildTargets, blazeQueryRes.buildTargets);
  const tests = merge(depServerRes.testTargets, blazeQueryRes.testTargets);

  onOutput?.(`[blazer] Synthesized unique ${builds.length} build targets and ${tests.length} test targets.\n`);

  return {
    buildTargets: builds,
    testTargets: tests
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
): Promise<TargetInfo[]> {
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
  const rootSample = targets.length > 100 ? targets.slice(0, 100) : targets;
  const roots = `set(${rootSample.join(' ')})`;
  
  const rdepsQuery = `rdeps(${scopeExpr}, ${roots}, 1)`;
  const siblingQuery = pkgs.size > 0 ? Array.from(pkgs).map(p => `${p}:*`).join(' + ') : 'set()';
  
  const queryExpr = `kind(".* rule", (${rdepsQuery}) + (${siblingQuery}))`;

  const output = await blazeQueryAsync(queryExpr, ['--output=label_kind', '--keep_going', '--order_output=no'], onOutput);
  
  const discovered = new Map<string, string>();
  for (const line of output.split(/[\r\n]+/).map(l => l.trim()).filter(Boolean)) {
    const match = line.match(/^(\S+(?: \S+)*?)\s+rule\s+(.*)$/);
    if (match) {
      const kind = match[1] || 'unknown_rule';
      const label = match[2] || '';
      if (label && !targetSet.has(label)) {
        discovered.set(label, kind);
      }
    }
  }

  const discoveredList = Array.from(discovered.entries()).map(([label, kind]) => ({ label, kind }));
  onOutput?.(`[Expansion] Found ${discoveredList.length} potential new targets.\n`);

  if (coverage >= 100) return discoveredList;

  // 3. Sampling logic with stable pseudo-random selection
  const targetCount = Math.ceil(discoveredList.length * (coverage / 100));
  
  const sorted = discoveredList.sort((a, b) => {
    const hashA = a.label.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    const hashB = b.label.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return hashA - hashB || a.label.localeCompare(b.label);
  });

  return sorted.slice(0, targetCount);
}
