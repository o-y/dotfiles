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
  const allDetected = [...current.buildTargets, ...current.testTargets];
  const expanded = await expandAffectedTargets(allDetected, coverage, onProgress);
  
  if (expanded.length === 0) return current;

  const newBuilds = expanded.filter(t => !t.includes('test'));
  const newTests = expanded.filter(t => t.includes('test'));

  return {
    buildTargets: Array.from(new Set([...current.buildTargets, ...newBuilds])).sort(),
    testTargets: Array.from(new Set([...current.testTargets, ...newTests])).sort()
  };
}
