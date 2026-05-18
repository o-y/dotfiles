import { existsSync } from 'fs';

export type TargetStatus = 'SUCCESSFUL' | 'FAILED' | 'BROKEN' | 'SKIPPED' | 'PENDING' | 'UNKNOWN';

export interface SummaryNode {
  name: string;
  fullPath: string;
  isTarget: boolean;
  children: Map<string, SummaryNode>;
  status: TargetStatus;
  maxSeverity: number;
  isExpanded: boolean;
  totalTargets: number;
  passedTargets: number;
  pendingTargets: number;
}

/**
 * Returns a severity score for a target status, used for sorting and coloring.
 * 4 = Worst (FAILED)
 * 3 = Broken (BROKEN)
 * 2 = Skipped (SKIPPED) / Pending / Unknown
 * 1 = Best (SUCCESSFUL)
 */
export function getSeverity(status: TargetStatus): number {
  if (status === 'FAILED') return 4;
  if (status === 'BROKEN') return 3;
  if (status === 'SKIPPED' || status === 'PENDING') return 2;
  if (status === 'SUCCESSFUL') return 1;
  return 0; // UNKNOWN
}

export interface TestCase {
  name: string;
  status: 'PASSED' | 'FAILED' | 'ERROR' | 'SKIPPED' | 'FLAKY' | 'TIMEOUT';
  durationMillis?: number;
}

export interface DetailedTargetResult {
  label: string;
  status: TargetStatus;
  testCases: TestCase[];
  outputFiles: string[];
  testSummary?: {
    totalRunCount: number;
    passedCount: number;
    failedCount: number;
    flakyCount?: number;
  };
}

export interface BepEvent {
  id?: {
    targetCompleted?: { label: string };
    testResult?: { label: string };
    testSummary?: { label: string };
    aborted?: { 
      id?: { targetCompleted?: { label: string } }; 
      label?: string 
    };
  };
  aborted?: { reason: string };
  completed?: { success: boolean };
  testResult?: {
    status: string;
    testActionOutput?: Array<{ uri: string }>;
  };
  testSummary?: {
    overallStatus: string;
    totalRunCount: number;
    passedCount: number;
    failedCount: number;
  };
}

export class BepStreamer {
  private statusMap = new Map<string, TargetStatus>();
  private detailedResults = new Map<string, DetailedTargetResult>();
  private position = 0;
  private buffer = '';
  private interval: ReturnType<typeof setInterval> | null = null;
  private isProcessing = false;

  constructor(
    private filePath: string, 
    private onUpdate: (map: Map<string, TargetStatus>, detailed?: Map<string, DetailedTargetResult>) => void
  ) {}

  public start() {
    this.interval = setInterval(async () => {
       if (this.isProcessing || !existsSync(this.filePath)) return;
       this.isProcessing = true;
       
       try {
         const file = Bun.file(this.filePath);
         const size = file.size;
         
         if (size > this.position) {
           const chunk = file.slice(this.position, size);
           const text = await chunk.text();
           this.position = size;
           this.buffer += text;
           
           let hasUpdates = false;
           let nlIndex;
           
           while ((nlIndex = this.buffer.indexOf('\n')) !== -1) {
              const line = this.buffer.slice(0, nlIndex).trim();
              this.buffer = this.buffer.slice(nlIndex + 1);
              
              if (line) {
                try {
                  const evt = JSON.parse(line) as BepEvent;
                  if (this.processEvent(evt)) {
                    hasUpdates = true;
                  }
                } catch (e) {
                }
              }
           }
           
           if (hasUpdates) {
             this.onUpdate(new Map(this.statusMap), new Map(this.detailedResults));
           }
         }
       } finally {
         this.isProcessing = false;
       }
    }, 250);
  }

  private processEvent(evt: BepEvent): boolean {
    const label = evt.id?.targetCompleted?.label 
               || evt.id?.testResult?.label
               || evt.id?.testSummary?.label
               || evt.id?.aborted?.label 
               || evt.id?.aborted?.id?.targetCompleted?.label;
               
    if (!label) return false;

    if (evt.completed) {
      const status = evt.completed.success ? 'SUCCESSFUL' : 'FAILED';
      this.statusMap.set(label, status);
      this.updateDetailed(label, { status });
      return true;
    }

    if (evt.testResult) {
      const outputs = evt.testResult.testActionOutput?.map(o => o.uri).filter(Boolean) || [];
      this.updateDetailed(label, { outputFiles: outputs });
      return true;
    }

    if (evt.testSummary) {
      this.updateDetailed(label, {
        testSummary: {
          totalRunCount: evt.testSummary.totalRunCount,
          passedCount: evt.testSummary.passedCount,
          failedCount: evt.testSummary.failedCount,
        }
      });
      return true;
    }
    
    if (evt.aborted) {
      let status: TargetStatus = 'UNKNOWN';
      if (evt.aborted.reason === 'INCOMPLETE') status = 'BROKEN';
      if (evt.aborted.reason === 'SKIPPED') status = 'SKIPPED';
      
      if (status !== 'UNKNOWN') {
        this.statusMap.set(label, status);
        this.updateDetailed(label, { status });
        return true;
      }
    }
    
    return false;
  }

  private updateDetailed(label: string, update: Partial<DetailedTargetResult>) {
    const existing = this.detailedResults.get(label) || {
      label,
      status: 'PENDING',
      testCases: [],
      outputFiles: []
    };
    this.detailedResults.set(label, { ...existing, ...update });
  }

  public stop() {
    if (this.interval) clearInterval(this.interval);
  }
}

/**
 * Extracts the Sponge ID from a full Sponge URL.
 */
export function getSpongeId(link?: string | null): string | null {
  if (!link) return null;
  const match = link.match(/sponge2\/([a-f0-9-]+)/);
  return match ? match[1] ?? null : null;
}

/**
 * Reconciles the final status of a target by combining both build and test Maps.
 */
export function getTargetStatus(
  target: string,
  buildTargets: string[],
  testTargets: string[],
  buildMap: Map<string, TargetStatus>,
  testMap: Map<string, TargetStatus>,
  done: boolean
): TargetStatus {
  const isB = buildTargets.includes(target);
  const isT = testTargets.includes(target);
  
  const rawBStatus = buildMap.get(target) || 'PENDING';
  const bStatus = rawBStatus === 'FAILED' ? 'BROKEN' : rawBStatus;

  const tStatus = testMap.get(target) || 'PENDING';

  // For targets that are both built and tested
  if (isB && isT) {
     if (bStatus === 'BROKEN') return 'BROKEN';
     if (bStatus === 'PENDING' && !done) return 'PENDING';
     if (tStatus === 'PENDING' && !done) return 'PENDING';
     
     if (tStatus === 'BROKEN' || tStatus === 'FAILED' || tStatus === 'SKIPPED') return tStatus;
     if (bStatus === 'SUCCESSFUL' && (tStatus === 'SUCCESSFUL' || done)) return 'SUCCESSFUL';
  }
  
  if (isB) {
     if (bStatus === 'PENDING' && done) return 'UNKNOWN';
     return bStatus;
  }
  
  if (isT) {
     if (tStatus === 'PENDING' && done) return 'UNKNOWN';
     return tStatus;
  }
  
  return 'UNKNOWN';
}
