package uz.mynine.app.ui.exam

import android.app.Application
import androidx.annotation.OptIn
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import uz.mynine.app.data.AnswerQueue
import uz.mynine.app.data.ApiClient
import uz.mynine.app.data.ApiException
import uz.mynine.app.data.AppJson
import uz.mynine.app.data.AttemptState
import uz.mynine.app.data.ExamModule
import uz.mynine.app.data.LoadedPart
import uz.mynine.app.data.PartPayload
import uz.mynine.app.data.QuestionPayload
import uz.mynine.app.data.SavedAnswer
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import java.time.OffsetDateTime

enum class Phase { Loading, Intro, Running, Submitting, Done, Error }

/** A question in the number bar (all parts of the module, in order). */
data class NavQuestion(val partIndex: Int, val question: QuestionPayload) {
    val label: String get() = if (question.numberCount > 1) "${question.number}–${question.number + question.numberCount - 1}" else "${question.number}"
}

data class ExamUi(
    val phase: Phase = Phase.Loading,
    val attempt: AttemptState? = null,
    val module: ExamModule? = null,
    val moduleIndex: Int = 0,
    val parts: List<LoadedPart> = emptyList(),
    val partIndex: Int = 0,
    val remainingMs: Long = 0,
    val answers: Map<Int, SavedAnswer> = emptyMap(),
    val flagged: Set<Int> = emptySet(),
    val error: String? = null,
    val offline: Boolean = false,
    val pending: Int = 0,
    val autoSubmitted: Boolean = false,
    val volume: Float = 1f,
    val audioPlaying: Boolean = false,
) {
    val part: LoadedPart? get() = parts.getOrNull(partIndex)
    val navQuestions: List<NavQuestion>
        get() = parts.flatMapIndexed { i, p -> p.payload.sections.flatMap { s -> s.questions.map { NavQuestion(i, it) } } }

    fun answered(questionId: Int): Boolean = answers[questionId]?.let { !it.text.isNullOrBlank() || it.optionIds.isNotEmpty() } ?: false
}

class ExamViewModel(app: Application, private val attemptId: Int) : AndroidViewModel(app) {
    private val _ui = MutableStateFlow(ExamUi())
    val ui: StateFlow<ExamUi> = _ui.asStateFlow()

    private val queue = AnswerQueue(app, attemptId, viewModelScope)

    /** Highlights and notes per part (exam room page format), kept on the device like the desktop app. */
    private val marksPrefs = app.getSharedPreferences("marks-$attemptId", android.content.Context.MODE_PRIVATE)

    fun saveMarks(partId: Int, json: String) {
        marksPrefs.edit().putString(partId.toString(), json).apply()
    }
    private var serverOffsetMs = 0L
    private var finishedAtMs = 0L
    private var ticker: Job? = null
    private var player: ExoPlayer? = null

    init {
        viewModelScope.launch {
            queue.offline.collect { off -> _ui.update { it.copy(offline = off) } }
        }
        viewModelScope.launch {
            queue.pendingCount.collect { n -> _ui.update { it.copy(pending = n) } }
        }
        load()
    }

    fun load() {
        _ui.update { it.copy(phase = Phase.Loading, error = null) }
        viewModelScope.launch {
            try {
                val attempt = call { attempt(attemptId) }.attempt
                syncClock(attempt.serverTime)
                queue.flush()
                route(attempt)
            } catch (e: Exception) {
                _ui.update { it.copy(phase = Phase.Error, error = e.userMessage()) }
            }
        }
    }

    /** First module that is not submitted: running → enter, not started → intro, none → finish the attempt. */
    private suspend fun route(attempt: AttemptState) {
        if (attempt.status == "completed") {
            queue.clear()
            _ui.update { it.copy(phase = Phase.Done, attempt = attempt) }
            return
        }
        val index = attempt.modules.indexOfFirst { it.status != "submitted" }
        if (index < 0) {
            finishAttempt()
            return
        }
        val module = attempt.modules[index]
        _ui.update { it.copy(attempt = attempt, module = module, moduleIndex = index, parts = emptyList(), partIndex = 0, autoSubmitted = false) }
        if (module.status == "in_progress" && module.finishedAt != null) {
            enterModule(module, module.startedAt, module.finishedAt, fresh = false, knownLagSeconds = module.audioLagSeconds)
        } else {
            _ui.update { it.copy(phase = Phase.Intro) }
        }
    }

    fun startModule() {
        val module = _ui.value.module ?: return
        _ui.update { it.copy(phase = Phase.Loading, error = null) }
        viewModelScope.launch {
            try {
                val timer = call { startModule(attemptId, module.typeId) }
                syncClock(timer.serverTime)
                enterModule(module, timer.startedAt, timer.finishedAt ?: return@launch, fresh = true, knownLagSeconds = timer.audioLagSeconds)
            } catch (e: Exception) {
                _ui.update { it.copy(phase = Phase.Intro, error = e.userMessage()) }
            }
        }
    }

