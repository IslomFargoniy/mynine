package uz.mynine.app.ui.exam

import uz.mynine.app.R
import uz.mynine.app.data.str

import android.annotation.SuppressLint
import android.app.Application
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import uz.mynine.app.BuildConfig
import uz.mynine.app.data.AppJson
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.minutes
import uz.mynine.app.ui.theme.moduleTitle

/** Messages from the exam room page (window.AndroidBridge.post). */
class ExamBridge(private val onMessage: (String) -> Unit) {
    private val main = Handler(Looper.getMainLooper())

    @JavascriptInterface
    fun post(message: String) {
        main.post { onMessage(message) }
    }
}

@Composable
fun ExamScreen(attemptId: Int, onExit: () -> Unit, onFinished: () -> Unit) {
    val app = LocalContext.current.applicationContext as Application
    val vm: ExamViewModel = viewModel(key = "exam-$attemptId") { ExamViewModel(app, attemptId) }
    val ui by vm.ui.collectAsState()
    var confirmExit by remember { mutableStateOf(false) }
    var confirmSubmit by remember { mutableStateOf(false) }

    LaunchedEffect(ui.phase) { if (ui.phase == Phase.Done) onFinished() }

    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_RESUME) vm.onResume() }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }

    // The exam room is white in both themes: dark status bar icons while it is open.
    val view = androidx.compose.ui.platform.LocalView.current
    DisposableEffect(view) {
        val window = (view.context as? android.app.Activity)?.window
        val bars = window?.let { androidx.core.view.WindowCompat.getInsetsController(it, view) }
        bars?.isAppearanceLightStatusBars = true
        bars?.isAppearanceLightNavigationBars = true
        onDispose {
            bars?.isAppearanceLightStatusBars = !Mn.dark
            bars?.isAppearanceLightNavigationBars = !Mn.dark
        }
    }

    BackHandler { confirmExit = true }

    Box(
        Modifier
            .fillMaxSize()
            .background(Color.White)
            .windowInsetsPadding(WindowInsets.statusBars)
            .windowInsetsPadding(WindowInsets.navigationBars)
            .imePadding(),
    ) {
        when (ui.phase) {
            Phase.Loading, Phase.Done -> Center { CircularProgressIndicator(color = Mn.ExamBlue) }
            Phase.Error -> Center {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.padding(32.dp)) {
                    Text(ui.error ?: str(R.string.error), textAlign = TextAlign.Center, color = Mn.ExamText)
                    ExamButton(str(R.string.retry), dark = true) { vm.load() }
                    ExamButton(str(R.string.exit)) { onExit() }
                }
            }
            Phase.Intro -> IntroView(ui, onBack = { confirmExit = true }, onStart = vm::startModule)
            Phase.Running, Phase.Submitting -> RoomView(ui, vm, onFinish = { confirmSubmit = true }, onBack = { confirmExit = true })
        }

        if (ui.phase == Phase.Submitting) {
            Box(Modifier.fillMaxSize().background(Color(0x99FFFFFF)), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CircularProgressIndicator(color = Mn.ExamBlue)
                    Text(if (ui.autoSubmitted) str(R.string.time_up_submitting) else str(R.string.submitting), color = Mn.ExamText, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }

    if (confirmExit) {
        AlertDialog(
            onDismissRequest = { confirmExit = false },
            title = { Text(str(R.string.leave_q)) },
            text = { Text(str(R.string.leave_text)) },
            confirmButton = { TextButton(onClick = { confirmExit = false; onExit() }) { Text(str(R.string.exit)) } },
            dismissButton = { TextButton(onClick = { confirmExit = false }) { Text(str(R.string.stay)) } },
        )
    }
    if (confirmSubmit) {
        val total = ui.navQuestions.size
        val done = ui.navQuestions.count { ui.answered(it.question.id) }
        AlertDialog(
            onDismissRequest = { confirmSubmit = false },
            title = { Text(str(R.string.finish_module_q, ui.module?.title ?: str(R.string.module))) },
            text = { Text(str(R.string.answered_of, total, done)) },
            confirmButton = { TextButton(onClick = { confirmSubmit = false; vm.submitModule() }) { Text(str(R.string.finish)) } },
            dismissButton = { TextButton(onClick = { confirmSubmit = false }) { Text(str(R.string.cancel)) } },
        )
    }
    ui.error?.takeIf { ui.phase == Phase.Running || ui.phase == Phase.Intro }?.let { msg ->
        AlertDialog(
            onDismissRequest = vm::dismissError,
            text = { Text(msg) },
            confirmButton = { TextButton(onClick = vm::dismissError) { Text("OK") } },
        )
    }
}

@Composable
private fun Center(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { content() }
}

@Composable
private fun ExamButton(text: String, dark: Boolean = false, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Text(
        text,
        modifier
            .clip(RoundedCornerShape(2.dp))
            .background(if (dark) Mn.ExamText else Mn.ExamPanel)
            .border(1.dp, if (dark) Mn.ExamText else Mn.ExamLine, RoundedCornerShape(2.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 12.dp),
        color = if (dark) Color.White else Mn.ExamText,
        fontWeight = FontWeight.Bold,
        fontSize = 14.sp,
    )
}

@Composable
private fun IeltsBadge() {
    Text(
        "IELTS",
        Modifier.clip(RoundedCornerShape(2.dp)).background(Mn.ExamRed).padding(horizontal = 9.dp, vertical = 5.dp),
        color = Color.White, fontWeight = FontWeight.ExtraBold, fontSize = 13.sp,
    )
}

@Composable
private fun IntroView(ui: ExamUi, onBack: () -> Unit, onStart: () -> Unit) {
    val module = ui.module ?: return
    val total = ui.attempt?.modules?.size ?: 1
    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().height(56.dp).border(0.dp, Color.Transparent).padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.back), Modifier.clickable(onClick = onBack).padding(4.dp), tint = Mn.ExamText)
            IeltsBadge()
            Text(ui.attempt?.test?.name ?: "", fontWeight = FontWeight.Bold, color = Mn.ExamText, maxLines = 1)
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(Mn.ExamLine))
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(24.dp).widthIn(max = 640.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(str(R.string.module_n_of, ui.moduleIndex + 1, total), color = Color(0xFF4B5563), fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Text(module.title, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, color = Mn.ExamText)
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Fact(Icons.Outlined.Timer, minutes(module.durationSeconds))
                Fact(null, str(R.string.parts_questions_short, module.parts.size, module.parts.sumOf { it.questionCount }))
            }
            Column(
                Modifier.fillMaxWidth().background(Mn.ExamPanel).border(1.dp, Color(0xFFE5E7EB)).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text("INSTRUCTIONS TO CANDIDATES", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = Mn.ExamText, letterSpacing = 0.5.sp)
                val lines = when (module.type) {
                    "listening" -> listOf(
                        str(R.string.ins_l1),
                        str(R.string.ins_l2),
                        str(R.string.ins_l3),
                    )
                    "writing" -> listOf(
                        str(R.string.ins_w1),
                        str(R.string.ins_w2),
                        str(R.string.ins_w3),
                    )
                    else -> listOf(
                        str(R.string.ins_r1),
                        str(R.string.ins_r2),
                        str(R.string.ins_r3),
                    )
                }
                lines.forEach { Text("•  $it", fontSize = 15.sp, color = Color(0xFF1F2937), lineHeight = 21.sp) }
            }
            Text(str(R.string.timer_starts), fontSize = 13.sp, color = Color(0xFF4B5563))
        }
        Box(Modifier.fillMaxWidth().padding(20.dp)) {
            Text(
                str(R.string.start),
                Modifier.fillMaxWidth().clip(RoundedCornerShape(2.dp)).background(Mn.ExamText).clickable(onClick = onStart).padding(vertical = 16.dp),
                color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp, textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun Fact(icon: androidx.compose.ui.graphics.vector.ImageVector?, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        if (icon != null) Icon(icon, null, tint = Color(0xFF4B5563), modifier = Modifier.size(18.dp))
        Text(text, fontSize = 15.sp, color = Color(0xFF374151), fontWeight = FontWeight.SemiBold)
    }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
private fun RoomView(ui: ExamUi, vm: ExamViewModel, onFinish: () -> Unit, onBack: () -> Unit) {
    val split = LocalConfiguration.current.screenWidthDp >= 840
    var view by remember { mutableStateOf("passage") }
    var pageReady by remember { mutableStateOf(false) }
    val hasPassage = remember { mutableStateMapOf<Int, Boolean>() }
    var webView by remember { mutableStateOf<WebView?>(null) }
    val part = ui.part
    val passage = part?.let { hasPassage[it.payload.id] } ?: true

    fun js(script: String) = webView?.evaluateJavascript(script, null)

    // Render the part (again) when the page is ready or the part changes.
    LaunchedEffect(pageReady, part?.payload?.id) {
        if (!pageReady || part == null) return@LaunchedEffect
        val start = if (part.payload.type == "listening") "questions" else "passage"
        view = start
        val config = vm.renderConfig(start, if (split) "split" else "phone") ?: return@LaunchedEffect
        // The page answers every render with "ready"; render again if it did not (WebView still busy).
        repeat(3) {
            js("window.ExamRoom && ExamRoom.render($config)")
            kotlinx.coroutines.delay(1500)
            if (hasPassage.containsKey(part.payload.id)) return@LaunchedEffect
        }
    }
    LaunchedEffect(view) { js("window.ExamRoom && ExamRoom.setView('$view')") }
    LaunchedEffect(ui.phase) { if (ui.phase != Phase.Running) js("window.ExamRoom && (ExamRoom.flush(), ExamRoom.setLocked(true))") }
    LaunchedEffect(ui.flagged) { js("window.ExamRoom && ExamRoom.setFlagged(${ui.flagged.toList()})") }

    Column(Modifier.fillMaxSize()) {
        // Header: IELTS · module · timer · finish
        Row(
            Modifier.fillMaxWidth().height(56.dp).padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.exit), Modifier.clip(RoundedCornerShape(4.dp)).clickable(onClick = onBack).padding(4.dp), tint = Mn.ExamText)
            IeltsBadge()
            Text(ui.module?.title ?: "", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Mn.ExamText)
            Spacer(Modifier.weight(1f))
            if (ui.offline || ui.pending > 3) {
                Icon(Icons.Outlined.CloudOff, str(R.string.offline_saving), tint = Color(0xFFD97706), modifier = Modifier.size(20.dp))
            }
            Timer(ui.remainingMs)
            Text(
                "FINISH",
                Modifier.clip(RoundedCornerShape(2.dp)).background(Mn.ExamPanel).border(1.dp, Mn.ExamLine, RoundedCornerShape(2.dp))
                    .clickable(enabled = ui.phase == Phase.Running, onClick = onFinish).padding(horizontal = 10.dp, vertical = 8.dp),
                fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Mn.ExamText,
            )
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(Mn.ExamLine))

        if (ui.module?.type == "listening") AudioBar(ui, vm)

        // Parts
        if (ui.parts.size > 1) {
            Row(
                Modifier.fillMaxWidth().background(Mn.ExamPanel).horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                ui.parts.forEachIndexed { i, p ->
                    val on = i == ui.partIndex
                    val qs = p.payload.sections.flatMap { it.questions }
                    val done = qs.count { ui.answered(it.id) }
                    Text(
                        "${p.payload.name ?: "Part ${i + 1}"}  $done/${qs.size}",
                        Modifier.clip(RoundedCornerShape(2.dp)).background(if (on) Color.White else Color.Transparent)
                            .border(1.dp, if (on) Mn.ExamText else Color.Transparent, RoundedCornerShape(2.dp))
                            .clickable { vm.selectPart(i) }.padding(horizontal = 12.dp, vertical = 8.dp),
                        fontSize = 13.sp, fontWeight = if (on) FontWeight.Bold else FontWeight.Medium, color = Mn.ExamText,
                    )
                }
            }
        } else if (part != null) {
            Text(part.payload.name ?: "Part 1", Modifier.fillMaxWidth().background(Mn.ExamPanel).padding(horizontal = 16.dp, vertical = 10.dp), fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Mn.ExamText)
        }

        // Passage | Questions (phone only, when the part has a passage / task)
        if (!split && passage) {
            Row(Modifier.fillMaxWidth().height(46.dp)) {
                val writing = ui.module?.type == "writing"
                listOf("passage" to if (writing) "Task" else "Passage", "questions" to if (writing) "Answer" else "Questions").forEach { (id, label) ->
                    val on = view == id
                    Column(Modifier.weight(1f).fillMaxHeight().clickable { view = id }, horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                            Text(label, fontSize = 15.sp, fontWeight = if (on) FontWeight.Bold else FontWeight.SemiBold, color = if (on) Mn.ExamText else Color(0xFF4B5563))
                        }
                        Box(Modifier.fillMaxWidth().height(3.dp).background(if (on) Mn.ExamBlue else Color.Transparent))
                    }
                }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(Mn.ExamLine))
        }

        AndroidView(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            factory = { context ->
                ExamWebView(context).apply {
                    layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = false
                    settings.allowContentAccess = false
                    settings.textZoom = 100
                    WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)
                    webViewClient = object : WebViewClient() {
                        // The page never navigates anywhere (links in passages are inert).
                        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean = true
                    }
                    webChromeClient = object : android.webkit.WebChromeClient() {
                        override fun onConsoleMessage(m: android.webkit.ConsoleMessage): Boolean {
                            android.util.Log.d("ExamRoom", "${m.messageLevel()} ${m.message()} @${m.lineNumber()}")
                            return true
                        }
                    }
                    addJavascriptInterface(ExamBridge { message -> handleMessage(message, vm, hasPassage, onView = { view = it }) { pageReady = true } }, "AndroidBridge")
                    loadUrl("file:///android_asset/exam-room/index.html")
                    webView = this
                }
            },
            onRelease = { it.destroy() },
        )

        Box(Modifier.fillMaxWidth().height(1.dp).background(Mn.ExamLine))
        NumberBar(ui, onPick = { nq ->
            if (nq.partIndex != ui.partIndex) {
                vm.selectPart(nq.partIndex)
                // Rendered by the LaunchedEffect; scroll once it is on screen.
                webView?.postDelayed({ webView?.evaluateJavascript("ExamRoom.scrollToQuestion(${nq.question.id})", null) }, 350)
            } else {
                view = "questions"
                js("ExamRoom.scrollToQuestion(${nq.question.id})")
            }
        }, onPart = { vm.selectPart(it) })
    }
}

