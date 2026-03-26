import React, { useState, useMemo, useEffect } from 'react';
import { Box, Text, useApp } from 'ink';
import { useControls, ControlsDisplay } from '../hooks/useControls';
import { useNotification } from '../hooks/useNotification';
import type { TargetStatus } from '../lib/reconciliation';
import { getTargetStatus, getSeverity } from '../lib/reconciliation';
import { buildTargetTree, compressTree, flattenTree, type TreeNode } from '../lib/tree';
import { copyToClipboard } from '../lib/os';
import open from 'open';
import type { ExecutionResult } from './ExecutionRenderer';
import { Timeline } from './Timeline';

interface SummaryData {
  status: TargetStatus;
  maxSeverity: number;
  totalTargets: number;
  passedTargets: number;
  pendingTargets: number;
  diff?: 'FIXED' | 'REGRESSION';
}

export type SummaryNode = TreeNode<SummaryData>;

export interface ExecutionSummaryProps {
  buildTargets: string[];
  testTargets: string[];
  buildExitCode: number | null;
  testExitCode: number | null;
  buildSpongeId?: string | null;
  testSpongeId?: string | null;
  buildMap: Map<string, TargetStatus>;
  testMap: Map<string, TargetStatus>;
  done: boolean;
  history: ExecutionResult[];
  onReexecute: () => void;
}

function getRunData(props: ExecutionSummaryProps, effectiveViewedIdx: number) {
  const displayCount = props.history.length + (props.done ? 0 : 1);
  const isViewingLatest = effectiveViewedIdx === displayCount - 1;
  
  const currentRun = isViewingLatest 
    ? (props.done ? (props.history.length > 0 ? props.history[props.history.length - 1] : null) : null)
    : (effectiveViewedIdx < props.history.length ? props.history[effectiveViewedIdx] : null);

  const prevRun = isViewingLatest
    ? (props.done 
        ? (props.history.length > 1 ? props.history[props.history.length - 2] : null)
        : (props.history.length > 0 ? props.history[props.history.length - 1] : null))
    : (effectiveViewedIdx > 0 ? props.history[effectiveViewedIdx - 1] : null);

  return { currentRun, prevRun, isViewingLatest, displayCount };
}

/**
 * Constructs the execution summary tree and computes health metrics.
 */
