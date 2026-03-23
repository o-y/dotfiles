import React, { useState, useMemo } from 'react';
import { Box, Text } from 'ink';
import { ProgressBar } from '@inkjs/ui';
import { useControls, ControlsDisplay } from '../hooks/useControls';
import { buildTargetTree, compressTree, flattenTree, extractAllTargets, type TreeNode } from '../lib/tree';

export interface TargetSelectorProps {
  type: 'BUILD' | 'TEST';
  targets: string[];
  onSubmit: (selectedTargets: string[]) => void;
  onExpand?: (coverage: number, onOutput: (data: string) => void) => Promise<void>;
}

/**
 * Initializes and manages a collapsible tree structure of targets.
 */
function useTargetTree(targets: string[]) {
  const [root, setRoot] = useState<TreeNode>(() => {
    return initializeTree(targets);
  });

  const [version, setVersion] = useState(0);

  // Sync tree when targets prop changes
  React.useEffect(() => {
    setRoot(initializeTree(targets));
    setVersion(v => v + 1);
  }, [targets]);

  function initializeTree(targets: string[]) {
    const r = buildTargetTree<{}>(targets, () => ({}), () => ({}));
    compressTree(r, true);
    
    const applyHeuristics = (node: TreeNode, depth: number): number => {
      if (node.isTarget) return 1;
      let count = 0;
      for (const child of node.children.values()) count += applyHeuristics(child, depth + 1);
      node.isExpanded = depth === 0 || depth <= 2 || count <= 10;
      return count;
    };
    applyHeuristics(r, 0);
    return r;
  }
  const toggleNodeExpansion = (node: TreeNode) => {
    node.isExpanded = !node.isExpanded;
    setVersion(v => v + 1);
  };

  const flatNodes = useMemo(() => {
    const nodes: { node: TreeNode, depth: number }[] = [];
    flattenTree(root, 0, nodes, (a, b) => {
      if (a.isTarget !== b.isTarget) return a.isTarget ? 1 : -1;
      return a.name.localeCompare(b.name);
    });
    return nodes;
  }, [root, version]);

  const allTargets = useMemo(() => {
    const all: string[] = [];
    extractAllTargets(root, all);
    return all;
  }, [root]);

  return { root, flatNodes, allTargets, toggleNodeExpansion };
}

/**
 * Manages cursor navigation, visible windowing, and target selections.
 */
function useTreeSelection(flatNodes: { node: TreeNode, depth: number }[], allTargets: string[]) {
  const [cursor, setCursor] = useState(0);
  const [selected, setSelected] = useState<Set<string>>(() => new Set(allTargets));

  const toggleTarget = (targetPath: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(targetPath)) next.delete(targetPath);
      else next.add(targetPath);
      return next;
    });
  };

  const toggleFolderSubtree = (folderNode: TreeNode) => {
    const allSubTargets: string[] = [];
    const extract = (x: TreeNode) => {
      if (x.isTarget) allSubTargets.push(x.fullPath);
      x.children.forEach(extract);
    };
    extract(folderNode);

    const allSelected = allSubTargets.every(t => selected.has(t));
    setSelected((prev) => {
      const next = new Set(prev);
      for (const t of allSubTargets) {
        if (allSelected) next.delete(t);
        else next.add(t);
      }
      return next;
    });
  };

  const toggleAll = () => {
    if (selected.size === allTargets.length) setSelected(new Set());
    else setSelected(new Set(allTargets));
  };

  return { cursor, setCursor, selected, toggleTarget, toggleFolderSubtree, toggleAll };
}

/** Visual representation of a single tree element (folder or target). */
function TreeItem({ 
  isFocused, isTarget, isExpanded, isSelected, depth, name 
}: { 
  isFocused: boolean, isTarget: boolean, isExpanded: boolean, isSelected: boolean, depth: number, name: string 
}) {
  const paddingStr = '  '.repeat(depth);
  const bgColor = isFocused ? '#1e2e3e' : undefined;
  
  const icon = isTarget ? (isSelected ? '[×]' : '[ ]') : (isExpanded ? '-' : '+');
  const targetColor = isFocused ? 'whiteBright' : (isSelected ? 'whiteBright' : 'gray');
  const checkColor = isFocused ? 'whiteBright' : (isSelected ? 'greenBright' : 'dim');

  return (
    <Box flexDirection="row" width="100%" backgroundColor={bgColor}>
      <Box width={3} flexShrink={0}>
        <Text color="cyanBright" bold>{isFocused ? ' ❯ ' : '   '}</Text>
      </Box>
      <Box flexGrow={1} flexDirection="row" minWidth={0} paddingRight={1}>
        <Text dimColor>{paddingStr}</Text>
        {!isTarget ? (
          <Text color={isFocused ? 'cyanBright' : 'cyan'} bold wrap="truncate">
            {icon} {name}
          </Text>
        ) : (
          <Text wrap="truncate">
            <Text color={checkColor} bold={isFocused || isSelected}>{icon} </Text>
            <Text color={targetColor} bold={isFocused || isSelected}>{name}</Text>
          </Text>
        )}
      </Box>
    </Box>
  );
}

/**
 * Component for selecting build/test targets using a collapsible tree view.
 */
