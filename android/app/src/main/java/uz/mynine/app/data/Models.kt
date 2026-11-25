package uz.mynine.app.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/* Student API (/api/v1/student) — docs/mobile/API.md. Unknown fields are ignored. */

@Serializable
data class User(
    val id: Int,
    val name: String = "",
    val email: String? = null,
    val username: String? = null,
    val avatar: String? = null,
    @SerialName("telegram_connected") val telegramConnected: Boolean = false,
    @SerialName("google_connected") val googleConnected: Boolean = false,
    @SerialName("apple_connected") val appleConnected: Boolean = false,
)

@Serializable
data class AuthResponse(val token: String, val user: User)

@Serializable
data class UserResponse(val user: User)

@Serializable
data class ApiErrorBody(val message: String? = null, val code: String? = null)

@Serializable
data class VersionInfo(
    val latest: String = "1.0.0",
    @SerialName("min_supported") val minSupported: String = "1.0.0",
    @SerialName("store_url") val storeUrl: String? = null,
)

// ------------------------------------------------------------------ tests

@Serializable
data class Folder(val id: Int, val name: String)

@Serializable
data class TestModule(
    @SerialName("type_id") val typeId: Int,
    val type: String,
    val title: String,
    @SerialName("duration_seconds") val durationSeconds: Int = 0,
    @SerialName("parts_count") val partsCount: Int = 0,
    @SerialName("questions_count") val questionsCount: Int = 0,
)

@Serializable
data class TestItem(
    val id: Int,
    val name: String,
    val comment: String? = null,
    val variant: String? = null,
    val folder: Folder? = null,
    val modules: List<TestModule> = emptyList(),
    @SerialName("attempts_count") val attemptsCount: Int = 0,
    @SerialName("in_progress_attempt_id") val inProgressAttemptId: Int? = null,
    @SerialName("last_finished_attempt_id") val lastFinishedAttemptId: Int? = null,
)

@Serializable
data class PageMeta(
    @SerialName("current_page") val currentPage: Int = 1,
    @SerialName("last_page") val lastPage: Int = 1,
    val total: Int = 0,
)

@Serializable
data class TestsResponse(val data: List<TestItem> = emptyList(), val folders: List<Folder> = emptyList(), val meta: PageMeta = PageMeta())

@Serializable
data class TestResponse(val test: TestItem)

// ------------------------------------------------------------------ attempts

@Serializable
data class Ref(val id: Int, val name: String? = null)

@Serializable
data class ModuleAudio(val url: String, @SerialName("duration_seconds") val durationSeconds: Int? = null)

@Serializable
data class PartRef(
    val id: Int,
    val name: String? = null,
    val order: Int = 1,
    @SerialName("question_count") val questionCount: Int = 0,
    @SerialName("first_question_number") val firstQuestionNumber: Int = 1,
)

@Serializable
data class ExamModule(
    @SerialName("type_id") val typeId: Int,
    val type: String,
    val title: String,
    @SerialName("duration_seconds") val durationSeconds: Int = 0,
    val status: String = "not_started",
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("finished_at") val finishedAt: String? = null,
    val audio: ModuleAudio? = null,
    val parts: List<PartRef> = emptyList(),
)

@Serializable
data class AttemptState(
    val id: Int,
    val test: Ref,
    val module: String? = null,
    val status: String,
    val paused: Boolean = false,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("finished_at") val finishedAt: String? = null,
    val modules: List<ExamModule> = emptyList(),
    @SerialName("server_time") val serverTime: String? = null,
)

@Serializable
data class AttemptEnvelope(val attempt: AttemptState, val resumed: Boolean = false)

@Serializable
data class StartAttemptBody(@SerialName("test_id") val testId: Int, val module: String? = null)

@Serializable
data class ModuleTimer(
    @SerialName("type_id") val typeId: Int,
    val status: String,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("finished_at") val finishedAt: String? = null,
    @SerialName("server_time") val serverTime: String? = null,
)

@Serializable
data class Bands(
    val overall: Double? = null,
    val listening: Double? = null,
    val reading: Double? = null,
    val writing: Double? = null,
    @SerialName("writing_pending") val writingPending: Boolean = false,
)

