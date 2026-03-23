import { $ } from 'bun';

/** Represents a parsed Commit from jj log */
export interface JjCommit {
  changeId: string;
  commitId: string;
  description: string;
}

/**
 * Fetches the log of commits between the given base and the current working copy (`@`).
 *
 * @param base The base revision to diff against (e.g. 'p4base', 'main').
 * @returns A promise resolving to a chronological array of JjCommit data.
 */
export async function getJjLog(base: string = 'p4base'): Promise<JjCommit[]> {
  const revset = `${base}..@`;
  const template = 'change_id.short() ++ "\\0" ++ commit_id.short() ++ "\\0" ++ description.first_line() ++ "\\n"';
  
  const { stdout } = await $`jj log -r ${revset} --no-graph -T ${template}`.quiet().nothrow();
  
  const cleanOut = stdout.toString('utf-8').trim();
  if (!cleanOut) return [];

  return cleanOut.split('\n').filter(Boolean).map(line => {
    const [changeId = '', commitId = '', desc = ''] = line.split('\0');
    return { changeId, commitId, description: desc.trim() };
  });
}

/**
 * Lists the files that have changed between the given base and the working copy.
 *
 * @param base The base revision to diff against.
 * @returns A promise resolving to an array of relative file paths.
 */
export async function getChangedFiles(base: string = 'p4base'): Promise<string[]> {
  const { stdout } = await $`jj diff --from ${base} --to @ --name-only`.quiet().nothrow();
  return stdout.toString('utf-8').trim().split('\n').filter(Boolean);
}
