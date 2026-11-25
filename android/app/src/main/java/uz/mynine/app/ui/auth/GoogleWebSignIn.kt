package uz.mynine.app.ui.auth

import android.content.Context
import android.content.Intent
import android.net.Uri
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import uz.mynine.app.BuildConfig
import java.security.SecureRandom

/**
 * Google sign-in through the browser, used when the Credential Manager account sheet fails or is closed
 * (e.g. an OAuth client / Play signing key mismatch): mynine.uz/app/google signs in with the website's
 * Google client and sends the browser back to mynine://auth?token=…&state=…; the token is swapped for an
 * API token (POST auth/google/exchange). The state is our own nonce, kept in prefs in case the process dies.
 */
object GoogleWebSignIn {
    sealed interface Result {
        data class Token(val token: String) : Result
        data object Failed : Result
    }

    private const val PREFS = "google_web"
    private const val KEY_STATE = "state"

    private val _result = MutableStateFlow<Result?>(null)
    val result: StateFlow<Result?> = _result

    private var appContext: Context? = null

    fun start(context: Context) {
        appContext = context.applicationContext
        val bytes = ByteArray(24).also { SecureRandom().nextBytes(it) }
        val state = bytes.joinToString("") { "%02x".format(it) }
        prefs(context).edit().putString(KEY_STATE, state).apply()
        val url = Uri.parse(BuildConfig.BASE_URL.trimEnd('/') + "/app/google").buildUpon().appendQueryParameter("state", state).build()
        context.startActivity(Intent(Intent.ACTION_VIEW, url).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    /** Called with every intent's data; ignores anything that is not our mynine://auth return. */
    fun deliver(uri: Uri?, context: Context? = appContext) {
        if (uri == null || uri.scheme != "mynine" || uri.host != "auth") return
        val ctx = context ?: return
        val expected = prefs(ctx).getString(KEY_STATE, null)
        prefs(ctx).edit().remove(KEY_STATE).apply()

        val token = uri.getQueryParameter("token")
        _result.value = if (expected != null && uri.getQueryParameter("state") == expected && !token.isNullOrBlank()) {
            Result.Token(token)
        } else {
            Result.Failed
        }
    }

    fun consumed() {
        _result.value = null
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
