package uz.mynine.app.ui.result

import uz.mynine.app.R
import uz.mynine.app.data.str

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import uz.mynine.app.data.ResultModule
import uz.mynine.app.data.ResultResponse
import uz.mynine.app.data.ReviewQuestion
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.main.BandRing
import uz.mynine.app.ui.main.shortDate
import uz.mynine.app.ui.theme.ErrorBox
import uz.mynine.app.ui.theme.GlassBackground
import uz.mynine.app.ui.theme.GlassCard
import uz.mynine.app.ui.theme.LoadingBox
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.Pill
import uz.mynine.app.ui.theme.band
import uz.mynine.app.ui.theme.glass

@Composable
fun ResultScreen(attemptId: Int, onBack: () -> Unit) {
    var result by remember { mutableStateOf<ResultResponse?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }
    var selected by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(reload) {
        error = null
        try {
            result = call { result(attemptId) }
            if (selected == null) selected = result?.modules?.firstOrNull()?.type
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }
    // Writing is scored by AI in the background: refresh until the band arrives.
    LaunchedEffect(result?.bands?.writingPending) {
        if (result?.bands?.writingPending == true) {
            delay(8000)
            reload++
        }
    }

    GlassBackground(2) {
        LazyColumn(
            Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.statusBars).windowInsetsPadding(WindowInsets.navigationBars),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Box(Modifier.size(44.dp).glass(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.back), tint = Mn.Ink2)
                    }
                    Column {
                        Text(result?.attempt?.test?.name ?: str(R.string.result), fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                        result?.attempt?.let { Text(shortDate(it.finishedAt ?: it.startedAt), fontSize = 13.sp, color = Mn.Subtle) }
                    }
                }
            }
            error?.let { msg -> item { ErrorBox(msg) { reload++ } } }
            val r = result
            if (r == null && error == null) item { LoadingBox() }
            if (r != null) {
                item { Summary(r) }
                if (r.modules.size > 1) {
                    item {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            r.modules.forEach { m ->
                                val on = m.type == selected
                                Text(
                                    m.title,
                                    Modifier.clip(RoundedCornerShape(999.dp)).background(if (on) Mn.Accent else Mn.Glass).clickable { selected = m.type }.padding(horizontal = 16.dp, vertical = 9.dp),
                                    color = if (on) Color.White else Mn.Ink2, fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                                )
                            }
                        }
                    }
                }
                val module = r.modules.firstOrNull { it.type == selected } ?: r.modules.firstOrNull()
                if (module != null) {
                    if (module.type == "writing") {
                        items(module.essays, key = { it.questionId }) { e ->
                            GlassCard(Modifier.fillMaxWidth()) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("Task ${e.task}", Modifier.weight(1f), fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Mn.Ink)
                                    Pill(if (e.band != null) "Band ${band(e.band)}" else str(R.string.grading), bg = if (e.band != null) Mn.GreenSoft else Mn.AccentSoft, fg = if (e.band != null) Mn.Green else Mn.AccentDark)
                                }
                                Spacer(Modifier.height(6.dp))
                                Text(str(R.string.words, e.words), fontSize = 13.sp, color = Mn.Subtle)
                                Spacer(Modifier.height(10.dp))
                                Text(e.answer.ifBlank { str(R.string.no_answer) }, fontSize = 14.sp, lineHeight = 21.sp, color = Mn.Muted, maxLines = 12)
                                e.feedback?.takeIf { it.isNotBlank() }?.let { fb ->
                                    Spacer(Modifier.height(12.dp))
                                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Color(0x144F46E5)).padding(14.dp)) {
                                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                            Icon(Icons.Outlined.AutoAwesome, null, tint = Color(0xFF3730A3), modifier = Modifier.size(18.dp))
                                            Text(str(R.string.ai_feedback), fontWeight = FontWeight.Bold, color = Color(0xFF3730A3))
                                        }
                                        Spacer(Modifier.height(6.dp))
                                        Text(plainMarkdown(fb), fontSize = 14.sp, lineHeight = 21.sp, color = Mn.Muted)
                                    }
                                }
                            }
                        }
                    } else {
                        item {
                            Text(
                                str(R.string.answers_of, module.title) + (module.correct?.let { " · ${it.toInt()} / ${module.questions.sumOf { q -> q.maxPoints }}" } ?: ""),
                                fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Mn.Ink,
                            )
                        }
                        item {
                            Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp)).padding(vertical = 6.dp)) {
                                module.questions.forEach { ReviewRow(it) }
                                if (module.questions.isEmpty()) Text(str(R.string.no_questions), Modifier.padding(16.dp), color = Mn.Subtle)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Summary(r: ResultResponse) {
    val b = r.bands
    val main = b.overall ?: r.modules.singleOrNull()?.band
    GlassCard(Modifier.fillMaxWidth(), radius = 28.dp) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            BandRing(main, 150, label = if (b.overall != null) "OVERALL" else r.modules.singleOrNull()?.title?.uppercase())
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                r.modules.forEach { m -> ModuleBand(m, Modifier.weight(1f)) }
            }
            if (b.writingPending) Text(str(R.string.writing_pending), fontSize = 13.sp, color = Mn.Subtle)
        }
    }
}

@Composable
private fun ModuleBand(m: ResultModule, modifier: Modifier) {
    Column(
        modifier.clip(RoundedCornerShape(20.dp)).background(Color(0xCCFFFFFF)).padding(vertical = 12.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Text(m.title, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Mn.Subtle)
        Text(band(m.band), fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink)
        val total = m.questions.sumOf { it.maxPoints }
        Text(if (m.type == "writing") str(R.string.ai_grade) else "${m.correct?.toInt() ?: 0}/$total", fontSize = 12.sp, color = Mn.Subtle)
    }
}

@Composable
private fun ReviewRow(q: ReviewQuestion) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 9.dp), verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            Modifier.size(26.dp).clip(CircleShape).background(if (q.isCorrect) Mn.GreenSoft else Mn.OrangeSoft),
            contentAlignment = Alignment.Center,
        ) {
            Icon(if (q.isCorrect) Icons.Outlined.Check else Icons.Outlined.Close, if (q.isCorrect) str(R.string.correct) else str(R.string.wrong), tint = if (q.isCorrect) Mn.Green else Mn.Orange, modifier = Modifier.size(15.dp))
        }
        Text(
            if (q.numberCount > 1) "${q.number}–${q.number + q.numberCount - 1}" else "${q.number}",
            Modifier.width(40.dp).padding(top = 3.dp), fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Mn.Ink,
        )
        Text(
            buildAnnotatedString {
                if (q.isCorrect) {
                    append(q.yourAnswer ?: "")
                } else {
                    append(str(R.string.yours))
                    if (q.yourAnswer.isNullOrBlank()) append("—") else withStyle(SpanStyle(textDecoration = TextDecoration.LineThrough)) { append(q.yourAnswer) }
                    append(str(R.string.correct_sep))
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold, color = Mn.Ink)) { append(q.correctAnswer) }
                }
            },
            Modifier.weight(1f).padding(top = 3.dp), fontSize = 14.sp, color = Mn.Muted, lineHeight = 20.sp,
        )
    }
}

/** AI feedback is Markdown ("### …", "**…**"): shown as plain text. */
private fun plainMarkdown(text: String): String =
    text.lines().joinToString("\n") { it.trimStart('#', ' ').replace("**", "") }
        .replace(Regex("\n{3,}"), "\n\n").trim()
