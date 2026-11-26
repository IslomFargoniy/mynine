package uz.mynine.app

import android.app.Application
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import uz.mynine.app.data.AppLanguage
import uz.mynine.app.data.Session
import uz.mynine.app.ui.auth.GoogleWebSignIn
import uz.mynine.app.ui.auth.LoginScreen
import uz.mynine.app.ui.exam.ExamScreen
import uz.mynine.app.ui.main.MainScreen
import uz.mynine.app.ui.result.ResultScreen
import uz.mynine.app.ui.tests.TestDetailScreen
import uz.mynine.app.ui.theme.MynineTheme

class MynineApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AppLanguage.init(this)
        uz.mynine.app.ui.theme.ThemeMode.init(this)
        Session.init(this)
    }
}

/** AppCompatActivity (not ComponentActivity) so the per-app language from Profile applies. */
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        GoogleWebSignIn.deliver(intent?.data, this)
        setContent { MynineTheme { AppNav() } }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        GoogleWebSignIn.deliver(intent.data, this)
    }
}

object Routes {
    const val LOGIN = "login"
    const val MAIN = "main"
    fun test(id: Int, module: String? = null) = "test/$id" + (module?.let { "?module=$it" } ?: "")
    fun exam(attemptId: Int) = "exam/$attemptId"
    fun result(attemptId: Int) = "result/$attemptId"
}

@Composable
fun AppNav() {
    val nav = rememberNavController()
    val user by Session.user.collectAsState()

    // Signed out (logout, deleted account, revoked token): back to the sign-in screen.
    LaunchedEffect(user) {
        if (user == null && nav.currentDestination?.route != Routes.LOGIN) {
            nav.navigate(Routes.LOGIN) { popUpTo(0) { inclusive = true } }
        }
    }

    NavHost(nav, startDestination = if (Session.signedIn) Routes.MAIN else Routes.LOGIN) {
        composable(Routes.LOGIN) {
            LoginScreen(onSignedIn = { nav.navigate(Routes.MAIN) { popUpTo(0) { inclusive = true } } })
        }
        composable(Routes.MAIN) {
            MainScreen(
                openTest = { id, module -> nav.navigate(Routes.test(id, module)) },
                openExam = { nav.navigate(Routes.exam(it)) },
                openResult = { nav.navigate(Routes.result(it)) },
            )
        }
        composable(
            Routes.TEST,
            arguments = listOf(
                navArgument("id") { type = NavType.IntType },
                navArgument("module") { type = NavType.StringType; nullable = true; defaultValue = null },
            ),
        ) { entry ->
            TestDetailScreen(
                testId = entry.arguments?.getInt("id") ?: 0,
                skill = entry.arguments?.getString("module"),
                onBack = { nav.popBackStack() },
                openExam = { nav.navigate(Routes.exam(it)) },
                openResult = { nav.navigate(Routes.result(it)) },
            )
        }
        composable(Routes.EXAM, arguments = listOf(navArgument("id") { type = NavType.IntType })) { entry ->
            val id = entry.arguments?.getInt("id") ?: 0
            // The exam room is the white IELTS UI in both themes, its dialogs included.
            androidx.compose.material3.MaterialTheme(colorScheme = androidx.compose.material3.lightColorScheme(primary = uz.mynine.app.ui.theme.Mn.ExamBlue)) {
                ExamScreen(
                    attemptId = id,
                    onExit = { nav.popBackStack() },
                    onFinished = {
                        nav.navigate(Routes.result(id)) { popUpTo(Routes.MAIN) }
                    },
                )
            }
        }
        composable(Routes.RESULT, arguments = listOf(navArgument("id") { type = NavType.IntType })) { entry ->
            ResultScreen(attemptId = entry.arguments?.getInt("id") ?: 0, onBack = { nav.popBackStack() })
        }
    }
}

private val Routes.TEST get() = "test/{id}?module={module}"
private val Routes.EXAM get() = "exam/{id}"
private val Routes.RESULT get() = "result/{id}"
