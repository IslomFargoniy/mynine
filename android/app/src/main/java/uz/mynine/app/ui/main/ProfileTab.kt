package uz.mynine.app.ui.main

import uz.mynine.app.R
import uz.mynine.app.data.str
import uz.mynine.app.data.AppLanguage
import uz.mynine.app.ui.theme.ThemeMode
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material3.RadioButton
import androidx.compose.ui.draw.clip

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.Badge
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import uz.mynine.app.BuildConfig
import uz.mynine.app.data.ApiClient
import uz.mynine.app.data.NameBody
import uz.mynine.app.data.Session
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.theme.GlassCard
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.Pill
import uz.mynine.app.ui.theme.ScreenTitle
import uz.mynine.app.ui.theme.glass

@Composable
fun ProfileTab(openHistory: () -> Unit, onBack: () -> Unit) {
    val user by Session.user.collectAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var editName by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var pickLanguage by remember { mutableStateOf(false) }
    var pickTheme by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(BottomBarSpace),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(Modifier.padding(top = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.size(44.dp).glass(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.back), tint = Mn.Ink2)
            }
            ScreenTitle(str(R.string.profile))
        }

        GlassCard(Modifier.fillMaxWidth(), radius = 28.dp, onClick = { editName = true }) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Avatar(user?.name ?: "", 64)
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(user?.name ?: "", fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                    (user?.email ?: user?.username)?.let { Text(maskEmail(it), fontSize = 14.sp, color = Mn.Subtle) }
                    Pill(str(R.string.mynine_student), bg = Mn.AccentSoft, fg = Mn.AccentDark)
                }
            }
        }

        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp))) {
            SettingRow(Icons.Outlined.Badge, str(R.string.change_name), null) { editName = true }
            HorizontalDivider(color = Mn.Divider)
            SettingRow(Icons.AutoMirrored.Outlined.Send, "Telegram", if (user?.telegramConnected == true) str(R.string.connected) else str(R.string.not_connected), valueColor = if (user?.telegramConnected == true) Mn.Green else Mn.Subtle)
            HorizontalDivider(color = Mn.Divider)
            SettingRow(Icons.Outlined.AccessTime, str(R.string.history), "›", onClick = openHistory)
            HorizontalDivider(color = Mn.Divider)
            SettingRow(Icons.Outlined.Language, str(R.string.language), languageName(AppLanguage.selected())) { pickLanguage = true }
            HorizontalDivider(color = Mn.Divider)
            SettingRow(Icons.Outlined.DarkMode, str(R.string.theme), themeName(ThemeMode.current)) { pickTheme = true }
        }

        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp))) {
            SettingRow(Icons.AutoMirrored.Outlined.Logout, str(R.string.exit), null) {
                scope.launch {
                    runCatching { call { logout() } }
                    Session.clear()
                }
            }
            HorizontalDivider(color = Mn.Divider)
            SettingRow(Icons.Outlined.DeleteOutline, str(R.string.delete_account), null, tint = Mn.Red) { confirmDelete = true }
        }

        error?.let { Text(it, color = Mn.Red, fontSize = 14.sp) }

        Spacer(Modifier.height(4.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Text("Mynine ${BuildConfig.VERSION_NAME} · ", fontSize = 13.sp, color = Mn.Subtle)
            Text(
                str(R.string.privacy),
                Modifier.clickable { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("${ApiClient.baseUrl}/privacy"))) },
                fontSize = 13.sp, color = Mn.Accent, fontWeight = FontWeight.SemiBold,
            )
        }
    }

    if (editName) {
        var name by remember { mutableStateOf(user?.name ?: "") }
        AlertDialog(
            onDismissRequest = { editName = false },
            title = { Text(str(R.string.name)) },
            text = { OutlinedTextField(name, { name = it }, singleLine = true, label = { Text(str(R.string.full_name)) }) },
            confirmButton = {
                TextButton(enabled = name.trim().length >= 2, onClick = {
                    scope.launch {
                        try {
                            Session.update(call { updateMe(NameBody(name.trim())) }.user)
                            editName = false
                        } catch (e: Exception) {
                            error = e.userMessage()
                        }
                    }
                }) { Text(str(R.string.save)) }
            },
            dismissButton = { TextButton(onClick = { editName = false }) { Text(str(R.string.cancel)) } },
        )
    }

    if (pickLanguage) {
        val current = AppLanguage.selected()
        AlertDialog(
            onDismissRequest = { pickLanguage = false },
            title = { Text(str(R.string.language)) },
            text = {
                Column {
                    AppLanguage.entries.forEach { lang ->
                        Row(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).clickable {
                                pickLanguage = false
                                if (lang != current) AppLanguage.apply(lang)
                            }.padding(vertical = 12.dp, horizontal = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            RadioButton(selected = lang == current, onClick = null)
                            Text(languageName(lang), fontSize = 16.sp, color = Mn.Ink)
                        }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { pickLanguage = false }) { Text(str(R.string.cancel)) } },
        )
    }

    if (pickTheme) {
        ChoiceDialog(
            title = str(R.string.theme),
            options = ThemeMode.entries.map { it to themeName(it) },
            selected = ThemeMode.current,
            onPick = { ThemeMode.set(context, it); pickTheme = false },
            onDismiss = { pickTheme = false },
        )
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            icon = { Icon(Icons.Outlined.Shield, null, tint = Mn.Red) },
            title = { Text(str(R.string.delete_q)) },
            text = { Text(str(R.string.delete_text), textAlign = TextAlign.Start) },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        try {
                            call { deleteMe() }
                            Session.clear()
                        } catch (e: Exception) {
                            error = e.userMessage()
                        }
                        confirmDelete = false
                    }
                }) { Text(str(R.string.delete), color = Mn.Red) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(str(R.string.cancel)) } },
        )
    }
}

@Composable
private fun SettingRow(
    icon: ImageVector,
    title: String,
    value: String?,
    tint: Color = Mn.Accent,
    valueColor: Color = Mn.Subtle,
    onClick: (() -> Unit)? = null,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 16.dp, vertical = 17.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp))
        Text(title, Modifier.weight(1f), fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = if (tint == Mn.Red) Mn.Red else Mn.Ink)
        value?.let { Text(it, fontSize = 15.sp, color = valueColor, fontWeight = FontWeight.Medium) }
    }
}

private fun themeName(mode: ThemeMode): String = when (mode) {
    ThemeMode.System -> str(R.string.theme_system)
    ThemeMode.Light -> str(R.string.theme_light)
    ThemeMode.Dark -> str(R.string.theme_dark)
}

@Composable
private fun <T> ChoiceDialog(title: String, options: List<Pair<T, String>>, selected: T, onPick: (T) -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                options.forEach { (value, label) ->
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).clickable { onPick(value) }.padding(vertical = 12.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        RadioButton(selected = value == selected, onClick = null)
                        Text(label, fontSize = 16.sp, color = Mn.Ink)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(str(R.string.cancel)) } },
    )
}

/** Each language is named in itself, so it can be found whatever the current language is. */
private fun languageName(lang: AppLanguage): String = when (lang) {
    AppLanguage.System -> str(R.string.lang_system)
    AppLanguage.Uzbek -> "O'zbekcha"
    AppLanguage.Russian -> "Русский"
    AppLanguage.English -> "English"
}

private fun maskEmail(value: String): String {
    val at = value.indexOf('@')
    if (at <= 1) return value
    return value.first() + "•".repeat((at - 1).coerceAtMost(6)) + value.substring(at)
}
