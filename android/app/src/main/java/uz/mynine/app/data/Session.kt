package uz.mynine.app.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Signed-in student: the API token and the cached profile (app-private storage). */
object Session {
    private lateinit var prefs: SharedPreferences
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences("session", Context.MODE_PRIVATE)
        ApiClient.token = prefs.getString("token", null)
        _user.value = prefs.getString("user", null)?.let {
            runCatching { AppJson.decodeFromString(User.serializer(), it) }.getOrNull()
        }
        if (ApiClient.token == null) _user.value = null
        ApiClient.onUnauthorized = { clear() }
    }

    val signedIn: Boolean get() = ApiClient.token != null && _user.value != null

    fun signIn(auth: AuthResponse) {
        prefs.edit().putString("token", auth.token).putString("user", AppJson.encodeToString(User.serializer(), auth.user)).apply()
        ApiClient.token = auth.token
        _user.value = auth.user
    }

    fun update(user: User) {
        prefs.edit().putString("user", AppJson.encodeToString(User.serializer(), user)).apply()
        _user.value = user
    }

    fun clear() {
        prefs.edit().clear().apply()
        ApiCache.clear()
        ApiClient.token = null
        _user.value = null
    }
}
