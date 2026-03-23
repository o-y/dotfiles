/**
 * Copies the given text to the system clipboard using the OSC 52 terminal
 * escape sequence. By writing this directly to stdout, the terminal emulator
 * intercepts it and copies the content to the OS clipboard regardless of whether
 * it's a local or remote (SSH) session.
 *
 * @param text The text to copy to the clipboard.
 */
export function copyToClipboard(text: string): void {
  const base64 = Buffer.from(text).toString('base64');
  // OSC 52 escape sequence format: \x1b]52;[c];[base-64-string]\x07
  process.stdout.write(`\x1b]52;c;${base64}\x07`);
}
