import React, { useState, useMemo } from 'react';
import { Box, Text, useApp } from 'ink';
import { useControls, ControlsDisplay } from '../hooks/useControls';
import { useNotification } from '../hooks/useNotification';
import type { TargetStatus } from '../lib/reconciliation';
import { getTargetStatus, getSeverity } from '../lib/reconciliation';
import { buildTargetTree, compressTree, flattenTree, type TreeNode } from '../lib/tree';
import { copyToClipboard } from '../lib/os';
import open from 'open';

interface SummaryData {
  status: TargetStatus;
  maxSeverity: number;
  totalTargets: number;
  passedTargets: number;
  pendingTargets: number;
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
}

/**
 * Constructs the execution summary tree and computes health metrics.
 */
function useSummaryTree(props: ExecutionSummaryProps) {
  const { buildTargets, testTargets, buildMap, testMap, done } = props;
  const allTargets = useMemo(() => Array.from(new Set([...buildTargets, ...testTargets])), [buildTargets, testTargets]);

  const root = useMemo(() => {
    const r = buildTargetTree<SummaryData>(
      allTargets,
      (target) => {
        const status = getTargetStatus(target, buildTargets, testTargets, buildMap, testMap, done);
        const severity = getSeverity(status);
        const isPassing = status === 'SUCCESSFUL';
        const isPending = status === 'PENDING' || (!done && status === 'UNKNOWN');
        return { status, maxSeverity: severity, totalTargets: 1, passedTargets: isPassing ? 1 : 0, pendingTargets: isPending ? 1 : 0 };
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
        // Exclude UNKNOWN nodes entirely from parent totals as they are invalid
        if (child.isTarget && child.data.status === 'UNKNOWN') continue;
        
        total += stats.total;
        passed += stats.passed;
        pending += stats.pending;
      }
      
      // If we're a folder and have 0 valid totalTargets because all children were UNKNOWN,
      // we don't want to show 0/0 and 100%. Set maxSev=2 to represent Unknown/Skipped
      if (!node.isTarget && total === 0) {
         maxSev = 2; // match UNKNOWN severity
      }
      
      node.data.maxSeverity = maxSev;
      node.data.totalTargets = total;
      node.data.passedTargets = passed;
      node.data.pendingTargets = pending;
      return { maxSev, total, passed, pending };
    };
    computeMetrics(r);
    
    /** 
     * Applies expansion heuristics to ensure the tree defaults to a manageable 
     * view without hiding important failures from the user.
     */
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
  }, [allTargets, buildTargets, testTargets, buildMap, testMap, done]);

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
      
      // Push UNKNOWN targets to the bottom
      const aIsUnknown = a.isTarget && a.data.status === 'UNKNOWN';
      const bIsUnknown = b.isTarget && b.data.status === 'UNKNOWN';
      if (aIsUnknown !== bIsUnknown) return aIsUnknown ? 1 : -1;

      return a.name.localeCompare(b.name);
    });
    return nodes;
  }, [root, version]);
  
  return { root, flatNodes, allTargets, toggleNodeExpansion };
}

/**
 * Renders an individual node within the execution summary tree.
 */