    private suspend fun enterModule(module: ExamModule, startedAt: String?, finishedAt: String, fresh: Boolean, knownLagSeconds: Int) {
        finishedAtMs = parseMs(finishedAt)
        val parts = module.parts.sortedBy { it.order }.map { ref ->
            val raw = call { part(attemptId, ref.id) }
            LoadedPart(AppJson.decodeFromJsonElement(PartPayload.serializer(), raw), raw)
        }
        val answers = HashMap<Int, SavedAnswer>()
        parts.forEach { p -> p.payload.sections.forEach { s -> s.questions.forEach { q -> answers[q.id] = q.answer } } }
        // Answers not confirmed by the server yet win over the server's copy.
        queue.pendingAnswers().values.forEach { item ->
            val old = answers[item.questionId] ?: SavedAnswer()
            answers[item.questionId] = SavedAnswer(item.text ?: old.text.takeIf { item.optionIds != null }, item.optionIds ?: old.optionIds)
        }
        _ui.update { it.copy(phase = Phase.Running, module = module, parts = parts, partIndex = 0, answers = answers, remainingMs = remaining()) }
        queue.start()
        startTicker()
        if (module.type == "listening") startAudio(module, parts, startedAt, fresh, knownLagSeconds)
    }

    private fun startTicker() {
        ticker?.cancel()
        ticker = viewModelScope.launch {
            while (isActive) {
                val left = remaining()
                _ui.update { it.copy(remainingMs = left) }
                if (left <= 0 && _ui.value.phase == Phase.Running) {
                    submitModule(auto = true)
                    break
                }
                delay(500)
            }
        }
    }

    fun selectPart(index: Int) {
        if (index in _ui.value.parts.indices) _ui.update { it.copy(partIndex = index) }
    }

    fun onAnswer(partId: Int, questionId: Int, text: String?, optionIds: List<Int>?, hasText: Boolean, hasOptions: Boolean) {
        if (_ui.value.phase != Phase.Running) return
        _ui.update { s ->
            val old = s.answers[questionId] ?: SavedAnswer()
            val next = SavedAnswer(if (hasText) text else old.text, if (hasOptions) optionIds.orEmpty() else old.optionIds)
            s.copy(answers = s.answers + (questionId to next))
        }
        queue.put(partId, questionId, if (hasText) text else null, if (hasOptions) optionIds.orEmpty() else null)
    }

    fun toggleFlag(questionId: Int) {
        _ui.update { s -> s.copy(flagged = if (questionId in s.flagged) s.flagged - questionId else s.flagged + questionId) }
    }

    fun setVolume(value: Float) {
        player?.volume = value
        _ui.update { it.copy(volume = value) }
    }

    /** Finish the running module (button or time over), then go to the next one or finish the attempt. */
    fun submitModule(auto: Boolean = false) {
        val module = _ui.value.module ?: return
        if (_ui.value.phase == Phase.Submitting) return
        _ui.update { it.copy(phase = Phase.Submitting, autoSubmitted = auto) }
        viewModelScope.launch {
            delay(700) // the page's debounced text answers arrive first
            repeat(4) { if (!queue.flush()) delay(1500) }
            stopAudio()
            ticker?.cancel()
            try {
                call { submitModule(attemptId, module.typeId) }
            } catch (e: ApiException) {
                if (e.offline) {
                    _ui.update { it.copy(phase = Phase.Running, error = "Internet yo'q: modul yakunlanmadi. Aloqa tiklangach yana bosing.") }
                    startTicker()
                    return@launch
                }
                // attempt_finished / module already closed by the server: just move on.
            }
            try {
                val attempt = call { attempt(attemptId) }.attempt
                syncClock(attempt.serverTime)
                route(attempt)
            } catch (e: Exception) {
                _ui.update { it.copy(phase = Phase.Error, error = e.userMessage()) }
            }
        }
    }

    private suspend fun finishAttempt() {
        _ui.update { it.copy(phase = Phase.Submitting) }
        repeat(3) { if (!queue.flush()) delay(1500) }
        try {
            call { submitAttempt(attemptId) }
            queue.clear()
            _ui.update { it.copy(phase = Phase.Done) }
        } catch (e: Exception) {
            _ui.update { it.copy(phase = Phase.Error, error = e.userMessage()) }
        }
    }

    fun dismissError() = _ui.update { it.copy(error = null) }

