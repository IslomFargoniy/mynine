package uz.mynine.app.ui.main

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
fun ProfileTab(openHistory: () -> Unit) {
    val user by Session.user.collectAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var editName by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(BottomBarSpace),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        ScreenTitle("Profil", Modifier.padding(top = 20.dp))

        GlassCard(Modifier.fillMaxWidth(), radius = 28.dp, onClick = { editName = true }) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Avatar(user?.name ?: "", 64)
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(user?.name ?: "", fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                    (user?.email ?: user?.username)?.let { Text(maskEmail(it), fontSize = 14.sp, color = Mn.Subtle) }
                    Pill("Mynine talabasi", bg = Mn.AccentSoft, fg = Mn.AccentDark)
                }
            }
        }

        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp))) {
            SettingRow(Icons.Outlined.Badge, "Ismni o'zgartirish", null) { editName = true }
            HorizontalDivider(color = Color(0x120F172A))
            SettingRow(Icons.AutoMirrored.Outlined.Send, "Telegram", if (user?.telegramConnected == true) "Ulangan" else "Ulanmagan", valueColor = if (user?.telegramConnected == true) Mn.Green else Mn.Subtle)
            HorizontalDivider(color = Color(0x120F172A))
            SettingRow(Icons.Outlined.AccessTime, "Urinishlar tarixi", "›", onClick = openHistory)
        }

        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp))) {
            SettingRow(Icons.AutoMirrored.Outlined.Logout, "Chiqish", null) {
                scope.launch {
                    runCatching { call { logout() } }
                    Session.clear()
                }
            }
            HorizontalDivider(color = Color(0x120F172A))
            SettingRow(Icons.Outlined.DeleteOutline, "Hisobni o'chirish", null, tint = Mn.Red) { confirmDelete = true }
        }

        error?.let { Text(it, color = Mn.Red, fontSize = 14.sp) }

        Spacer(Modifier.height(4.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Text("Mynine ${BuildConfig.VERSION_NAME} · ", fontSize = 13.sp, color = Mn.Subtle)
            Text(
                "Maxfiylik siyosati",
                Modifier.clickable { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("${ApiClient.baseUrl}/privacy"))) },
                fontSize = 13.sp, color = Mn.Accent, fontWeight = FontWeight.SemiBold,
            )
        }
    }

    if (editName) {
        var name by remember { mutableStateOf(user?.name ?: "") }
        AlertDialog(
            onDismissRequest = { editName = false },
            title = { Text("Ism") },
            text = { OutlinedTextField(name, { name = it }, singleLine = true, label = { Text("Ism va familiya") }) },
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
                }) { Text("Saqlash") }
            },
            dismissButton = { TextButton(onClick = { editName = false }) { Text("Bekor qilish") } },
        )
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            icon = { Icon(Icons.Outlined.Shield, null, tint = Mn.Red) },
            title = { Text("Hisobni o'chirasizmi?") },
            text = { Text("Hisobingiz va unga bog'langan ma'lumotlar butunlay o'chiriladi. Bu amalni qaytarib bo'lmaydi.", textAlign = TextAlign.Start) },
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
                }) { Text("O'chirish", color = Mn.Red) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Bekor qilish") } },
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

private fun maskEmail(value: String): String {
    val at = value.indexOf('@')
    if (at <= 1) return value
    return value.first() + "•".repeat((at - 1).coerceAtMost(6)) + value.substring(at)
}
