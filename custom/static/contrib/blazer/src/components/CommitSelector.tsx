import React, { useEffect, useState, useMemo } from 'react';
import { Box, Text } from 'ink';
import { useControls, ControlsDisplay } from '../hooks/useControls';
import Spinner from 'ink-spinner';
import { getJjLog, type JjCommit } from '../lib/jj';

/** Standard base branch identifier for fetching JJ commits */
const BASE_REVISION = 'p4base';

/**
 * Fetches and manages the list of jj commits to select from.
 */
function useJjCommits(base: string) {
  const [commits, setCommits] = useState<JjCommit[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getJjLog(base)
      .then(setCommits)
      .catch((err) => setError(err instanceof Error ? err.message : String(err)))
      .finally(() => setLoading(false));
  }, [base]);

  return { commits, loading, error };
}

interface SelectableCommitItem {
  label: string;
  value: string;
  changeId: string;
  description: string;
  tag?: string;
}

/**
 * Individual row renderer for the commit list.
 */
function CommitItemRenderer({ isSelected, changeId, description, tag }: { isSelected?: boolean } & SelectableCommitItem) {
  const renderId = () => {
    if (tag) {
      const color = isSelected ? 'cyanBright' : 'cyan';
      return <Text color={color} bold>{`[${tag}]`.padEnd(11)}</Text>;
    }

    const shortId = changeId.slice(0, 5);
    const prefix = shortId.slice(0, 3);
    const suffix = shortId.slice(3, 5).padEnd(2 + (11 - 5));

    return (
      <Text>
        <Text color="magentaBright" bold={isSelected}>{prefix}</Text>
        <Text color={isSelected ? 'whiteBright' : 'dim'}>{suffix}</Text>
      </Text>
    );
  };

  return (
    <Box flexDirection="row" width="100%" backgroundColor={isSelected ? '#1e2e3e' : undefined}>
      <Box width={3} flexShrink={0}>
        <Text color="cyanBright" bold={isSelected}>{isSelected ? ' ❯ ' : '   '}</Text>
      </Box>
      <Box flexGrow={1} flexDirection="row" minWidth={0}>
        <Box flexShrink={0}>
          {renderId()}
        </Box>
        <Box minWidth={0} flexGrow={1} paddingX={1}>
          <Text color={isSelected ? 'whiteBright' : 'gray'} wrap="truncate">
            {description}
          </Text>
        </Box>
      </Box>
    </Box>
  );
}

export interface CommitSelectorProps {
  onSelect: (commit: string) => void;
}

/**
 * Core interface component that allows users to pick a baseline JJ commit for diffing.
 */
export function CommitSelector({ onSelect }: CommitSelectorProps) {
  const { commits, loading, error } = useJjCommits(BASE_REVISION);
  const [cursor, setCursor] = useState(0);

  const items = useMemo<SelectableCommitItem[]>(() => {
    const list = commits.map((c, i) => ({
      label: i === 0 ? `@- ${c.changeId}` : c.changeId,
      value: i === 0 ? '@-' : c.changeId,
      changeId: c.changeId,
      description: c.description,
      tag: i === 0 ? '@-' : undefined,
    }));
    
    if (!list.find(i => i.value === BASE_REVISION)) {
      list.push({
        label: BASE_REVISION,
        value: BASE_REVISION,
        changeId: '',
        description: 'Base of stacked commits',
        tag: BASE_REVISION,
      });
    }
    return list;
  }, [commits]);

  const controls = useControls([
    {
      id: 'up', displayKey: '↑', label: 'Up', isActive: !loading, isVisuallyDisplayed: true,
      matcher: (_, key) => key.upArrow,
      action: () => setCursor(c => Math.max(0, c - 1))
    },
    {
      id: 'down', displayKey: '↓', label: 'Down', isActive: !loading, isVisuallyDisplayed: true,
      matcher: (_, key) => key.downArrow,
      action: () => setCursor(c => Math.min(items.length - 1, c + 1))
    },
    {
      id: 'submit', displayKey: 'Enter', label: 'Submit', isActive: !loading,
      matcher: (_, key) => key.return,
      action: () => {
        if (items[cursor]) onSelect(items[cursor].value);
      }
    }
  ]);

  if (error) {
    return <Text color="red">Error loading JJ commits: {error}</Text>;
  }
  
  if (loading) {
    return (
      <Box>
        <Text color="green"><Spinner type="dots" /> </Text>
        <Text>Loading commits from {BASE_REVISION}...</Text>
      </Box>
    );
  }

  return (
    <Box flexDirection="column" borderStyle="round" borderColor="dim" paddingX={1} paddingY={0}>
      <Box flexDirection="row" justifyContent="space-between" marginBottom={1}>
        <Box flexDirection="row">
          <Text bold backgroundColor="whiteBright" color="black"> SELECT BASE COMMIT </Text>
        </Box>
      </Box>

      <Box flexDirection="column" marginBottom={1}>
        {items.map((item, index) => (
          <CommitItemRenderer 
            key={item.value} 
            isSelected={index === cursor} 
            {...item} 
          />
        ))}
      </Box>

      <ControlsDisplay controls={controls} />
    </Box>
  );
}
