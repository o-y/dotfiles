import { getChangedFiles } from './jj';
import { getAffectedTargets, expandAffectedTargets, type AffectedTargets } from './targets';

/**
 * Resolves affected targets for a given commit.
 * 
 * @param commit The commit ID or reference (e.g. 'p4base', '@-')
 * @param onProgress Callback for evaluation progress
 */
export async function getAffectedTargetsForCommit(
  commit: string,
  onProgress?: (data: string) => void
): Promise<AffectedTargets> {
  const files = await getChangedFiles(commit);
  return getAffectedTargets(files, onProgress);
}

/**
 * Expands a set of affected targets based on proximity/rdeps.
 * 
 * @param current The current affected targets
 * @param coverage The expansion radius coverage percentage (0-100)
 * @param onProgress Callback for expansion progress
 */
export async function expandTargets(
  current: AffectedTargets,
  coverage: number,
  onProgress?: (data: string) => void
): Promise<AffectedTargets> {
  const allLabels = [...current.buildTargets.map(t => t.label), ...current.testTargets.map(t => t.label)];
  const expanded = await expandAffectedTargets(allLabels, coverage, onProgress);
  
  if (expanded.length === 0) return current;

  const newBuilds = expanded.filter(t => !t.kind.includes('test'));
  const newTests = expanded.filter(t => t.kind.includes('test'));

  const merge = (existing: TargetInfo[], additions: TargetInfo[]) => {
    const map = new Map<string, string>();
    [...existing, ...additions].forEach(t => map.set(t.label, t.kind));
    return Array.from(map.entries())
      .map(([label, kind]) => ({ label, kind }))
      .sort((a, b) => a.label.localeCompare(b.label));
  };

  return {
    buildTargets: merge(current.buildTargets, newBuilds),
    testTargets: merge(current.testTargets, newTests)
  };
}