    /** Render config for the exam room page (mobile/shared/exam-room/exam-room.js). */
    fun renderConfig(view: String, layout: String): String? {
        val s = _ui.value
        val part = s.part ?: return null
        val ids = part.payload.sections.flatMap { sec -> sec.questions.map { it.id } }
        val config = buildJsonObject {
            put("part", part.raw)
            put("answers", buildJsonObject {
                ids.forEach { id ->
                    val a = s.answers[id] ?: return@forEach
                    put(id.toString(), buildJsonObject {
                        put("text", a.text?.let { JsonPrimitive(it) } ?: JsonNull)
                        put("option_ids", JsonArray(a.optionIds.map { JsonPrimitive(it) }))
                    })
                }
            })
            put("flagged", buildJsonArray { s.flagged.forEach { add(JsonPrimitive(it)) } })
            put("locked", s.phase != Phase.Running)
            put("view", view)
            put("layout", layout)
            put("baseUrl", ApiClient.baseUrl)
            marksPrefs.getString(part.payload.id.toString(), null)
                ?.let { runCatching { AppJson.parseToJsonElement(it) }.getOrNull() }
                ?.let { put("marks", it) }
        }
        return config.toString()
    }

    // ------------------------------------------------------------ audio (Listening plays once, never paused)

    @OptIn(UnstableApi::class)
    private fun startAudio(module: ExamModule, parts: List<LoadedPart>, startedAt: String?, fresh: Boolean, knownLagSeconds: Int) {
        stopAudio()
        val urls = module.audio?.let { listOf(it.url) }
            ?: parts.filter { p -> p.raw["audio_key"].let { it != null && it !is JsonNull } }
                .map { "${ApiClient.baseUrl}/api/v1/student/attempts/$attemptId/audio/part/${it.payload.id}" }
        if (urls.isEmpty()) return

        val factory = DefaultMediaSourceFactory(OkHttpDataSource.Factory(ApiClient.http))
        val exo = ExoPlayer.Builder(getApplication()).setMediaSourceFactory(factory).build()
        exo.setMediaItems(urls.map { MediaItem.fromUri(it) })
        exo.volume = _ui.value.volume
        val startedAtMs = startedAt?.let { parseMs(it) } ?: now()
        var reported = false
        exo.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                _ui.update { it.copy(audioPlaying = isPlaying) }
                // The recording started later than the module clock (parts loading, buffering, app closed):
                // the module ends that much later, like the desktop app (total lag, the server never shortens).
                if (isPlaying && !reported && urls.size == 1) {
                    reported = true
                    val lagSeconds = ((now() - startedAtMs - exo.currentPosition) / 1000).toInt()
                    if (lagSeconds > knownLagSeconds) reportAudioLag(module.typeId, lagSeconds)
                }
            }
        })
        // A new module always plays from 0:00. A resumed one continues where the recording is now: the time since
        // the start minus the lag already added to the clock.
        if (!fresh && urls.size == 1) {
            val position = now() - startedAtMs - knownLagSeconds * 1000L
            if (position > 1500) exo.seekTo(position)
        }
        exo.prepare()
        exo.playWhenReady = true
        player = exo
    }

    private fun reportAudioLag(typeId: Int, lagSeconds: Int) {
        viewModelScope.launch {
            runCatching { call { audioLag(attemptId, typeId, uz.mynine.app.data.LagBody(lagSeconds)) } }.getOrNull()?.let { timer ->
                syncClock(timer.serverTime)
                timer.finishedAt?.let { finishedAtMs = parseMs(it) }
            }
        }
    }

    private fun stopAudio() {
        player?.release()
        player = null
        _ui.update { it.copy(audioPlaying = false) }
    }

    // ------------------------------------------------------------ clock

    private fun syncClock(serverTime: String?) {
        if (serverTime != null) serverOffsetMs = parseMs(serverTime) - System.currentTimeMillis()
    }

    private fun now(): Long = System.currentTimeMillis() + serverOffsetMs

    private fun remaining(): Long = (finishedAtMs - now()).coerceAtLeast(0)

    private fun parseMs(iso: String): Long = runCatching { OffsetDateTime.parse(iso).toInstant().toEpochMilli() }.getOrDefault(0L)

    /** App back in the foreground: re-sync the clock and the attempt (the module may have ended meanwhile). */
    fun onResume() {
        val phase = _ui.value.phase
        if (phase != Phase.Running) return
        viewModelScope.launch {
            runCatching { call { attempt(attemptId) }.attempt }.getOrNull()?.let { attempt ->
                syncClock(attempt.serverTime)
                val module = attempt.modules.getOrNull(_ui.value.moduleIndex)
                if (module?.status == "submitted" || attempt.status == "completed") {
                    stopAudio()
                    ticker?.cancel()
                    route(attempt)
                } else module?.finishedAt?.let { finishedAtMs = parseMs(it) }
            }
        }
    }

    override fun onCleared() {
        stopAudio()
        queue.stop()
        super.onCleared()
    }
}