private fun handleMessage(
    message: String,
    vm: ExamViewModel,
    hasPassage: MutableMap<Int, Boolean>,
    onView: (String) -> Unit,
    onLoaded: () -> Unit,
) {
    if (BuildConfig.DEBUG) android.util.Log.d("ExamRoom", "bridge: ${message.take(200)}")
    val obj = runCatching { AppJson.parseToJsonElement(message).jsonObject }.getOrNull() ?: return
    val type = obj["type"]?.jsonPrimitive?.contentOrNull
    val data = obj["data"] as? JsonObject
    when (type) {
        "loaded" -> onLoaded()
        "ready" -> {
            val partId = data?.get("part_id")?.jsonPrimitive?.intOrNull ?: return
            hasPassage[partId] = data["hasPassage"]?.jsonPrimitive?.booleanOrNull ?: true
        }
        "answer" -> {
            data ?: return
            val partId = data["part_id"]?.jsonPrimitive?.int ?: return
            val questionId = data["question_id"]?.jsonPrimitive?.int ?: return
            val hasText = data.containsKey("text")
            val hasOptions = data.containsKey("option_ids")
            val text = (data["text"] as? JsonPrimitive)?.contentOrNull
            val options = if (hasOptions) data["option_ids"]?.jsonArray?.mapNotNull { it.jsonPrimitive.intOrNull } else null
            vm.onAnswer(partId, questionId, text, options, hasText, hasOptions)
        }
        "flag" -> data?.get("question_id")?.jsonPrimitive?.intOrNull?.let(vm::toggleFlag)
        "marks" -> {
            val partId = data?.get("part_id")?.jsonPrimitive?.intOrNull ?: return
            vm.saveMarks(partId, data.toString())
        }
        "view" -> data?.get("view")?.jsonPrimitive?.contentOrNull?.let(onView)
        "log" -> android.util.Log.w("ExamRoom", obj["data"].toString())
    }
}

