import { useState } from 'react';
import { getChangedFiles } from '../lib/jj';
import { getAffectedTargets, expandAffectedTargets, type AffectedTargets } from '../lib/targets';

export type ViewState = 'SELECT_COMMIT' | 'LOADING_TARGETS' | 'SELECT_BUILD_TARGETS' | 'SELECT_TEST_TARGETS' | 'EXECUTE' | 'ERROR';

/**
 * Manages the top-level application state for the Blazer workflow.
 */
export function useBlazerWorkflow() {
  const [view, setView] = useState<ViewState>('SELECT_COMMIT');
  const [errorObj, setError] = useState<string>('');
  const [baseCommit, setBaseCommit] = useState<string>('');
  const [affectedTargets, setAffectedTargets] = useState<AffectedTargets | null>(null);
  const [targetStream, setTargetStream] = useState<string>('');
  const [selectedBuilds, setSelectedBuilds] = useState<string[]>([]);
  const [selectedTests, setSelectedTests] = useState<string[]>([]);

  const actions = {
    async selectCommit(commit: string) {
      setBaseCommit(commit);
      setView('LOADING_TARGETS');
      setTargetStream('');
      try {
        const files = await getChangedFiles(commit);
        const targets = await getAffectedTargets(files, data => setTargetStream(log => (log + data).slice(-5000)));
        setAffectedTargets(targets);
        setView('SELECT_BUILD_TARGETS');
      } catch (err: any) {
        setError(err instanceof Error ? err.message : String(err));
        setView('ERROR');
      }
    },
    selectBuildTargets(builds: string[]) {
      setSelectedBuilds(builds);
      setView('SELECT_TEST_TARGETS');
    },
    selectTestTargets(tests: string[]) {
      setSelectedTests(tests);
      setView('EXECUTE');
    },
    async expandTargets(coverage: number, onOutput?: (data: string) => void) {
      if (!affectedTargets) return;
      
      try {
        const allDetected = [...affectedTargets.buildTargets, ...affectedTargets.testTargets];
        const expanded = await expandAffectedTargets(allDetected, coverage, onOutput);
        
        if (expanded.length === 0) return;

        const newBuilds = expanded.filter(t => !t.includes('test'));
        const newTests = expanded.filter(t => t.includes('test'));

        setAffectedTargets({
          buildTargets: Array.from(new Set([...affectedTargets.buildTargets, ...newBuilds])).sort(),
          testTargets: Array.from(new Set([...affectedTargets.testTargets, ...newTests])).sort()
        });
      } catch (err: any) {
        onOutput?.(`\n[Expansion Error] ${err.message || String(err)}\n`);
        // We don't want to flip the whole app to ERROR view for a non-critical expansion failure
      }
    }
  };

  return { view, errorObj, baseCommit, affectedTargets, targetStream, selectedBuilds, selectedTests, actions };
}
