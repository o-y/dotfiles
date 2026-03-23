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

export interface BepEvent {
  id?: {
    targetCompleted?: { label: string };
    aborted?: { 
      id?: { targetCompleted?: { label: string } }; 
      label?: string 
    };
  };
  aborted?: { reason: string };
  completed?: { success: boolean };
}

export class BepStreamer {
  private statusMap = new Map<string, TargetStatus>();
  private position = 0;
  private buffer = '';
  private interval: ReturnType<typeof setInterval> | null = null;
  private isProcessing = false;

  constructor(private filePath: string, private onUpdate: (map: Map<string, TargetStatus>) => void) {}

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
           
           // Process complete lines from the buffer
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
                  // Ignore JSON parse errors for incomplete lines
                }
              }
           }
           
           if (hasUpdates) {
             this.onUpdate(new Map(this.statusMap));
           }
         }
       } finally {
         this.isProcessing = false;
       }
    }, 250);
  }

  private processEvent(evt: BepEvent): boolean {
    const label = evt.id?.targetCompleted?.label 
               || evt.id?.aborted?.label 
               || evt.id?.aborted?.id?.targetCompleted?.label;
               
    if (!label) return false;

    if (evt.completed) {
      this.statusMap.set(label, evt.completed.success ? 'SUCCESSFUL' : 'FAILED');
      return true;
    }
    
    if (evt.aborted) {
      if (evt.aborted.reason === 'INCOMPLETE') {
         this.statusMap.set(label, 'BROKEN');
         return true;
      }
      if (evt.aborted.reason === 'SKIPPED') {
         this.statusMap.set(label, 'SKIPPED');
         return true;
      }
    }
    
    return false;
  }

  public stop() {
    if (this.interval) clearInterval(this.interval);
  }
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