@Composable
private fun Timer(remainingMs: Long) {
    val total = remainingMs / 1000
    val h = total / 3600
    val m = (total % 3600) / 60
    val s = total % 60
    val text = if (h > 0) String.format(java.util.Locale.US, "%d:%02d:%02d", h, m, s) else String.format(java.util.Locale.US, "%02d:%02d", m, s)
    val warn = total < 5 * 60
    Row(
        Modifier.clip(RoundedCornerShape(2.dp)).background(Color(0xFFF9FAFB)).border(1.dp, Mn.ExamLine, RoundedCornerShape(2.dp)).padding(horizontal = 9.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Icon(Icons.Outlined.Timer, null, tint = if (warn) Mn.ExamTimer else Color(0xFF374151), modifier = Modifier.size(15.dp))
        Text(text, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = if (warn) Mn.ExamTimer else Mn.ExamText)
    }
}

@Composable
private fun AudioBar(ui: ExamUi, vm: ExamViewModel) {
    Row(
        Modifier.fillMaxWidth().background(Color(0xFFF9FAFB)).padding(horizontal = 14.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Outlined.Headphones, null, tint = Mn.ExamText, modifier = Modifier.size(18.dp))
        Text(if (ui.audioPlaying) str(R.string.audio_playing) else "Audio", fontSize = 13.sp, color = Color(0xFF374151), fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.weight(1f))
        Icon(Icons.AutoMirrored.Outlined.VolumeUp, str(R.string.volume), tint = Color(0xFF374151), modifier = Modifier.size(18.dp))
        Slider(
            value = ui.volume,
            onValueChange = vm::setVolume,
            modifier = Modifier.width(140.dp),
            colors = SliderDefaults.colors(thumbColor = Mn.ExamText, activeTrackColor = Mn.ExamText),
        )
    }
    Box(Modifier.fillMaxWidth().height(1.dp).background(Mn.ExamLine))
}

@Composable
private fun NumberBar(ui: ExamUi, onPick: (NavQuestion) -> Unit, onPart: (Int) -> Unit) {
    val list = ui.navQuestions
    val state = rememberLazyListState()
    val firstOfPart = list.indexOfFirst { it.partIndex == ui.partIndex }
    LaunchedEffect(ui.partIndex) { if (firstOfPart >= 0) state.animateScrollToItem(firstOfPart) }

    Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        NavArrow(Icons.AutoMirrored.Outlined.KeyboardArrowLeft, str(R.string.prev_part), ui.partIndex > 0) { onPart(ui.partIndex - 1) }
        LazyRow(Modifier.weight(1f), state = state, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            itemsIndexed(list, key = { _, q -> q.question.id }) { _, q ->
                val answered = ui.answered(q.question.id)
                val flagged = q.question.id in ui.flagged
                val inPart = q.partIndex == ui.partIndex
                Box(
                    Modifier
                        .height(44.dp)
                        .widthIn(min = 38.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(if (answered) Mn.ExamText else Color.White)
                        .border(
                            if (flagged || inPart) 2.dp else 1.dp,
                            when {
                                flagged -> Color(0xFFF97316)
                                answered -> Mn.ExamText
                                inPart -> Mn.ExamBlue
                                else -> Mn.ExamLine
                            },
                            RoundedCornerShape(2.dp),
                        )
                        .clickable { onPick(q) }
                        .padding(horizontal = 6.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(q.label, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = if (answered) Color.White else Color(0xFF374151))
                }
            }
        }
        NavArrow(Icons.AutoMirrored.Outlined.KeyboardArrowRight, str(R.string.next_part), ui.partIndex < ui.parts.size - 1, dark = true) { onPart(ui.partIndex + 1) }
    }
}

@Composable
private fun NavArrow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, enabled: Boolean, dark: Boolean = false, onClick: () -> Unit) {
    Box(
        Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(2.dp))
            .background(if (dark && enabled) Mn.ExamText else Mn.ExamPanel)
            .border(1.dp, if (dark && enabled) Mn.ExamText else Mn.ExamLine, RoundedCornerShape(2.dp))
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, label, tint = if (!enabled) Color(0xFF9CA3AF) else if (dark) Color.White else Mn.ExamText)
    }
}

