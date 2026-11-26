package uz.mynine.app.data

import android.content.Context
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import java.io.File

/**
 * The last API answers of the list screens (home, tests, attempts, test, result), kept on disk per user, so a
 * screen shows them at once and refreshes from the network behind them. Cleared on sign-out.
 */
object ApiCache {
    private var dir: File? = null

    fun init(context: Context) {
        dir = File(context.cacheDir, "api").apply { mkdirs() }
    }

    private fun file(key: String): File? {
        val user = Session.user.value?.id ?: return null
        val safe = key.replace(Regex("[^A-Za-z0-9_.-]"), "_")
        return dir?.let { File(it, "${user}_$safe.json") }
    }

    suspend fun <T> read(key: String, serializer: KSerializer<T>): T? = withContext(Dispatchers.IO) {
        runCatching { file(key)?.takeIf { it.exists() }?.readText()?.let { AppJson.decodeFromString(serializer, it) } }.getOrNull()
    }

    suspend fun <T> write(key: String, serializer: KSerializer<T>, value: T) = withContext(Dispatchers.IO) {
        runCatching { file(key)?.writeText(AppJson.encodeToString(serializer, value)) }
    }

    fun clear() {
        dir?.listFiles()?.forEach { it.delete() }
    }
}

/**
 * Stale-while-revalidate: [show] gets the cached copy at once (when there is one), then the fresh answer.
 * Errors reach the caller only when nothing was cached, so a slow or dropped connection keeps the screen filled.
 */
suspend fun <T> cachedCall(key: String, serializer: KSerializer<T>, show: (T) -> Unit, block: suspend StudentApi.() -> T) {
    val cached = ApiCache.read(key, serializer)
    cached?.let(show)
    try {
        val fresh = call(block)
        show(fresh)
        ApiCache.write(key, serializer, fresh)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (cached == null) throw e
    }
}
