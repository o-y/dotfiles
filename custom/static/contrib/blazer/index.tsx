import React from 'react';
import { render, Text, Box } from 'ink';
import { Clerc, defineCommand } from 'clerc';
import { completionsPlugin } from '@clerc/plugin-completions';
import { helpPlugin } from '@clerc/plugin-help';
import Spinner from 'ink-spinner';

import { CommitSelector } from './src/components/CommitSelector';
import { TargetSelector } from './src/components/TargetSelector';
import { ExecutionRenderer } from './src/components/ExecutionRenderer';
import { useBlazerWorkflow } from './src/hooks/useBlazerWorkflow';
import { NotificationProvider } from './src/hooks/useNotification';
import { runCLI } from './src/cli';


/**
 * The main Blazer terminal UI application.
 */
const App = () => {
  const state = useBlazerWorkflow();

  const renderView = () => {
    switch (state.view) {
      case 'SELECT_COMMIT':
        return <CommitSelector onSelect={state.actions.selectCommit} />;
      case 'LOADING_TARGETS':
        return (
          <Box flexDirection="column">
            <Box alignItems="center">
              <Text color="cyan"><Spinner type="dots" /> </Text>
              <Text dimColor>Evaluating graph extension for base </Text>
              <Text bold color="white">{state.baseCommit}</Text>
            </Box>
            <Box marginLeft={2} marginTop={1} paddingLeft={2} borderStyle="single" borderLeft borderColor="dim" borderTop={false} borderRight={false} borderBottom={false}>
              <Text dimColor>{state.targetStream.split(/[\r\n]/).filter(Boolean).slice(-6).join('\n') || '...'}</Text>
            </Box>
          </Box>
        );
      case 'SELECT_BUILD_TARGETS':
        return state.affectedTargets && (
          <TargetSelector key="build" type="BUILD" targets={state.affectedTargets.buildTargets} onSubmit={state.actions.selectBuildTargets} onExpand={state.actions.expandTargets} />
        );
      case 'SELECT_TEST_TARGETS':
        return state.affectedTargets && (
          <TargetSelector key="test" type="TEST" targets={state.affectedTargets.testTargets} onSubmit={state.actions.selectTestTargets} onExpand={state.actions.expandTargets} />
        );
      case 'EXECUTE':
        return <ExecutionRenderer buildTargets={state.selectedBuilds} testTargets={state.selectedTests} />;
      case 'ERROR':
        return (
          <Box borderStyle="single" borderColor="red">
            <Text color="red"> FATAL ERROR </Text>
            <Text dimColor>{state.errorObj}</Text>
          </Box>
        );
      default:
        return null;
    }
  };

  return (
    <Box flexDirection="column" paddingX={2} paddingTop={1}>
      <Box marginBottom={1} flexDirection="row" alignItems="center">
         <Text bold color="black" backgroundColor="cyan"> BLAZER </Text>
         <Text dimColor>  BLAZE AFFECTED TARGETS BUILDER</Text>
      </Box>
      {renderView()}
    </Box>
  );
};

const uiCommand = defineCommand({
  name: 'ui',
  description: 'Launch the interactive terminal user interface (TUI). This is the default mode.',
}, () => {
  const { waitUntilExit } = render(
    <NotificationProvider>
      <App />
    </NotificationProvider>
  );
  return waitUntilExit();
});

const runCommand = defineCommand({
  name: 'run',
  description: 'Execute build and test targets in pure CLI mode for a specific commit.',
  parameters: [
    '[commit]'
  ],
  flags: {
    build: {
      type: [String],
      description: 'Explicitly specify build targets to run. Overrides affected targets if provided.',
      alias: 'b',
    },
    test: {
      type: [String],
      description: 'Explicitly specify test targets to run. Overrides affected targets if provided.',
      alias: 't',
    },
    coverage: {
      type: Number,
      description: 'Expansion radius percentage (0-100) to find proximity targets and rdeps.',
      alias: 'c',
      default: 0,
    }
  }
}, async ({ parameters, flags }) => {
  const commit = parameters.commit || 'p4base';
  await runCLI(commit, flags);
});

const blazer = Clerc.create()
  .name('blazer')
  .scriptName('blazer')
  .description('Blazer: The ultimate TUI and CLI for remote JJ builds using Blaze. Efficiently build and test only what has changed.')
  .version('0.2.0')
  .use(completionsPlugin())
  .use(helpPlugin())
  .command(uiCommand)
  .command(runCommand);

// Default to UI if no arguments provided
if (process.argv.length === 2) {
  process.argv.push('ui');
}

blazer.parse();