/**
 * The exam room shows its own Highlight · Note · Clear toolbar for selected text; the system's Copy / Select all
 * menu would cover it (and copying the passage is not part of the IELTS room), so its items are removed.
 */
class ExamWebView(context: android.content.Context) : WebView(context) {
    override fun startActionMode(callback: android.view.ActionMode.Callback, type: Int): android.view.ActionMode? =
        super.startActionMode(EmptyMenu(callback), type)

    override fun startActionMode(callback: android.view.ActionMode.Callback): android.view.ActionMode? =
        super.startActionMode(EmptyMenu(callback))

    private class EmptyMenu(private val wrapped: android.view.ActionMode.Callback) : android.view.ActionMode.Callback2() {
        override fun onCreateActionMode(mode: android.view.ActionMode, menu: android.view.Menu): Boolean {
            wrapped.onCreateActionMode(mode, menu)
            menu.clear()
            return true
        }

        override fun onPrepareActionMode(mode: android.view.ActionMode, menu: android.view.Menu): Boolean {
            wrapped.onPrepareActionMode(mode, menu)
            menu.clear()
            return true
        }

        override fun onActionItemClicked(mode: android.view.ActionMode, item: android.view.MenuItem): Boolean = false

        override fun onDestroyActionMode(mode: android.view.ActionMode) = wrapped.onDestroyActionMode(mode)

        override fun onGetContentRect(mode: android.view.ActionMode, view: android.view.View, outRect: android.graphics.Rect) {
            if (wrapped is android.view.ActionMode.Callback2) wrapped.onGetContentRect(mode, view, outRect) else super.onGetContentRect(mode, view, outRect)
        }
    }
}
