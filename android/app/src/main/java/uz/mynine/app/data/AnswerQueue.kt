package uz.mynine.app.data

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

/**
 * Answers of one attempt waiting for the server. Every change is stored on the device first (survives a crash,
 * a restart or no internet) and sent in idempotent batches (client_uuid + per-question seq: the server keeps the
 * newest). Same contract as the desktop app's queue.
 */
class AnswerQueue(context: Context, private val attemptId: Int, private val scope: CoroutineScope) {
    private val prefs = context.getSharedPreferences("answers-$attemptId", Context.MODE_PRIVATE)
    private val mutex = Mutex()
    private val pending = LinkedHashMap<Int, AnswerItem>() // questionId -> newest unsent item
    private val seqs = HashMap<Int, Int>()
    private var loop: Job? = null

    private val _pendingCount = MutableStateFlow(0)
    val pendingCount: StateFlow<Int> = _pendingCount

    private val _offline = MutableStateFlow(false)
    val offline: StateFlow<Boolean> = _offline

    init {
        prefs.getString("pending", null)?.let { raw ->
            runCatching { AppJson.decodeFromString(ListSerializer(AnswerItem.serializer()), raw) }.getOrNull()
                ?.forEach { pending[it.questionId] = it }
        }
        prefs.getString("seqs", null)?.let { raw ->
            runCatching { AppJson.decodeFromString(MapSerializer(Int.serializer(), Int.serializer()), raw) }.getOrNull()
                ?.let { seqs.putAll(it) }
        }
        _pendingCount.value = pending.size
    }

    /** Pending (not yet confirmed) answers, so a reopened part shows them over the server's copy. */
    fun pendingAnswers(): Map<Int, AnswerItem> = synchronized(pending) { HashMap(pending) }

    fun put(partId: Int, questionId: Int, text: String?, optionIds: List<Int>?) {
        synchronized(pending) {
            // Monotonic across reinstalls too: tenths of a second since 2026-01-01, never below the last one + 1.
            val clock = ((System.currentTimeMillis() / 100) - 17_672_256_000L).coerceIn(0, Int.MAX_VALUE.toLong()).toInt()
            val seq = maxOf((seqs[questionId] ?: 0) + 1, clock)
            seqs[questionId] = seq
            pending[questionId] = AnswerItem(
                clientUuid = UUID.randomUUID().toString(),
                partId = partId,
                questionId = questionId,
                text = text,
                optionIds = optionIds,
                changedAt = OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME),
                seq = seq,
            )
            persist()
        }
    }

    fun start() {
        if (loop?.isActive == true) return
        loop = scope.launch {
            while (isActive) {
                flush()
                delay(if (_offline.value) 5_000 else 1_500)
            }
        }
    }

    fun stop() {
        loop?.cancel()
        loop = null
    }

    /** Sends everything pending; returns true when nothing is left. */
    suspend fun flush(): Boolean = mutex.withLock {
        val batch = synchronized(pending) { pending.values.toList() }
        if (batch.isEmpty()) return@withLock true
        try {
            val response = call { answers(attemptId, AnswersBody(batch.take(200))) }
            _offline.value = false
            val done = response.results.filter { it.status != "deferred" }.map { it.clientUuid }.toSet()
            synchronized(pending) {
                // Keep an item that changed again while the batch was in flight (its uuid differs).
                pending.entries.removeAll { it.value.clientUuid in done }
                persist()
            }
        } catch (e: ApiException) {
            _offline.value = e.offline
            if (e.code == "attempt_finished") {
                synchronized(pending) { pending.clear(); persist() }
            }
        }
        synchronized(pending) { pending.isEmpty() }
    }

    fun clear() {
        synchronized(pending) {
            pending.clear()
            seqs.clear()
        }
        prefs.edit().clear().apply()
        _pendingCount.value = 0
    }

    private fun persist() {
        prefs.edit()
            .putString("pending", AppJson.encodeToString(ListSerializer(AnswerItem.serializer()), pending.values.toList()))
            .putString("seqs", AppJson.encodeToString(MapSerializer(Int.serializer(), Int.serializer()), seqs))
            .apply()
        _pendingCount.value = pending.size
    }
}