function useSummaryTree(props: ExecutionSummaryProps, effectiveViewedIdx: number) {
  const { currentRun, prevRun } = getRunData(props, effectiveViewedIdx);
  
  const bMap = currentRun ? currentRun.buildMap : props.buildMap;
  const tMap = currentRun ? currentRun.testMap : props.testMap;
  const isDone = currentRun ? true : props.done;

  const allTargets = useMemo(() => Array.from(new Set([...props.buildTargets, ...props.testTargets])), [props.buildTargets, props.testTargets]);

  const root = useMemo(() => {
    const r = buildTargetTree<SummaryData>(
      allTargets,
      (target) => {
        const status = getTargetStatus(target, props.buildTargets, props.testTargets, bMap, tMap, isDone);
        const prevStatus = prevRun ? getTargetStatus(target, props.buildTargets, props.testTargets, prevRun.buildMap, prevRun.testMap, true) : null;

        const severity = getSeverity(status);
        const isPassing = status === 'SUCCESSFUL';
        const isPending = status === 'PENDING' || (!isDone && status === 'UNKNOWN');
        
        let diff: 'FIXED' | 'REGRESSION' | undefined;
        if (prevStatus && prevStatus !== 'SUCCESSFUL' && status === 'SUCCESSFUL') diff = 'FIXED';
        if (prevStatus === 'SUCCESSFUL' && status !== 'SUCCESSFUL' && status !== 'PENDING' && status !== 'UNKNOWN') diff = 'REGRESSION';

        return { status, maxSeverity: severity, totalTargets: 1, passedTargets: isPassing ? 1 : 0, pendingTargets: isPending ? 1 : 0, diff };
      },
      () => ({ status: 'SUCCESSFUL', maxSeverity: 0, totalTargets: 0, passedTargets: 0, pendingTargets: 0 })
    );

    compressTree(r, true);

    const computeMetrics = (node: SummaryNode): { maxSev: number, total: number, passed: number, pending: number } => {
      if (node.isTarget) return { maxSev: node.data.maxSeverity, total: node.data.totalTargets, passed: node.data.passedTargets, pending: node.data.pendingTargets };
      
      let maxSev = 0, total = 0, passed = 0, pending = 0;
      for (const child of node.children.values()) {
        const stats = computeMetrics(child);
        maxSev = Math.max(maxSev, stats.maxSev);
        if (child.isTarget && child.data.status === 'UNKNOWN') continue;
        
        total += stats.total;
        passed += stats.passed;
        pending += stats.pending;
      }
      
      if (!node.isTarget && total === 0) maxSev = 2;
      
      node.data.maxSeverity = maxSev;
      node.data.totalTargets = total;
      node.data.passedTargets = passed;
      node.data.pendingTargets = pending;
      return { maxSev, total, passed, pending };
    };
    computeMetrics(r);
    
    const applyHeuristics = (node: SummaryNode, depth: number): number => {
      if (node.isTarget) return node.data.maxSeverity >= 3 ? 1 : 0;
      let failCount = 0;
      for (const child of node.children.values()) failCount += applyHeuristics(child, depth + 1);
      
      if (depth > 0) node.isExpanded = node.data.maxSeverity < 3 ? false : failCount <= 15;
      else node.isExpanded = true;
      
      return failCount;
    };
    applyHeuristics(r, 0);

    return r;
  }, [allTargets, props.buildTargets, props.testTargets, bMap, tMap, isDone, prevRun]);

  const [version, setVersion] = useState(0);
  const toggleNodeExpansion = (node: SummaryNode) => {
    node.isExpanded = !node.isExpanded;
    setVersion(v => v + 1);
  };

  const flatNodes = useMemo(() => {
    const nodes: { node: SummaryNode, depth: number }[] = [];
    flattenTree(root, 0, nodes, (a, b) => {
      if (a.data.maxSeverity !== b.data.maxSeverity) return b.data.maxSeverity - a.data.maxSeverity;
      if (a.isTarget !== b.isTarget) return a.isTarget ? 1 : -1;
      
      const aIsUnknown = a.isTarget && a.data.status === 'UNKNOWN';
      const bIsUnknown = b.isTarget && b.data.status === 'UNKNOWN';
      if (aIsUnknown !== bIsUnknown) return aIsUnknown ? 1 : -1;

      return a.name.localeCompare(b.name);
    });
    return nodes;
  }, [root, version]);
  
  return { flatNodes, allTargets, toggleNodeExpansion };
}