@Serializable
data class AttemptSummary(
    val id: Int,
    val test: Ref,
    val module: String? = null,
    val status: String,
    @SerialName("started_at") val startedAt: String? = null,
    @SerialName("finished_at") val finishedAt: String? = null,
    val modules: List<String> = emptyList(),
    val bands: Bands? = null,
)

@Serializable
data class AttemptsResponse(val data: List<AttemptSummary> = emptyList(), val meta: PageMeta = PageMeta())

@Serializable
data class SummaryEnvelope(val attempt: AttemptSummary)

// ------------------------------------------------------------------ exam part (PartPayload)

@Serializable
data class SavedAnswer(val text: String? = null, @SerialName("option_ids") val optionIds: List<Int> = emptyList())

@Serializable
data class QuestionPayload(
    val id: Int,
    val number: Int,
    @SerialName("number_count") val numberCount: Int = 1,
    val answer: SavedAnswer = SavedAnswer(),
)

@Serializable
data class SectionPayload(
    val id: Int,
    @SerialName("question_type") val questionType: String? = null,
    val questions: List<QuestionPayload> = emptyList(),
)

@Serializable
data class PartPayload(
    val id: Int,
    val type: String,
    @SerialName("type_id") val typeId: Int,
    val name: String? = null,
    val order: Int = 1,
    val html: String = "",
    val sections: List<SectionPayload> = emptyList(),
)

/** The part as the exam room page needs it (raw JSON) plus the fields the app reads. */
data class LoadedPart(val payload: PartPayload, val raw: JsonObject)

// ------------------------------------------------------------------ answers

@Serializable
data class AnswerItem(
    @SerialName("client_uuid") val clientUuid: String,
    @SerialName("part_id") val partId: Int,
    @SerialName("question_id") val questionId: Int,
    val text: String? = null,
    @SerialName("option_ids") val optionIds: List<Int>? = null,
    @SerialName("changed_at") val changedAt: String,
    val seq: Int,
)

@Serializable
data class AnswersBody(val answers: List<AnswerItem>)

@Serializable
data class AnswerResult(@SerialName("client_uuid") val clientUuid: String, val status: String, val reason: String? = null)

@Serializable
data class AnswersResponse(val results: List<AnswerResult> = emptyList(), @SerialName("server_time") val serverTime: String? = null)

// ------------------------------------------------------------------ result

@Serializable
data class FullBands(
    val overall: Double? = null,
    val listening: Double? = null,
    val reading: Double? = null,
    val writing: Double? = null,
    @SerialName("listening_correct") val listeningCorrect: Double? = null,
    @SerialName("reading_correct") val readingCorrect: Double? = null,
    @SerialName("writing_confirmed") val writingConfirmed: Boolean = false,
    @SerialName("writing_pending") val writingPending: Boolean = false,
)

@Serializable
data class ReviewQuestion(
    @SerialName("question_id") val questionId: Int,
    val number: Int,
    @SerialName("number_count") val numberCount: Int = 1,
    @SerialName("your_answer") val yourAnswer: String? = null,
    @SerialName("correct_answer") val correctAnswer: String = "",
    val points: Int = 0,
    @SerialName("max_points") val maxPoints: Int = 1,
    @SerialName("is_correct") val isCorrect: Boolean = false,
)

@Serializable
data class EssayReview(
    @SerialName("question_id") val questionId: Int,
    val task: Int,
    @SerialName("prompt_html") val promptHtml: String = "",
    val answer: String = "",
    val words: Int = 0,
    val band: Double? = null,
    val feedback: String? = null,
)

@Serializable
data class ResultModule(
    val type: String,
    @SerialName("type_id") val typeId: Int,
    val title: String,
    val band: Double? = null,
    val correct: Double? = null,
    val questions: List<ReviewQuestion> = emptyList(),
    val essays: List<EssayReview> = emptyList(),
)

@Serializable
data class ResultResponse(val attempt: AttemptSummary, val bands: FullBands = FullBands(), val modules: List<ResultModule> = emptyList())

// ------------------------------------------------------------------ requests

@Serializable
data class CodeBody(val code: String)

@Serializable
data class PasswordBody(val login: String, val password: String)

@Serializable
data class GoogleBody(@SerialName("id_token") val idToken: String)

@Serializable
data class NameBody(val name: String)
