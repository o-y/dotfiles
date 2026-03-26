import React from 'react';
import { Box, Text } from 'ink';
import type { ExecutionResult } from './ExecutionRenderer';

export interface TimelineProps {
  history: ExecutionResult[];
  viewedIdx: number;
  isFocused: boolean;
  done: boolean;
  displayCount: number;
}

export function Timeline({ history, viewedIdx, isFocused, done, displayCount }: TimelineProps) {
  if (displayCount <= 1) return null;

  return (
    <Box flexDirection="row" alignItems="center" height={1}>
      {Array.from({ length: displayCount }).map((_, i) => {
        const isHistorical = i < history.length;
        const run = isHistorical ? history[i] : null;
        
        const isViewed = i === viewedIdx || (viewedIdx === -1 && i === displayCount - 1);
        
        let hasFailure = false;
        if (run) {
           hasFailure = (run.buildExitCode !== 0 && run.buildExitCode !== null) || (run.testExitCode !== 0 && run.testExitCode !== null);
        }
        
        let color = hasFailure ? 'red' : 'green';
        if (!isHistorical) {
           color = 'cyan';
        }
        
        if (isViewed) {
           if (isHistorical) {
              color = hasFailure ? 'redBright' : 'greenBright';
           } else {
              color = 'cyanBright';
           }
        }

        const char = isViewed ? '●' : '○';

        return (
          <Box key={i} flexDirection="row" alignItems="center">
            {i > 0 && <Text color="gray" dimColor>──</Text>}
            <Text color={isFocused && isViewed ? 'cyanBright' : color} bold={isViewed}>{char}</Text>
          </Box>
        );
      })}
    </Box>
  );
}