export function TargetSelector({ type, targets, onSubmit, onExpand }: TargetSelectorProps) {
  const { flatNodes, allTargets, toggleNodeExpansion } = useTargetTree(targets);
  const { cursor, setCursor, selected, toggleTarget, toggleFolderSubtree, toggleAll } = useTreeSelection(flatNodes, allTargets);
  const [coverage, setCoverage] = useState(20);
  const [isExpanding, setIsExpanding] = useState(false);
  const [expandLogs, setExpandLogs] = useState<string>('');

  const handleExpand = async () => {
    if (!onExpand || isExpanding) return;
    setIsExpanding(true);
    setExpandLogs('');
    try {
      await onExpand(coverage, (data: string) => {
        // Only update logs if they changed to reduce re-renders
        setExpandLogs(prev => {
          const next = (prev + data).split('\n').slice(-5).join('\n');
          return next === prev ? prev : next;
        });
      });
    } catch (err: any) {
      setExpandLogs(`Error: ${err.message || String(err)}`);
    } finally {
      setIsExpanding(false);
    }
  };

  const controls = useControls([
    {
      id: 'up', displayKey: '↑', label: 'Up', isActive: !isExpanding, isVisuallyDisplayed: false,
      matcher: (_, key) => key.upArrow,
      action: () => setCursor(c => Math.max(0, c - 1))
    },
    {
      id: 'down', displayKey: '↓', label: 'Down', isActive: !isExpanding, isVisuallyDisplayed: false,
      matcher: (_, key) => key.downArrow,
      action: () => setCursor(c => Math.min(flatNodes.length - 1, c + 1))
    },
    {
      id: 'expand', displayKey: '←/→', label: 'Expand/Collapse', isActive: !isExpanding,
      matcher: (_, key) => key.leftArrow || key.rightArrow,
      action: () => {
        const nodeItem = flatNodes[cursor];
        if (nodeItem && !nodeItem.node.isTarget) toggleNodeExpansion(nodeItem.node);
      }
    },
    {
      id: 'toggle', displayKey: 'Spc', label: 'Toggle', isActive: !isExpanding,
      matcher: (input) => input === ' ',
      action: () => {
        const nodeItem = flatNodes[cursor];
        if (nodeItem?.node.isTarget) toggleTarget(nodeItem.node.fullPath);
        else if (nodeItem) toggleFolderSubtree(nodeItem.node);
      }
    },
    {
      id: 'coverageDown', displayKey: '[', label: 'Decrease Radius', isActive: !isExpanding,
      matcher: (input) => input === '[',
      action: () => setCoverage(c => Math.max(0, c - 5))
    },
    {
      id: 'coverageUp', displayKey: ']', label: 'Increase Radius', isActive: !isExpanding,
      matcher: (input) => input === ']',
      action: () => setCoverage(c => Math.min(100, c + 5))
    },
    {
      id: 'triggerExpand', displayKey: 'E', label: 'Execute Radius Expansion', isActive: !isExpanding && !!onExpand,
      matcher: (input) => input === 'e' || input === 'E',
      action: handleExpand
    },
    {
      id: 'toggleAll', displayKey: 'Ctrl+A', label: 'Toggle All', isActive: !isExpanding,
      matcher: (input, key) => key.ctrl && input === 'a',
      action: () => toggleAll()
    },
    {
      id: 'submit', displayKey: 'Enter', label: 'Submit', isActive: !isExpanding,
      matcher: (_, key) => key.return,
      action: () => onSubmit(Array.from(selected))
    }
  ]);

  if (allTargets.length === 0) {
    return (
      <Box flexDirection="column" marginY={1}>
        <Text color="red">No {type} targets found.</Text>
        <Text dimColor>Press Enter to exit.</Text>
      </Box>
    );
  }

  const maxLines = 15;
  const startIdx = Math.max(0, Math.min(cursor - Math.floor(maxLines / 2), flatNodes.length - maxLines));
  const visibleItems = flatNodes.slice(startIdx, startIdx + maxLines);

  return (
    <Box flexDirection="column" borderStyle="round" borderColor="dim" paddingX={1} paddingBottom={0} paddingTop={0}>
      <Box flexDirection="row" justifyContent="space-between" marginBottom={0}>
        <Box flexDirection="row">
          <Text bold backgroundColor="whiteBright" color="black"> {type.toUpperCase()} </Text>
        </Box>
        <Box flexDirection="row">
          <Text bold color="cyanBright">{selected.size}</Text>
          <Text color="gray"> / {allTargets.length} selected</Text>
        </Box>
      </Box>
      
      <Box flexDirection="column" marginTop={1}>
        {visibleItems.map((item, index) => {
          const actualIndex = startIdx + index;
          const isFocused = actualIndex === cursor;
          const { isTarget, isExpanded, name, fullPath } = item.node;
          const isSelected = isTarget && selected.has(fullPath);
          
          return (
            <TreeItem 
               key={`${actualIndex}-${fullPath || name}`}
               isFocused={isFocused}
               isTarget={isTarget}
               isExpanded={!!isExpanded}
               isSelected={isSelected}
               depth={item.depth}
               name={name}
            />
          );
        })}
      </Box>

      <Box marginTop={1} flexDirection="column" paddingTop={1}>
        <Box flexDirection="row" justifyContent="space-between" marginBottom={1}>
          <Box flexDirection="column" width={30}>
            <Box flexDirection="row" justifyContent="space-between" marginBottom={0.5}>
              <Text color="gray">Expansion Radius</Text>
              <Text color="cyanBright" bold>{coverage}%</Text>
            </Box>
            <ProgressBar value={coverage} />
          </Box>
          {isExpanding && (
            <Box alignItems="center">
               <Text color="yellowBright" bold inverse> EXPANDING </Text>
            </Box>
          )}
        </Box>

        {isExpanding && expandLogs && (
          <Box paddingX={1} marginBottom={1} borderStyle="single" borderColor="yellow" borderLeft borderRight={false} borderTop={false} borderBottom={false}>
            <Text dimColor italic>{expandLogs}</Text>
          </Box>
        )}

        <ControlsDisplay controls={controls} />
      </Box>
    </Box>
  );
}
