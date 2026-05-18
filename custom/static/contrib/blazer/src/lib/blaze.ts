export interface BlazeOutputHandlers {
  onStdout?: (data: string) => void;
  onStderr?: (data: string) => void;
  onClose?: (code: number | null) => void;
  onSpongeLink?: (link: string) => void;
}

/**
 * Cleans the raw output stream from Blaze by removing ANSI colors,
 * carriage returns, and unsupported control characters.
 */
function cleanStreamChunk(chunk: string): string {
  return chunk
    .replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, '')
    .replace(/\r/g, '\n')
    .replace(/\t/g, '    ')
    .replace(/[\x00-\x09\x0B-\x0C\x0E-\x1F\x7F]/g, '');
}

/**
 * Core execution wrapper for spawning Blaze subprocesses.
 * Uses Bun.spawn for streaming efficiency.
 */
async function blazeCommand(
  command: 'build' | 'test' | 'query',
  args: string[],
  handlers?: BlazeOutputHandlers,
  startupArgs: string[] = []
): Promise<void> {
  if (args.length === 0) {
    handlers?.onClose?.(0);
    return;
  }

  const SPONGE_URL_REGEX = /(https?:\/\/sponge2\S+)/;
  let hasExtractedSpongeLink = false;

  const handleData = (chunk: string, isStdout: boolean) => {
    const cleaned = cleanStreamChunk(chunk);
    if (isStdout) handlers?.onStdout?.(cleaned);
    else handlers?.onStderr?.(cleaned);
    
    if (!hasExtractedSpongeLink && handlers?.onSpongeLink) {
      const match = cleaned.match(SPONGE_URL_REGEX);
      if (match?.[1]) {
        handlers.onSpongeLink(match[1]);
        hasExtractedSpongeLink = true;
      }
    }
  };

  try {
    const proc = Bun.spawn(['blaze', ...startupArgs, command, ...args], {
      stdout: 'pipe',
      stderr: 'pipe',
    });

    const streamReader = async (stream: ReadableStream, isStdout: boolean) => {
      const reader = stream.getReader();
      const decoder = new TextDecoder();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          handleData(decoder.decode(value), isStdout);
        }
      } finally {
        reader.releaseLock();
      }
    };

    await Promise.all([
      streamReader(proc.stdout, true),
      streamReader(proc.stderr, false),
      proc.exited
    ]);

    handlers?.onClose?.(proc.exitCode);
  } catch (err: unknown) {
    handlers?.onClose?.(1);
  }
}

/**
 * Spawns a `blaze build` command.
 */
export function blazeBuild(targets: string[], bepFile?: string, handlers?: BlazeOutputHandlers, extraArgs: string[] = []): void {
  const bepArgs = bepFile ? [`--build_event_json_file=${bepFile}`] : [];
  blazeCommand(
    'build',
    ['--curses=no', '--color=no', '--keep_going', ...bepArgs, ...extraArgs, ...targets],
    handlers,
    ['--output_base=/tmp/blazer-build']
  );
}

/**
 * Spawns a `blaze test` command.
 */
export function blazeTest(targets: string[], bepFile?: string, handlers?: BlazeOutputHandlers, extraArgs: string[] = []): void {
  const bepArgs = bepFile ? [`--build_event_json_file=${bepFile}`] : [];
  blazeCommand(
    'test',
    ['--test_output=errors', '--curses=no', '--color=no', '--keep_going', '--test_keep_going', ...bepArgs, ...extraArgs, ...targets],
    handlers,
    ['--output_base=/tmp/blazer-test']
  );
}

/**
 * Spawns a `blaze query` command and streams output.
 */
export function blazeQuery(query: string, extraArgs: string[] = [], handlers?: BlazeOutputHandlers): void {
  blazeCommand('query', [query, ...extraArgs], handlers);
}

/**
 * Promisified version of `blaze query` to return the complete output as a string.
 */
export function blazeQueryAsync(query: string, extraArgs: string[] = [], onStdout?: (data: string) => void): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: string[] = [];
    blazeCommand('query', [query, ...extraArgs], {
      onStdout: data => {
        chunks.push(data);
        onStdout?.(data);
      },
      onStderr: data => {
        onStdout?.(data); // Pipe progress to logs too
      },
      onClose: code => {
        if (code === 0 || code === 3) resolve(chunks.join(''));
        else reject(new Error(`blaze query failed (code ${code})`));
      }
    });
  });
}
