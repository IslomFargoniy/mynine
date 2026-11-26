package uz.mynine.app.ui.auth

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.launch
import uz.mynine.app.BuildConfig
import uz.mynine.app.R
import uz.mynine.app.data.str
import uz.mynine.app.data.CodeBody
import uz.mynine.app.data.GoogleBody
import uz.mynine.app.data.PasswordBody
import uz.mynine.app.data.Session
import uz.mynine.app.data.TokenBody
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.theme.GlassBackground
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.PrimaryButton
import uz.mynine.app.ui.theme.SecondaryButton
import uz.mynine.app.ui.theme.glass

private const val BOT = "MynineUzBot"

@Composable
fun LoginScreen(onSignedIn: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var code by remember { mutableStateOf("") }
    var login by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val codeFocus = remember { FocusRequester() }

    fun submit(block: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        scope.launch {
            try {
                block()
                onSignedIn()
            } catch (e: Exception) {
                error = e.userMessage()
            } finally {
                busy = false
            }
        }
    }

    // Back from the browser sign-in (mynine://auth).
    val webResult by GoogleWebSignIn.result.collectAsState()
    LaunchedEffect(webResult) {
        when (val r = webResult) {
            is GoogleWebSignIn.Result.Token -> {
                GoogleWebSignIn.consumed()
                submit { Session.signIn(call { googleExchange(TokenBody(r.token)) }) }
            }
            GoogleWebSignIn.Result.Failed -> {
                GoogleWebSignIn.consumed()
                error = str(R.string.google_failed)
            }
            null -> Unit
        }
    }

    GlassBackground(0) {
        Column(
            Modifier
                .fillMaxSize()
                .safeDrawingPadding()
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Image(
                    painterResource(R.drawable.logo_mark),
                    contentDescription = null,
                    modifier = Modifier.size(44.dp).clip(RoundedCornerShape(14.dp)),
                )
                Text("mynine", fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink)
            }

            Column(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(top = 12.dp)) {
                Text(
                    str(R.string.login_title),
                    fontSize = 32.sp, lineHeight = 36.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink, letterSpacing = (-0.8).sp,
                )
                Text(
                    str(R.string.login_subtitle),
                    fontSize = 16.sp, lineHeight = 23.sp, color = Mn.Muted,
                )
            }

            Column(
                Modifier.fillMaxWidth().glass(RoundedCornerShape(28.dp)).padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (BuildConfig.GOOGLE_WEB_CLIENT_ID.isNotBlank()) {
                    SecondaryButton(str(R.string.google_sign_in), Modifier.fillMaxWidth(), painter = painterResource(R.drawable.ic_google), enabled = !busy) {
                        if (!busy) {
                            busy = true
                            error = null
                            scope.launch {
                                // No token from the account sheet (closed, or the sheet failed): sign in through the browser.
                                val token = googleIdToken(context)
                                busy = false
                                if (token == null) GoogleWebSignIn.start(context)
                                else submit { Session.signIn(call { loginGoogle(GoogleBody(token)) }) }
                            }
                        }
                    }
                    Divider(str(R.string.or_telegram))
                }

                Row(
                    Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .clip(RoundedCornerShape(999.dp))
                        .background(Mn.AccentSoft)
                        .clickable { openBot(context); codeFocus.requestFocus() },
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.AutoMirrored.Outlined.Send, null, tint = Mn.AccentDark, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.size(8.dp))
                    Text(str(R.string.get_code, BOT), color = Mn.AccentDark, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                }

                Text(str(R.string.code_6), fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Mn.Muted)
                OtpField(code, onChange = {
                    code = it
                    if (it.length == 6) submit { Session.signIn(call { loginTelegram(CodeBody(it)) }) }
                }, focus = codeFocus)

                PrimaryButton(str(R.string.sign_in), Modifier.fillMaxWidth(), enabled = code.length == 6, loading = busy && !showPassword) {
                    submit { Session.signIn(call { loginTelegram(CodeBody(code)) }) }
                }

                if (!showPassword) {
                    Text(
                        str(R.string.with_password),
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).clickable { showPassword = true }.padding(8.dp),
                        textAlign = TextAlign.Center, color = Mn.Accent, fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                    )
                } else {
                    Divider(str(R.string.login_password))
                    Field(login, { login = it }, str(R.string.email_or_login), KeyboardType.Email)
                    Field(password, { password = it }, str(R.string.password), KeyboardType.Password, secret = true)
                    SecondaryButton(str(R.string.sign_in_password), Modifier.fillMaxWidth(), icon = Icons.Outlined.Lock, enabled = !busy && login.isNotBlank() && password.isNotBlank()) {
                        submit { Session.signIn(call { loginPassword(PasswordBody(login.trim(), password)) }) }
                    }
                }

                error?.let { Text(it, color = Mn.Red, fontSize = 14.sp) }
            }

            Text(
                str(R.string.login_footer),
                Modifier.fillMaxWidth(), textAlign = TextAlign.Center, fontSize = 13.sp, lineHeight = 19.sp, color = Mn.Subtle,
            )
        }
    }
}

@Composable
private fun Divider(label: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        HorizontalDivider(Modifier.weight(1f), color = Mn.Divider)
        Text(label, fontSize = 13.sp, color = Mn.Subtle, fontWeight = FontWeight.Medium)
        HorizontalDivider(Modifier.weight(1f), color = Mn.Divider)
    }
}

@Composable
private fun OtpField(value: String, onChange: (String) -> Unit, focus: FocusRequester) {
    BasicTextField(
        value = value,
        onValueChange = { v -> onChange(v.filter(Char::isDigit).take(6)) },
        modifier = Modifier.fillMaxWidth().focusRequester(focus),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
        singleLine = true,
        decorationBox = {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(6) { i ->
                    val ch = value.getOrNull(i)?.toString() ?: ""
                    val active = i == value.length
                    Box(
                        Modifier
                            .weight(1f)
                            .height(54.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Mn.Surface)
                            .border(1.5.dp, if (ch.isNotEmpty() || active) Mn.Accent else Mn.FieldBorder, RoundedCornerShape(16.dp)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(ch, style = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Mn.Ink))
                    }
                }
            }
        },
    )
}

@Composable
private fun Field(value: String, onChange: (String) -> Unit, label: String, type: KeyboardType, secret: Boolean = false) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        keyboardOptions = KeyboardOptions(keyboardType = type),
        visualTransformation = if (secret) PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Mn.Accent,
            unfocusedBorderColor = Mn.FieldBorder,
            focusedContainerColor = Mn.Surface,
            unfocusedContainerColor = Mn.Surface,
        ),
    )
}

/** Opens the bot with the "app" start parameter: the bot answers with a sign-in code. */
private fun openBot(context: Context) {
    val tg = Intent(Intent.ACTION_VIEW, Uri.parse("tg://resolve?domain=$BOT&start=app"))
    try {
        context.startActivity(tg)
    } catch (e: Exception) {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://t.me/$BOT?start=app")))
    }
}

/** Google's account sheet → ID token (audience: the web client ID the server accepts). */
private suspend fun googleIdToken(context: Context): String? {
    val option = GetSignInWithGoogleOption.Builder(BuildConfig.GOOGLE_WEB_CLIENT_ID).build()
    val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
    return try {
        val credential = CredentialManager.create(context).getCredential(context, request).credential
        if (credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
            GoogleIdTokenCredential.createFrom(credential.data).idToken
        } else null
    } catch (e: GetCredentialCancellationException) {
        null
    } catch (e: GetCredentialException) {
        Log.w("GoogleSignIn", "getCredential failed: ${e.type}", e)
        null
    }
}
