/**
 * Mynine Offline Audio Cache Engine (IndexedDB + Blob URLs)
 * Guarantees zero buffering & 100% offline playback during IELTS Listening tests.
 */

const DB_NAME = 'mynine_offline_audio';
const DB_VERSION = 1;
const STORE_NAME = 'audio_blobs';

interface CachedAudio {
    url: string;
    blob: Blob;
    timestamp: number;
    size: number;
}

let dbPromise: Promise<IDBDatabase> | null = null;

function openDB(): Promise<IDBDatabase> {
    if (dbPromise) return dbPromise;

    dbPromise = new Promise((resolve, reject) => {
        if (typeof window === 'undefined' || !window.indexedDB) {
            reject(new Error('IndexedDB is not supported'));
            return;
        }

        const request = window.indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = (e: any) => {
            const db = e.target.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, { keyPath: 'url' });
            }
        };

        request.onsuccess = () => {
            resolve(request.result);
        };

        request.onerror = () => {
            reject(request.error);
        };
    });

    return dbPromise;
}

/**
 * Fetch an audio file from IndexedDB cache
 */
export async function getCachedAudio(url: string): Promise<Blob | null> {
    try {
        const db = await openDB();
        return new Promise((resolve) => {
            const tx = db.transaction(STORE_NAME, 'readonly');
            const store = tx.objectStore(STORE_NAME);
            const request = store.get(url);

            request.onsuccess = () => {
                const result = request.result as CachedAudio | undefined;
                if (result && result.blob) {
                    resolve(result.blob);
                } else {
                    resolve(null);
                }
            };

            request.onerror = () => {
                resolve(null);
            };
        });
    } catch {
        return null;
    }
}

/**
 * Save an audio blob to IndexedDB cache
 */
export async function saveAudioToCache(url: string, blob: Blob): Promise<void> {
    try {
        const db = await openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORE_NAME, 'readwrite');
            const store = tx.objectStore(STORE_NAME);
            const record: CachedAudio = {
                url,
                blob,
                timestamp: Date.now(),
                size: blob.size,
            };

            const request = store.put(record);
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    } catch (e) {
        console.warn('Failed to save audio to offline cache:', e);
    }
}

// Active blob URLs to revoke on cleanup
const activeBlobUrls = new Map<string, string>();

/**
 * Preload and cache an audio file, with real-time download progress
 * Returns a fast local blob: URL
 */
export async function preloadAudio(
    url: string,
    onProgress?: (percent: number) => void
): Promise<string> {
    if (!url) return url;

    // Check in-memory blob URL first
    if (activeBlobUrls.has(url)) {
        onProgress?.(100);
        return activeBlobUrls.get(url)!;
    }

    try {
        // 1. Check if already stored in IndexedDB
        const cachedBlob = await getCachedAudio(url);
        if (cachedBlob && cachedBlob.size > 1000) {
            const blobUrl = URL.createObjectURL(cachedBlob);
            activeBlobUrls.set(url, blobUrl);
            onProgress?.(100);
            return blobUrl;
        }

        // 2. Download with progress tracking
        // no-cache: never trust an HTTP-cached copy (a failed response once got cached for a day).
        const response = await fetch(url, { cache: 'no-cache' });
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

        const contentLength = response.headers.get('content-length');
        const totalBytes = contentLength ? parseInt(contentLength, 10) : 0;

        let blob: Blob;

        if (totalBytes > 0 && response.body && ReadableStream) {
            const reader = response.body.getReader();
            let receivedBytes = 0;
            const chunks: Uint8Array[] = [];

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                if (value) {
                    chunks.push(value);
                    receivedBytes += value.length;
                    const percent = Math.min(100, Math.round((receivedBytes / totalBytes) * 100));
                    onProgress?.(percent);
                }
            }

            blob = new Blob(chunks, { type: 'audio/mpeg' });
        } else {
            blob = await response.blob();
            onProgress?.(100);
        }

        // 3. Save to IndexedDB
        await saveAudioToCache(url, blob);

        // 4. Create Object URL
        const blobUrl = URL.createObjectURL(blob);
        activeBlobUrls.set(url, blobUrl);
        return blobUrl;
    } catch (err) {
        console.warn('Audio preloading failed, falling back to network stream:', err);
        onProgress?.(100);
        return networkUrl(url); // Graceful network fallback
    }
}

/**
 * URL for streaming straight from the network. The version parameter skips a broken response that browsers
 * cached on 11.11.2026 (an nginx misconfiguration answered 500 with a one-day Cache-Control).
 */
function networkUrl(url: string): string {
    if (!url || url.startsWith('blob:') || !url.includes('/media/audio/')) return url;
    return `${url}${url.includes('?') ? '&' : '?'}v=2`;
}

/**
 * Get offline-ready Audio URL (from cache if exists, otherwise fallback to network)
 */
export async function getOfflineAudioUrl(url: string): Promise<string> {
    if (!url) return '';
    if (activeBlobUrls.has(url)) return activeBlobUrls.get(url)!;

    try {
        const cached = await getCachedAudio(url);
        if (cached) {
            const blobUrl = URL.createObjectURL(cached);
            activeBlobUrls.set(url, blobUrl);
            return blobUrl;
        }
    } catch (e) {
        console.warn('Error reading audio cache:', e);
    }

    return networkUrl(url);
}
