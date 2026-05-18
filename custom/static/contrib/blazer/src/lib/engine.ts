import { blazeBuild, blazeTest } from './blaze';
import { BepStreamer, type TargetStatus } from './reconciliation';
import { randomUUID } from 'crypto';

export interface ExecutionOptions {
  onBuildStdout?: (data: string) => void;
  onBuildStderr?: (data: string) => void;
  onBuildSponge?: (link: string) => void;
  onTestStdout?: (data: string) => void;
  onTestStderr?: (data: string) => void;
  onTestSponge?: (link: string) => void;
  onStatusUpdate?: (
    buildMap: Map<string, TargetStatus>, 
    testMap: Map<string, TargetStatus>,
    buildDetailed?: Map<string, DetailedTargetResult>,
    testDetailed?: Map<string, DetailedTargetResult>
  ) => void;
  onComplete?: (buildCode: number | null, testCode: number | null) => void;
  extraArgs?: string[];
}

/**
 * Orchestrates the parallel execution of Blaze build and test phases.
 */
export async function runExecution(
  buildTargets: string[],
  testTargets: string[],
  options: ExecutionOptions
) {
  const buildStatusMap = new Map<string, TargetStatus>();
  const testStatusMap = new Map<string, TargetStatus>();
  const buildDetailedMap = new Map<string, DetailedTargetResult>();
  const testDetailedMap = new Map<string, DetailedTargetResult>();
  let buildCode: number | null = null;
  let testCode: number | null = null;

  const notify = () => options.onStatusUpdate?.(
    new Map(buildStatusMap), 
    new Map(testStatusMap),
    new Map(buildDetailedMap),
    new Map(testDetailedMap)
  );

  const buildBepFile = `/tmp/blazer-build-${randomUUID()}.json`;
  const testBepFile = `/tmp/blazer-test-${randomUUID()}.json`;

  const buildStreamer = new BepStreamer(buildBepFile, (map, detailed) => {
    map.forEach((v, k) => buildStatusMap.set(k, v));
    detailed?.forEach((v, k) => buildDetailedMap.set(k, v));
    notify();
  });
  const testStreamer = new BepStreamer(testBepFile, (map, detailed) => {
    map.forEach((v, k) => testStatusMap.set(k, v));
    detailed?.forEach((v, k) => testDetailedMap.set(k, v));
    notify();
  });

  if (buildTargets.length > 0) buildStreamer.start();
  if (testTargets.length > 0) testStreamer.start();

  const buildPromise = new Promise<void>((resolve) => {
    if (buildTargets.length === 0) {
      resolve();
      return;
    }
    blazeBuild(buildTargets, buildBepFile, {
      onStdout: options.onBuildStdout,
      onStderr: options.onBuildStderr,
      onSpongeLink: options.onBuildSponge,
      onClose: (code) => {
        buildCode = code;
        setTimeout(() => { buildStreamer.stop(); resolve(); }, 500);
      }
    }, options.extraArgs || []);
  });

  const testPromise = new Promise<void>((resolve) => {
    if (testTargets.length === 0) {
      resolve();
      return;
    }
    blazeTest(testTargets, testBepFile, {
      onStdout: options.onTestStdout,
      onStderr: options.onTestStderr,
      onSpongeLink: options.onTestSponge,
      onClose: (code) => {
        testCode = code;
        setTimeout(() => { testStreamer.stop(); resolve(); }, 500);
      }
    }, options.extraArgs || []);
  });

  await Promise.all([buildPromise, testPromise]);
  options.onComplete?.(buildCode, testCode);
  
  return { buildStatusMap, testStatusMap, buildDetailedMap, testDetailedMap, buildCode, testCode };
}
