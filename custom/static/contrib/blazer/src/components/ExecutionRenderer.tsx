import React, { useEffect, useState, useRef } from 'react';
import { Box, Text, useInput, useApp } from 'ink';
import { blazeBuild, blazeTest } from '../lib/blaze';
import { ExecutionSummary } from './ExecutionSummary';
import { randomUUID } from 'crypto';
import { BepStreamer, type TargetStatus } from '../lib/reconciliation';

export interface ExecutionProps {
  buildTargets: string[];
  testTargets: string[];
}

function getSpongeId(link?: string | null): string | null {
  if (!link) return null;
  const match = link.match(/sponge2\/([a-f0-9-]+)/);
  return match ? match[1] ?? null : null;
}

/**
 * Hook to manage execution of a Blaze command asynchronously.
 */
function useBlazeExecution(targets: string[], runner: typeof blazeBuild | typeof blazeTest) {
  const [log, setLog] = useState<string>('Initializing...\n');
  const logRef = useRef<string>('');
  const [done, setDone] = useState(targets.length === 0);
  const [exitCode, setExitCode] = useState<number | null>(null);
  const [spongeLink, setSpongeLink] = useState<string | null>(null);
  const [spongeId, setSpongeId] = useState<string | null>(null);
  const [statusMap, setStatusMap] = useState<Map<string, TargetStatus>>(new Map());

  useEffect(() => {
    if (targets.length === 0) {
      setLog('Skipped.');
      setDone(true);
      return;
    }

    const bepFile = `/tmp/blazer-${randomUUID()}.json`;
    const streamer = new BepStreamer(bepFile, setStatusMap);
    streamer.start();

    const appendLog = (data: Buffer | string) => {
      const d = data.toString();
      logRef.current += d;
      setLog(l => (l + d).slice(-5000));
    };

    runner(targets, bepFile, {
      onStdout: appendLog,
      onStderr: appendLog,
      onSpongeLink: link => {
        setSpongeLink(link ?? null);
        setSpongeId(getSpongeId(link));
      },
      onClose: code => {
        setExitCode(code || 0);
        setLog(l => l + `\n[DONE] Exit code: ${code}`);
        setDone(true);
        setTimeout(() => streamer.stop(), 500);
      }
    });

    return () => streamer.stop();
  }, [targets, runner]);

  return { log, logRef, done, exitCode, spongeLink, spongeId, statusMap };
}

interface LogPanelProps {
  title: string;
  exitCode: number | null;
  log: string;
  done: boolean;
  spongeLink: string | null;
  marginRight?: number;
  marginLeft?: number;
}

/**
 * UI Component for rendering live terminal output segments.
 */
function LogPanel({ title, exitCode, log, done, spongeLink, marginRight = 0, marginLeft = 0 }: LogPanelProps) {
  const MAX_LINES = 18;
  const recentLines = log.split('\n').filter(Boolean).slice(-MAX_LINES);
  while (recentLines.length < MAX_LINES) recentLines.push(' ');

  const renderLogLine = (line: string, i: number) => {
    let color = 'dim';
    if (line.includes('PASSED')) color = 'greenBright';
    else if (line.includes('FAILED') || line.includes('ERROR')) color = 'redBright';
    else if (line.includes('WARNING')) color = 'yellow';
    return <Text key={i} color={color} wrap="truncate">{line}</Text>;
  };

  return (
    <Box flexDirection="column" width="50%" marginRight={marginRight} marginLeft={marginLeft}>
      <Box marginBottom={1} flexDirection="row">
         <Text bold>
           <Text backgroundColor="whiteBright" color="black">  {title}  </Text>
           {exitCode === 0 && <Text backgroundColor="greenBright" color="black">  PASSED  </Text>}
           {exitCode !== null && exitCode !== 0 && <Text backgroundColor="redBright" color="whiteBright">  FAILED  </Text>}
         </Text>
      </Box>
      <Box flexDirection="column" overflow="hidden" minHeight={MAX_LINES} height={MAX_LINES}>
        {recentLines.map(renderLogLine)}
      </Box>
      {(done && spongeLink) && (
        <Box marginTop={1}>
          <Text bold color="cyan">Sponge2: </Text>
          <Text underline color="blueBright" wrap="truncate">{spongeLink}</Text>
        </Box>
      )}
    </Box>
  );
}

/**
 * Controller component orchestrating BUILD and TEST phases for all targets.
 */
export function ExecutionRenderer({ buildTargets, testTargets }: ExecutionProps) {
  const { exit } = useApp();
  
  useInput((input, key) => {
    if (key.ctrl && input === 'c') exit();
  });

  const build = useBlazeExecution(buildTargets, blazeBuild);
  const test = useBlazeExecution(testTargets, blazeTest);

  const done = build.done && test.done;

  return (
    <Box flexDirection="column">
      <Box flexDirection="row" width="100%">
        {buildTargets.length > 0 && (
          <LogPanel 
            title="BUILD" 
            exitCode={build.exitCode} 
            log={build.log} 
            done={build.done} 
            spongeLink={build.spongeLink} 
            marginRight={1} 
          />
        )}
        
        {testTargets.length > 0 && (
          <LogPanel 
            title="TEST" 
            exitCode={test.exitCode} 
            log={test.log} 
            done={test.done} 
            spongeLink={test.spongeLink} 
            marginLeft={1} 
          />
        )}
      </Box>

      <ExecutionSummary
        buildTargets={buildTargets}
        testTargets={testTargets}
        buildExitCode={build.exitCode}
        testExitCode={test.exitCode}
        buildSpongeId={build.spongeId}
        testSpongeId={test.spongeId}
        buildMap={build.statusMap}
        testMap={test.statusMap}
        done={done}
      />
    </Box>
  );
}