function SummaryTreeItem({ item, cursor, index, startIdx }: { item: { node: SummaryNode, depth: number }, cursor: number, index: number, startIdx: number }) {
  const actualIndex = startIdx + index;
  const isFocused = actualIndex === cursor;
  const isTarget = item.node.isTarget;
  const bg = isFocused ? '#1e2e3e' : undefined;
  const icon = !isTarget ? (item.node.isExpanded ? '-' : '+') : '';
  const isUnknown = isTarget && item.node.data.status === 'UNKNOWN';

  return (
    <Box flexDirection="row" width="100%" backgroundColor={bg}>
      <Box width={3} flexShrink={0}>
        <Text color="cyanBright" bold={isFocused}>{isFocused ? ' ❯ ' : '   '}</Text>
      </Box>
      <Box width={item.depth * 2} flexShrink={0} />
      
      <Box flexGrow={1} flexDirection="row" justifyContent="space-between" minWidth={0}>
        <Box minWidth={0} paddingRight={1} flexGrow={1}>
          <Text color={isFocused ? (!isTarget ? 'cyanBright' :'whiteBright') : (!isTarget ? 'cyan' : (isUnknown ? 'grey' : 'gray'))} bold={!isTarget || isFocused} wrap="truncate-end">
            {icon ? `${icon} ` : ''}{item.node.name}
          </Text>
        </Box>
        <Box width={10} justifyContent="flex-end" flexShrink={0}>
          {(() => {
             if (!isTarget) {
               const { totalTargets, passedTargets, pendingTargets } = item.node.data;
               if (totalTargets === 0) {
                 return <Text dimColor>-</Text>;
               }
               if (pendingTargets === totalTargets) {
                 return <Text dimColor>-</Text>;
               }
               const pct = totalTargets > 0 ? Math.round((passedTargets / totalTargets) * 100) : 0;
               if (pendingTargets > 0) {
                 return <Text dimColor>{pct}%</Text>;
               }
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

/**
 * Renders an actionable OS-level hyperlink to a Sponge execution log.
 */
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
  const { flatNodes, allTargets, toggleNodeExpansion } = useSummaryTree(props);
  const [cursor, setCursor] = useState(0);
  const { exit } = useApp();

  const selectedNode = flatNodes[cursor]?.node;
  const isSelectedB = selectedNode ? props.buildTargets.includes(selectedNode.fullPath) : false;
  const isSelectedT = selectedNode ? props.testTargets.includes(selectedNode.fullPath) : false;

  const spongeUrl = useMemo(() => {
    if (!selectedNode || !selectedNode.isTarget) return null;
    const sid = (isSelectedB && props.buildSpongeId) ? props.buildSpongeId : (isSelectedT && props.testSpongeId ? props.testSpongeId : (props.buildSpongeId || props.testSpongeId));
    if (sid) {
       return `http://sponge2/${sid}/targets/${encodeURIComponent(selectedNode.fullPath)}/log`;
    }
    return null;
  }, [selectedNode, isSelectedB, isSelectedT, props.buildSpongeId, props.testSpongeId]);
  const { showNotification } = useNotification();
  const controls = useControls([
    {
      id: 'up', displayKey: '↑', label: 'Up', isActive: true, isVisuallyDisplayed: false,
      matcher: (_, key) => key.upArrow,
      action: () => setCursor(c => Math.max(0, c - 1))
    },
    {
      id: 'down', displayKey: '↓', label: 'Down', isActive: true, isVisuallyDisplayed: false,
      matcher: (_, key) => key.downArrow,
      action: () => setCursor(c => Math.min(flatNodes.length - 1, c + 1))
    },
    {
      id: 'expand', displayKey: '←/→', label: 'Expand/Collapse', isActive: true,
      matcher: (_, key) => key.leftArrow || key.rightArrow,
      action: () => {
        if (selectedNode) toggleNodeExpansion(selectedNode);
      }
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
      matcher: (input, key) => key.ctrl && input === 'c',
      action: exit
    }
  ]);

  const maxLines = 16;
  const startIdx = Math.max(0, Math.min(cursor - Math.floor(maxLines / 2), flatNodes.length - maxLines));
  const visibleItems = flatNodes.slice(startIdx, startIdx + maxLines);

  const stats = useMemo(() => {
    let passing = 0, failing = 0, pending = 0;
    allTargets.forEach(target => {
      const status = getTargetStatus(target, props.buildTargets, props.testTargets, props.buildMap, props.testMap, props.done);
      if (status === 'SUCCESSFUL') passing++;
      else if (status === 'FAILED' || status === 'BROKEN') failing++;
      else if (status === 'PENDING' || (!props.done && status === 'UNKNOWN')) pending++;
    });
    return { passing, failing, pending };
  }, [allTargets, props]);

  return (
    <Box flexDirection="column" borderStyle="round" borderColor="dim" paddingX={1} paddingY={0}>
      <Box flexDirection="row" justifyContent="space-between" marginBottom={1}>
         <Box flexDirection="row">
           <Text bold color="cyanBright">BLAZER </Text><Text dimColor>/ execution summary</Text>
         </Box>
         <Box flexDirection="row">
            <Text color="greenBright">{stats.passing} passed</Text><Text dimColor>  •  </Text>
            <Text color={stats.failing > 0 ? "redBright" : "dim"}>{stats.failing} failed</Text>
            {stats.pending > 0 && <><Text dimColor>  •  </Text><Text color="cyanBright">{stats.pending} pending</Text></>}
         </Box>
      </Box>

      <Box flexDirection="row" width="100%">
        <Box flexDirection="column" width="60%" paddingRight={1}>
           {visibleItems.map((item, index) => (
             <SummaryTreeItem key={index} item={item} cursor={cursor} index={index} startIdx={startIdx} />
           ))}
        </Box>

        <Box flexDirection="column" width="40%" paddingLeft={3}>
           {selectedNode ? (
             <Box flexDirection="column">
               <Text bold color="whiteBright">SELECTION DETAILS</Text>
               <Text dimColor>──────────────────────</Text>
               <Box flexDirection="column" marginBottom={1} marginTop={1}>
                  <Text bold color="cyanBright">{selectedNode.name}</Text>
                  {selectedNode.isTarget && <Text dimColor wrap="truncate">{selectedNode.fullPath}</Text>}
               </Box>

               {selectedNode.isTarget ? (
                 <Box flexDirection="column">
                   {isSelectedB && <SpongeLogLink spongeId={props.buildSpongeId} fullPath={selectedNode.fullPath} pass={props.buildMap.get(selectedNode.fullPath) === 'SUCCESSFUL'} phase="Build Phase:" />}
                   {isSelectedT && <SpongeLogLink spongeId={props.testSpongeId} fullPath={selectedNode.fullPath} pass={props.testMap.get(selectedNode.fullPath) === 'SUCCESSFUL'} phase="Test Phase:" marginTop={isSelectedB ? 1 : 0} />}
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