function SummaryTreeItem({ item, cursor, index, startIdx, isFocused }: { item: { node: SummaryNode, depth: number }, cursor: number, index: number, startIdx: number, isFocused: boolean }) {
  const actualIndex = startIdx + index;
  const isLineFocused = isFocused && actualIndex === cursor;
  const isTarget = item.node.isTarget;
  const bg = isLineFocused ? '#1e2e3e' : undefined;
  const icon = !isTarget ? (item.node.isExpanded ? '-' : '+') : '';
  const isUnknown = isTarget && item.node.data.status === 'UNKNOWN';
  const diff = item.node.data.diff;

  return (
    <Box flexDirection="row" width="100%" backgroundColor={bg}>
      <Box width={3} flexShrink={0}>
        <Text color="cyanBright" bold={isLineFocused}>{isLineFocused ? ' ❯ ' : '   '}</Text>
      </Box>
      <Box width={item.depth * 2} flexShrink={0} />
      
      <Box flexGrow={1} flexDirection="row" justifyContent="space-between" minWidth={0}>
        <Box minWidth={0} paddingRight={1} flexGrow={1} flexDirection="row">
          <Text color={isLineFocused ? (!isTarget ? 'cyanBright' :'whiteBright') : (!isTarget ? 'cyan' : (isUnknown ? 'grey' : 'gray'))} bold={!isTarget || isLineFocused} wrap="truncate-end">
            {icon ? `${icon} ` : ''}{item.node.name}
          </Text>
          {diff === 'FIXED' && <Text color="greenBright"> +</Text>}
          {diff === 'REGRESSION' && <Text color="redBright"> -</Text>}
        </Box>
        <Box width={10} justifyContent="flex-end" flexShrink={0}>
          {(() => {
             if (!isTarget) {
               const { totalTargets, passedTargets, pendingTargets } = item.node.data;
               if (totalTargets === 0) return <Text dimColor>-</Text>;
               if (pendingTargets === totalTargets) return <Text dimColor>-</Text>;
               const pct = totalTargets > 0 ? Math.round((passedTargets / totalTargets) * 100) : 0;
               if (pendingTargets > 0) return <Text dimColor>{pct}%</Text>;
               const color = pct === 100 ? 'green' : (pct < 50 ? 'red' : 'yellow');
               return <Text color={color}>{pct}%</Text>;
             }
             const status = item.node.data.status;
             if (status === 'SUCCESSFUL') return <Text color="green">PASS</Text>;
             if (status === 'FAILED') return <Text color="red">FAIL</Text>;
             if (status === 'BROKEN') return <Text color="red">BROKEN</Text>;
             if (status === 'SKIPPED') return <Text dimColor>SKIP</Text>;
             if (status === 'PENDING') return <Text dimColor>PEND</Text>;
             if (status === 'UNKNOWN') return <Text color="grey" dimColor>UNKNOWN</Text>;
             return <Text>{status}</Text>;
          })()}
        </Box>
      </Box>
    </Box>
  );
}

function SpongeLogLink({ spongeId, fullPath, pass, phase, marginTop = 0 }: { spongeId: string | null | undefined, fullPath: string, pass: boolean, phase: string, marginTop?: number }) {
  return (
    <Box flexDirection="row" justifyContent="space-between" paddingX={1} borderStyle="single" borderColor={pass ? 'dim' : 'red'} marginTop={marginTop}>
      <Text color="gray">{phase}</Text>
      <Box flexDirection="row">
        {spongeId && (
          <Box marginRight={2}>
             <Text color="blueBright" underline>
               {`\u001B]8;;http://sponge2/${spongeId}/targets/${encodeURIComponent(fullPath)}/log\u0007Sponge2 Log\u001B]8;;\u0007`}
             </Text>
          </Box>
        )}
        <Text color={pass ? 'greenBright' : 'redBright'} bold>{pass ? 'SUCCESS' : 'FAILURE'}</Text>
      </Box>
    </Box>
  );
}


