import { useState } from 'react';
import { type AffectedTargets, getAffectedTargetsForCommit, expandTargets } from '../lib/workflow';

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
        const targets = await getAffectedTargetsForCommit(commit, data => setTargetStream(log => (log + data).slice(-5000)));
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
        const expanded = await expandTargets(affectedTargets, coverage, onOutput);
        setAffectedTargets(expanded);
      } catch (err: any) {
        onOutput?.(`\n[Expansion Error] ${err.message || String(err)}\n`);
      }
    }
  };

  return { view, errorObj, baseCommit, affectedTargets, targetStream, selectedBuilds, selectedTests, actions };
}
