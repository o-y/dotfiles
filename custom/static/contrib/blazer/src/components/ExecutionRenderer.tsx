import React, { useEffect, useState, useRef } from 'react';
import { Box, Text, useInput, useApp } from 'ink';
import { ExecutionSummary } from './ExecutionSummary';
import { type TargetStatus, getSpongeId } from '../lib/reconciliation';
import { runExecution } from '../lib/engine';

export interface ExecutionResult {
  version: number;
  buildMap: Map<string, TargetStatus>;
  testMap: Map<string, TargetStatus>;
  buildExitCode: number | null;
  testExitCode: number | null;
  buildSpongeId: string | null;
  testSpongeId: string | null;
  timestamp: Date;
}

export interface ExecutionProps {
  buildTargets: string[];
  testTargets: string[];
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
  const [version, setVersion] = useState(0);
  const [history, setHistory] = useState<ExecutionResult[]>([]);
  
  const [buildLog, setBuildLog] = useState('');
  const [testLog, setTestLog] = useState('');
  const [buildDone, setBuildDone] = useState(buildTargets.length === 0);
  const [testDone, setTestDone] = useState(testTargets.length === 0);
  const [buildExitCode, setBuildExitCode] = useState<number | null>(null);
  const [testExitCode, setTestExitCode] = useState<number | null>(null);
  const [buildSponge, setBuildSponge] = useState<string | null>(null);
  const [testSponge, setTestSponge] = useState<string | null>(null);
  const [buildStatusMap, setBuildStatusMap] = useState<Map<string, TargetStatus>>(new Map());
  const [testStatusMap, setTestStatusMap] = useState<Map<string, TargetStatus>>(new Map());

  useInput((input, key) => {
    if (key?.ctrl && input === 'c') exit();
  });

  useEffect(() => {
    setBuildLog(buildTargets.length === 0 ? 'Skipped.' : 'Initializing...\n');
    setTestLog(testTargets.length === 0 ? 'Skipped.' : 'Initializing...\n');
    setBuildDone(buildTargets.length === 0);
    setTestDone(testTargets.length === 0);
    setBuildExitCode(null);
    setTestExitCode(null);
    setBuildSponge(null);
    setTestSponge(null);
    setBuildStatusMap(new Map());
    setTestStatusMap(new Map());

    runExecution(buildTargets, testTargets, {
      onBuildStdout: (d) => setBuildLog(l => (l + d).slice(-5000)),
      onBuildStderr: (d) => setBuildLog(l => (l + d).slice(-5000)),
      onBuildSponge: (link) => setBuildSponge(link),
      onTestStdout: (d) => setTestLog(l => (l + d).slice(-5000)),
      onTestStderr: (d) => setTestLog(l => (l + d).slice(-5000)),
      onTestSponge: (link) => setTestSponge(link),
      onStatusUpdate: (bMap, tMap) => {
        setBuildStatusMap(bMap);
        setTestStatusMap(tMap);
      },
      onComplete: (bCode, tCode) => {
        setBuildExitCode(bCode);
        setTestExitCode(tCode);
        setBuildDone(true);
        setTestDone(true);
      }
    });
  }, [version, buildTargets, testTargets]);

  useEffect(() => {
    if (buildDone && testDone) {
       setHistory(prev => {
         const last = prev[prev.length - 1];
         if (last && last.version === version) return prev;
         return [...prev, {
           version,
           buildMap: new Map(buildStatusMap),
           testMap: new Map(testStatusMap),
           buildExitCode,
           testExitCode,
           buildSpongeId: getSpongeId(buildSponge),
           testSpongeId: getSpongeId(testSponge),
           timestamp: new Date()
         }];
       });
    }
  }, [buildDone, testDone, version, buildStatusMap, testStatusMap, buildExitCode, testExitCode, buildSponge, testSponge]);

  const handleReexecute = () => {
    if (buildDone && testDone) {
       setVersion(v => v + 1);
    }
  };

  const done = buildDone && testDone;

  return (
    <Box flexDirection="column">
      <Box flexDirection="row" width="100%">
        {buildTargets.length > 0 && (
          <LogPanel 
            title="BUILD" 
            exitCode={buildExitCode} 
            log={buildLog} 
            done={buildDone} 
            spongeLink={buildSponge} 
            marginRight={1} 
          />
        )}
        
        {testTargets.length > 0 && (
          <LogPanel 
            title="TEST" 
            exitCode={testExitCode} 
            log={testLog} 
            done={testDone} 
            spongeLink={testSponge} 
            marginLeft={1} 
          />
        )}
      </Box>

      <ExecutionSummary
        buildTargets={buildTargets}
        testTargets={testTargets}
        buildExitCode={buildExitCode}
        testExitCode={testExitCode}
        buildSpongeId={getSpongeId(buildSponge)}
        testSpongeId={getSpongeId(testSponge)}
        buildMap={buildStatusMap}
        testMap={testStatusMap}
        done={done}
        history={history}
        onReexecute={handleReexecute}
      />
    </Box>
  );
}