export function ExecutionSummary(props: ExecutionSummaryProps) {
  const [viewedIdx, setViewedIdx] = useState(-1);
  const [focus, setFocus] = useState<'TREE' | 'TIMELINE'>('TREE');
  
  // Update viewedIdx to latest when history grows, unless manually viewing history
  const historyLen = props.history.length;
  useEffect(() => {
    if (viewedIdx === -1 && historyLen > 0) {
       // stay at -1 (active)
    } else if (viewedIdx >= 0 && viewedIdx < historyLen - 1) {
       // stay where we are
    } else if (historyLen > 0) {
       setViewedIdx(historyLen - 1);
    }
  }, [historyLen]);

  const displayCount = props.history.length + (props.done ? 0 : 1);
  const effectiveViewedIdx = viewedIdx === -1 ? displayCount - 1 : viewedIdx;
  const { currentRun, prevRun, isViewingLatest } = getRunData(props, effectiveViewedIdx);
  const { flatNodes, allTargets, toggleNodeExpansion } = useSummaryTree(props, effectiveViewedIdx);
  const [cursor, setCursor] = useState(0);
  const { exit } = useApp();

  const selectedNode = flatNodes[cursor]?.node;

  const buildSpongeId = currentRun ? currentRun.buildSpongeId : props.buildSpongeId;
  const testSpongeId = currentRun ? currentRun.testSpongeId : props.testSpongeId;
  const buildMap = currentRun ? currentRun.buildMap : props.buildMap;
  const testMap = currentRun ? currentRun.testMap : props.testMap;

  const isSelectedB = selectedNode ? props.buildTargets.includes(selectedNode.fullPath) : false;
  const isSelectedT = selectedNode ? props.testTargets.includes(selectedNode.fullPath) : false;

  const spongeUrl = useMemo(() => {
    if (!selectedNode || !selectedNode.isTarget) return null;
    const sid = (isSelectedB && buildSpongeId) ? buildSpongeId : (isSelectedT && testSpongeId ? testSpongeId : (buildSpongeId || testSpongeId));
    if (sid) return `http://sponge2/${sid}/targets/${encodeURIComponent(selectedNode.fullPath)}/log`;
    return null;
  }, [selectedNode, isSelectedB, isSelectedT, buildSpongeId, testSpongeId]);

  const { showNotification } = useNotification();
  const controls = useControls([
    {
      id: 'up', displayKey: '↑', label: 'Up', isActive: focus === 'TREE', isVisuallyDisplayed: false,
      matcher: (_, key) => !!key?.upArrow,
      action: () => setCursor(c => Math.max(0, c - 1))
    },
    {
      id: 'down', displayKey: '↓', label: 'Down', isActive: focus === 'TREE', isVisuallyDisplayed: false,
      matcher: (_, key) => !!key?.downArrow,
      action: () => setCursor(c => Math.min(flatNodes.length - 1, c + 1))
    },
    {
       id: 'prev-run', displayKey: '←', label: 'Prev Run', isActive: focus === 'TIMELINE', isVisuallyDisplayed: false,
       matcher: (_, key) => !!key?.leftArrow,
       action: () => setViewedIdx(v => Math.max(0, (v === -1 ? displayCount - 1 : v) - 1))
    },
    {
       id: 'next-run', displayKey: '→', label: 'Next Run', isActive: focus === 'TIMELINE', isVisuallyDisplayed: false,
       matcher: (_, key) => !!key?.rightArrow,
       action: () => setViewedIdx(v => v === -1 ? -1 : Math.min(displayCount - 1, v + 1))
    },
    {
      id: 'expand', displayKey: '←/→', label: 'Expand/Collapse', isActive: focus === 'TREE',
      matcher: (_, key) => !!(key?.leftArrow || key?.rightArrow),
      action: () => { if (selectedNode) toggleNodeExpansion(selectedNode); }
    },
    {
       id: 'toggle-focus', displayKey: 'T', label: 'Toggle Focus', isActive: displayCount > 1,
       matcher: (input) => input === 't',
       action: () => setFocus(f => f === 'TREE' ? 'TIMELINE' : 'TREE')
    },
    {
      id: 'reexecute', displayKey: 'R', label: 'Re-execute', isActive: props.done,
      matcher: (input) => input === 'r',
      action: () => { props.onReexecute(); setViewedIdx(-1); setFocus('TREE'); }
    },
    {
      id: 'copy-path', displayKey: 'C', label: 'Copy Path', isActive: !!selectedNode,
      matcher: (input) => input === 'c',
      action: () => {
        copyToClipboard(selectedNode!.fullPath);
        showNotification('Target path copied to clipboard');
      }
    },
    {
      id: 'copy-sponge', displayKey: 'S', label: 'Copy Sponge', isActive: !!(selectedNode && selectedNode.isTarget && spongeUrl),
      matcher: (input) => input === 's',
      action: () => {
        copyToClipboard(spongeUrl!);
        showNotification('Sponge URL copied to clipboard');
      }
    },
    {
      id: 'open-sponge', displayKey: 'O', label: 'Open Sponge', isActive: !!(selectedNode && selectedNode.isTarget && spongeUrl),
      matcher: (input) => input === 'o',
      action: () => open(spongeUrl!).catch(() => {})
    },
    {
      id: 'exit', displayKey: 'Ctrl+C', label: 'Exit', isActive: true,
      matcher: (input, key) => !!(key?.ctrl && input === 'c'),
      action: exit
    }
  ]);

  const maxLines = 16;
  const startIdx = Math.max(0, Math.min(cursor - Math.floor(maxLines / 2), flatNodes.length - maxLines));
  const visibleItems = flatNodes.slice(startIdx, startIdx + maxLines);

  const stats = useMemo(() => {
    let passing = 0, failing = 0, pending = 0;
    let prevPassing = 0, prevFailing = 0;

    const bMap = currentRun ? currentRun.buildMap : props.buildMap;
    const tMap = currentRun ? currentRun.testMap : props.testMap;
    const isDone = currentRun ? true : props.done;

    allTargets.forEach(target => {
      const status = getTargetStatus(target, props.buildTargets, props.testTargets, bMap, tMap, isDone);
      if (status === 'SUCCESSFUL') passing++;
      else if (status === 'FAILED' || status === 'BROKEN') failing++;
      else if (status === 'PENDING' || (!isDone && status === 'UNKNOWN')) pending++;

      if (prevRun) {
         const prevStatus = getTargetStatus(target, props.buildTargets, props.testTargets, prevRun.buildMap, prevRun.testMap, true);
         if (prevStatus === 'SUCCESSFUL') prevPassing++;
         else if (prevStatus === 'FAILED' || prevStatus === 'BROKEN') prevFailing++;
      }
    });

    return { passing, failing, pending, prevPassing, prevFailing, hasPrev: !!prevRun };
  }, [allTargets, props.buildTargets, props.testTargets, props.buildMap, props.testMap, props.done, currentRun, prevRun]);

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={focus === 'TREE' ? 'dim' : 'cyan'} paddingX={1} paddingY={0}>
      <Box flexDirection="row" justifyContent="space-between" marginBottom={1}>
         <Box flexGrow={1} flexDirection="row" alignItems="center">
           <Text bold backgroundColor="whiteBright" color="black"> SUMMARY </Text>
           {displayCount > 1 && (
             <Box marginLeft={2}>
               <Timeline history={props.history} viewedIdx={effectiveViewedIdx} isFocused={focus === 'TIMELINE'} done={props.done} displayCount={displayCount} />
             </Box>
           )}
         </Box>
         <Box flexGrow={1} flexDirection="row" justifyContent="flex-end">
            {!isViewingLatest && (
              <Box marginRight={2}>
                <Text color="yellowBright" bold> [Historical Run {effectiveViewedIdx + 1} / {displayCount}] </Text>
              </Box>
            )}
            <Box flexDirection="row">
               <Text color="greenBright" bold>{stats.passing}</Text><Text color="gray"> passed</Text>
               {stats.hasPrev && stats.passing > stats.prevPassing && <Text color="green"> (+{stats.passing - stats.prevPassing})</Text>}
               {stats.passing < stats.prevPassing && <Text color="red"> ({stats.passing - stats.prevPassing})</Text>}
               <Text dimColor>  •  </Text>
               <Text color={stats.failing > 0 ? "redBright" : "gray"} bold={stats.failing > 0}>{stats.failing}</Text><Text color="gray"> failed</Text>
               {stats.hasPrev && stats.failing > stats.prevFailing && <Text color="red"> (+{stats.failing - stats.prevFailing})</Text>}
               {stats.failing < stats.prevFailing && <Text color="green"> ({stats.failing - stats.prevFailing})</Text>}
               {stats.pending > 0 && <><Text dimColor>  •  </Text><Text color="cyanBright" bold>{stats.pending}</Text><Text color="gray"> pending</Text></>}
            </Box>
         </Box>
      </Box>

      <Box flexDirection="row" width="100%">
        <Box flexDirection="column" width="60%" paddingRight={1}>
           {visibleItems.map((item, index) => (
             <SummaryTreeItem key={index} item={item} cursor={cursor} index={index} startIdx={startIdx} isFocused={focus === 'TREE'} />
           ))}
        </Box>

        <Box flexDirection="column" width="40%" paddingLeft={3}>
           {selectedNode ? (
             <Box flexDirection="column">
               <Text bold color="whiteBright">SELECTION DETAILS</Text>
               <Text dimColor>──────────────────────</Text>
               <Box flexDirection="column" marginBottom={1} marginTop={1}>
                  <Text bold color="cyanBright" wrap="truncate">{selectedNode.name}</Text>
                  {selectedNode.isTarget && <Text dimColor wrap="truncate">{selectedNode.fullPath}</Text>}
               </Box>

               {selectedNode.isTarget ? (
                 <Box flexDirection="column">
                   {isSelectedB && <SpongeLogLink spongeId={buildSpongeId} fullPath={selectedNode.fullPath} pass={buildMap.get(selectedNode.fullPath) === 'SUCCESSFUL'} phase="Build Phase:" />}
                   {isSelectedT && <SpongeLogLink spongeId={testSpongeId} fullPath={selectedNode.fullPath} pass={testMap.get(selectedNode.fullPath) === 'SUCCESSFUL'} phase="Test Phase:" marginTop={isSelectedB ? 1 : 0} />}
                   {!isSelectedB && !isSelectedT && <Box paddingX={1} borderStyle="single" borderColor="dim"><Text dimColor>No actions executed.</Text></Box>}
                 </Box>
               ) : (
                 <Box flexDirection="column" paddingX={1} borderStyle="single" borderColor={selectedNode.data.maxSeverity >= 3 ? 'red' : 'dim'}>
                   <Box flexDirection="row" justifyContent="space-between" marginBottom={1}><Text color="gray">Total Targets:</Text><Text color="whiteBright">{selectedNode.data.totalTargets}</Text></Box>
                   <Box flexDirection="row" justifyContent="space-between"><Text color="gray">Passed Targets:</Text><Text color="greenBright">{selectedNode.data.passedTargets}</Text></Box>
                   {selectedNode.data.pendingTargets > 0 && <Box flexDirection="row" justifyContent="space-between"><Text color="gray">Pending Targets:</Text><Text color="cyanBright">{selectedNode.data.pendingTargets}</Text></Box>}
                   <Box flexDirection="row" justifyContent="space-between" marginBottom={1}><Text color="gray">Failed Targets:</Text><Text color={selectedNode.data.totalTargets - selectedNode.data.passedTargets - selectedNode.data.pendingTargets > 0 ? 'redBright' : 'gray'}>{selectedNode.data.totalTargets - selectedNode.data.passedTargets - selectedNode.data.pendingTargets}</Text></Box>
                   <Box flexDirection="row" justifyContent="space-between"><Text color="gray">Nested Health:</Text><Text color={selectedNode.data.maxSeverity >= 3 ? 'redBright' : 'greenBright'} bold>{selectedNode.data.maxSeverity >= 3 ? 'FAILING' : 'HEALTHY'}</Text></Box>
                 </Box>
               )}

               <Box marginTop={1}>
                 <ControlsDisplay controls={controls} />
               </Box>
             </Box>
           ) : (
             <Text dimColor>Select a specific node for details.</Text>
           )}
        </Box>
      </Box>
    </Box>
  );
}
