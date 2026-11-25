package uz.mynine.app.data

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.HttpException
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import uz.mynine.app.BuildConfig
import java.io.IOException
import java.util.concurrent.TimeUnit

interface StudentApi {
    @POST("auth/telegram") suspend fun loginTelegram(@Body body: CodeBody): AuthResponse
    @POST("auth/password") suspend fun loginPassword(@Body body: PasswordBody): AuthResponse
    @POST("auth/google") suspend fun loginGoogle(@Body body: GoogleBody): AuthResponse
    @POST("auth/logout") suspend fun logout(): JsonObject
    @GET("app/version") suspend fun version(@Query("platform") platform: String = "android"): VersionInfo

    @GET("me") suspend fun me(): UserResponse
    @PATCH("me") suspend fun updateMe(@Body body: NameBody): UserResponse
    @DELETE("me") suspend fun deleteMe(): JsonObject

    @GET("tests") suspend fun tests(
        @Query("search") search: String? = null,
        @Query("module") module: String? = null,
        @Query("folder_id") folderId: Int? = null,
        @Query("page") page: Int = 1,
    ): TestsResponse

    @GET("tests/{id}") suspend fun test(@Path("id") id: Int): TestResponse

    @GET("attempts") suspend fun attempts(@Query("page") page: Int = 1): AttemptsResponse
    @POST("attempts") suspend fun startAttempt(@Body body: StartAttemptBody): AttemptEnvelope
    @GET("attempts/{id}") suspend fun attempt(@Path("id") id: Int): AttemptEnvelope
    @GET("attempts/{id}/parts/{part}") suspend fun part(@Path("id") id: Int, @Path("part") part: Int): JsonObject
    @POST("attempts/{id}/modules/{type}/start") suspend fun startModule(@Path("id") id: Int, @Path("type") typeId: Int): ModuleTimer
    @POST("attempts/{id}/modules/{type}/submit") suspend fun submitModule(@Path("id") id: Int, @Path("type") typeId: Int): JsonObject
    @POST("attempts/{id}/answers") suspend fun answers(@Path("id") id: Int, @Body body: AnswersBody): AnswersResponse
    @POST("attempts/{id}/submit") suspend fun submitAttempt(@Path("id") id: Int): SummaryEnvelope
    @GET("attempts/{id}/result") suspend fun result(@Path("id") id: Int): ResultResponse
}

/** A failed request, with the API's `code` when it sent one. */
class ApiException(val status: Int, val code: String?, override val message: String) : Exception(message) {
    val offline: Boolean get() = status == 0
}

val AppJson = Json {
    ignoreUnknownKeys = true
    explicitNulls = false
    coerceInputValues = true
    isLenient = true
}

object ApiClient {
    val baseUrl: String = BuildConfig.BASE_URL.trimEnd('/')

    /** Set by [Session]; read on every request. */
    @Volatile var token: String? = null

    /** Called when the server says the token is no longer valid. */
    @Volatile var onUnauthorized: (() -> Unit)? = null

    val http: OkHttpClient by lazy {
        val auth = Interceptor { chain ->
            val builder = chain.request().newBuilder()
                .header("Accept", "application/json")
                .header("X-Platform", "android")
                .header("X-App-Version", BuildConfig.VERSION_NAME)
            token?.let { builder.header("Authorization", "Bearer $it") }
            val response = chain.proceed(builder.build())
            if (response.code == 401 && token != null) onUnauthorized?.invoke()
            response
        }
        OkHttpClient.Builder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(40, TimeUnit.SECONDS)
            .writeTimeout(40, TimeUnit.SECONDS)
            .addInterceptor(auth)
            .apply {
                if (BuildConfig.DEBUG) addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            }
            .build()
    }

    val api: StudentApi by lazy {
        Retrofit.Builder()
            .baseUrl("$baseUrl/api/v1/student/")
            .client(http)
            .addConverterFactory(AppJson.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(StudentApi::class.java)
    }
}

/** Runs an API call and turns transport / HTTP errors into [ApiException]. */
suspend fun <T> call(block: suspend StudentApi.() -> T): T = try {
    ApiClient.api.block()
} catch (e: HttpException) {
    val body = runCatching { e.response()?.errorBody()?.string() }.getOrNull()
    val parsed = body?.let { runCatching { AppJson.decodeFromString(ApiErrorBody.serializer(), it) }.getOrNull() }
    throw ApiException(e.code(), parsed?.code, parsed?.message ?: "Server xatosi (${e.code()})")
} catch (e: IOException) {
    throw ApiException(0, "offline", "Internet aloqasi yo'q. Qayta urinib ko'ring.")
}

fun Throwable.userMessage(): String = when (this) {
    is ApiException -> when (code) {
        "invalid_code" -> "Kod noto'g'ri yoki muddati o'tgan. Botdan yangi kod oling."
        "invalid_credentials" -> "Login yoki parol noto'g'ri."
        "staff_account" -> "Bu xodim akkaunti. Xodimlar mynine.uz saytidan foydalanadi."
        "account_suspended" -> "Akkaunt bloklangan."
        "too_many_requests" -> "Juda ko'p urinish. Bir daqiqadan keyin qayta urinib ko'ring."
        "module_locked" -> "Avval oldingi modulni yakunlang."
        else -> message
    }
    else -> message ?: "Kutilmagan xatolik"
}
