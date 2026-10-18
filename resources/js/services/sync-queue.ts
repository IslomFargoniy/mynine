/**
 * SyncQueue: Offline-First Answer Synchronization Service
 * Handles queuing, local persistence, retry mechanisms, and network status tracking
 */

export interface QueuedItem {
    id: string;
    attemptId: number;
    partId: number;
    questionId: number;
    answerText?: string | null;
    options?: number[] | null;
    timestamp: number;
    retries: number;
}

export type SyncStatus = 'online' | 'offline' | 'syncing' | 'error';

class SyncQueueService {
    private queue: QueuedItem[] = [];
    private isProcessing: boolean = false;
    private retryTimer: ReturnType<typeof setTimeout> | null = null;
    private static readonly MAX_RETRIES = 8;
    private listeners: Set<(status: { status: SyncStatus; pendingCount: number; isOnline: boolean }) => void> = new Set();
    private storageKey = 'mynine_offline_sync_queue';

    constructor() {
        this.loadQueue();
        if (typeof window !== 'undefined') {
            window.addEventListener('online', () => {
                this.notify();
                this.processQueue();
            });
            window.addEventListener('offline', () => {
                this.notify();
            });
        }
    }

    private loadQueue() {
        if (typeof window === 'undefined') return;
        try {
            const raw = localStorage.getItem(this.storageKey);
            if (raw) {
                this.queue = JSON.parse(raw);
            }
        } catch (e) {
            console.error('[SyncQueue] Failed to load queue:', e);
            this.queue = [];
        }
    }

    private saveQueue() {
        if (typeof window === 'undefined') return;
        try {
            localStorage.setItem(this.storageKey, JSON.stringify(this.queue));
        } catch (e) {
            console.error('[SyncQueue] Failed to save queue:', e);
        }
        this.notify();
    }

    public isOnline(): boolean {
        return typeof navigator !== 'undefined' ? navigator.onLine : true;
    }

    public getPendingCount(attemptId?: number): number {
        if (attemptId) {
            return this.queue.filter(item => item.attemptId === attemptId).length;
        }
        return this.queue.length;
    }

    public subscribe(listener: (status: { status: SyncStatus; pendingCount: number; isOnline: boolean }) => void): () => void {
        this.listeners.add(listener);
        listener(this.getStatus());
        return () => this.listeners.delete(listener);
    }

    public getStatus(): { status: SyncStatus; pendingCount: number; isOnline: boolean } {
        const isOnline = this.isOnline();
        let status: SyncStatus = 'online';
        if (!isOnline) {
            status = 'offline';
        } else if (this.isProcessing) {
            status = 'syncing';
        } else if (this.queue.length > 0) {
            status = 'syncing';
        }

        return {
            status,
            pendingCount: this.queue.length,
            isOnline,
        };
    }

    private notify() {
        const currentStatus = this.getStatus();
        this.listeners.forEach((listener) => listener(currentStatus));
    }

    /**
     * Enqueue a new save request and attempt immediate dispatch
     */
    public async saveAnswer(params: {
        attemptId: number;
        partId: number;
        questionId: number;
        answerText?: string | null;
        options?: number[] | null;
    }): Promise<{ success: boolean; offline?: boolean; error?: string }> {
        const { attemptId, partId, questionId, answerText, options } = params;
        const itemId = `${attemptId}_${partId}_${questionId}`;

        // Deduplicate or replace existing item in queue for same question
        this.queue = this.queue.filter(item => item.id !== itemId);
        const newItem: QueuedItem = {
            id: itemId,
            attemptId,
            partId,
            questionId,
            answerText,
            options,
            timestamp: Date.now(),
            retries: 0,
        };
        this.queue.push(newItem);
        this.saveQueue();

        if (!this.isOnline()) {
            return { success: true, offline: true };
        }

        return this.dispatchItem(newItem);
    }

    private async dispatchItem(item: QueuedItem): Promise<{ success: boolean; offline?: boolean; error?: string }> {
        try {
            const csrfToken = (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '';
            const url = `/attempt-answer?part_id=${item.partId}&attempt_id=${item.attemptId}`;

            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': csrfToken,
                },
                body: JSON.stringify({
                    question_id: item.questionId,
                    ...(item.options ? { options: item.options } : { answer_text: item.answerText }),
                }),
            });

            const data = await response.json();

            if (response.ok && data.success !== false) {
                // Remove from queue
                this.queue = this.queue.filter(q => q.id !== item.id);
                this.saveQueue();
                return { success: true };
            } else if (response.status === 422 || response.status === 403) {
                // The server will never accept this answer (time is up / not allowed): drop it instead of retrying forever
                this.queue = this.queue.filter(q => q.id !== item.id);
                this.saveQueue();
                throw new Error(data?.error || data?.message || 'Answer rejected by server');
            } else {
                throw new Error(data?.error || data?.message || 'Server returned an error');
            }
        } catch (error) {
            item.retries += 1;
            this.saveQueue();
            this.scheduleRetry();
            const message = error instanceof Error ? error.message : String(error);
            return { success: false, error: message };
        }
    }

    /**
     * A failed save while online (flaky network, 419 after a session refresh, ...) used to sit
     * in the queue until the browser fired an `online` event. Retry with backoff instead.
     */
    private scheduleRetry() {
        if (this.retryTimer || typeof window === 'undefined') return;
        const pending = this.queue.filter((q) => q.retries < SyncQueueService.MAX_RETRIES);
        if (pending.length === 0) return;
        const attempt = Math.min(...pending.map((q) => q.retries));
        const delay = Math.min(30000, 1000 * 2 ** attempt);
        this.retryTimer = setTimeout(() => {
            this.retryTimer = null;
            this.processQueue();
        }, delay);
    }

    /**
     * Process all queued items sequentially
     */
    public async processQueue(): Promise<void> {
        if (this.isProcessing || this.queue.length === 0 || !this.isOnline()) return;

        this.isProcessing = true;
        this.notify();

        const itemsToProcess = this.queue.filter((q) => q.retries < SyncQueueService.MAX_RETRIES);
        for (const item of itemsToProcess) {
            if (!this.isOnline()) break;
            await this.dispatchItem(item);
        }

        this.isProcessing = false;
        this.notify();
    }

    /**
     * Flush all pending sync items for an attempt before submission
     */
    public async flushAttempt(attemptId: number): Promise<boolean> {
        if (!this.isOnline()) return false;
        const attemptItems = this.queue.filter(item => item.attemptId === attemptId);
        for (const item of attemptItems) {
            await this.dispatchItem(item);
        }
        return this.getPendingCount(attemptId) === 0;
    }
}

export const syncQueue = new SyncQueueService();
