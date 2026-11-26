package uz.mynine.app.data

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import android.os.Build
import androidx.annotation.StringRes
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.ConfigurationCompat
import androidx.core.os.LocaleListCompat
import java.util.Locale

/**
 * The app language (same as the MultiTest app): follows the phone (Uzbek unless the phone prefers Russian or
 * English) or a per-app choice made in Profile, stored by AppCompat's per-app language API (Android 13+ keeps
 * it in the system "App languages" setting; below 13 AppCompat stores it, autoStoreLocales).
 */
enum class AppLanguage(val tag: String) {
    System(""), Uzbek("uz"), Russian("ru"), English("en");

    companion object {
        val supportedCodes = listOf("uz", "ru", "en")

        lateinit var app: Context
            private set

        fun init(context: Context) {
            app = context.applicationContext
        }

        /** The explicit per-app choice, or [System]. */
        fun selected(): AppLanguage {
            val code = appLocales().get(0)?.language ?: return System
            return entries.firstOrNull { it.tag == code } ?: System
        }

        /** Applies [language]; activities are recreated with the new locale. */
        fun apply(language: AppLanguage) {
            val locales = if (language == System) LocaleListCompat.getEmptyLocaleList()
            else LocaleListCompat.forLanguageTags(language.tag)
            AppCompatDelegate.setApplicationLocales(locales)
        }

        /** "uz" | "ru" | "en": the language the UI is shown in (also sent as Accept-Language). */
        fun currentCode(): String {
            appLocales().get(0)?.language?.let { if (it in supportedCodes) return it }
            val system = ConfigurationCompat.getLocales(Resources.getSystem().configuration)
            for (i in 0 until system.size()) {
                val code = system.get(i)?.language ?: continue
                if (code in supportedCodes) return code
            }
            return "uz"
        }

        private var cached: Pair<String, Context>? = null

        /** Resources in the current app language; works outside an activity too (view models, API errors). */
        fun localized(): Context {
            val code = currentCode()
            cached?.let { (c, ctx) -> if (c == code) return ctx }
            val config = Configuration(app.resources.configuration).apply { setLocale(Locale.forLanguageTag(code)) }
            return app.createConfigurationContext(config).also { cached = code to it }
        }

        private fun appLocales(): LocaleListCompat =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                app.getSystemService(LocaleManager::class.java)?.applicationLocales
                    ?.let { LocaleListCompat.wrap(it) } ?: LocaleListCompat.getEmptyLocaleList()
            } else {
                AppCompatDelegate.getApplicationLocales()
            }
    }
}

/** A UI string in the current app language. */
fun str(@StringRes id: Int, vararg args: Any): String = AppLanguage.localized().getString(id, *args)
