import React, { useMemo } from 'react';
import { useInput, Box, Text } from 'ink';

export interface ControlDefinition {
  /** The internal key/ID of the action */
  id: string;
  /** Format to display in the UI pill (e.g. 'C', 'Spc', 'Ctrl+C', '↑/↓') */
  displayKey: string;
  /** Label describing what the action does */
  label: string;
  /** Callback to invoke when this control is pressed */
  action: () => void;
  /** Ink key matcher. A function taking `(input: string, key: Key)` and returning true if it matches. */
  matcher: (input: string, key: any) => boolean;
  /** If true, this control is active and should be displayed/listened to */
  isActive: boolean;
  /** If false, this control is active (responds to keys) but hidden from the UI display. Defaults to true. */
  isVisuallyDisplayed?: boolean;
}

export function useControls(definitions: ControlDefinition[]) {
  const activeControls = useMemo(() => definitions.filter(d => d.isActive), [definitions]);

  useInput((input, key) => {
    // We execute the first active control that matches the current input/key
    const match = activeControls.find(c => c.matcher(input, key));
    if (match) {
      match.action();
    }
  });

  return activeControls;
}

export function ControlsDisplay({ controls }: { controls: ControlDefinition[] }) {
  if (controls.length === 0) return null;

  return (
    <Box marginTop={0} flexDirection="row" flexWrap="wrap" rowGap={1}>
      {controls.map((c) => {
         if (c.isVisuallyDisplayed === false) return null;
         return (
           <Box key={c.id} marginRight={2} marginBottom={0} flexDirection="row">
              <Text backgroundColor="whiteBright" color="black" bold> {c.displayKey} </Text>
              <Text color="gray"> {c.label}</Text>
           </Box>
         );
      })}
    </Box>
  );
}
