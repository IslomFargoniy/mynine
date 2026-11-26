package uz.mynine.app.ui.main

import uz.mynine.app.R
import uz.mynine.app.data.str

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import uz.mynine.app.data.AttemptSummary
import uz.mynine.app.data.Session
import uz.mynine.app.data.TestItem
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.theme.ErrorBox
import uz.mynine.app.ui.theme.GlassCard
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.Pill
import uz.mynine.app.ui.theme.SectionHeader
import uz.mynine.app.ui.theme.band
import uz.mynine.app.ui.theme.glass
import uz.mynine.app.ui.theme.minutes
import uz.mynine.app.ui.theme.moduleTitle
import java.time.LocalTime

@Composable
fun HomeTab(
    openTest: (Int) -> Unit,
    openExam: (Int) -> Unit,
    openResult: (Int) -> Unit,
    openSkill: (String) -> Unit,
    openFullTests: () -> Unit,
    openProfile: () -> Unit,
) {
    val user by Session.user.collectAsState()
    var attempts by remember { mutableStateOf<List<AttemptSummary>?>(null) }
    var tests by remember { mutableStateOf<List<TestItem>?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(reload) {
        error = null
        try {
            attempts = call { attempts(1) }.data
            tests = call { tests(full = 1) }.data.filter { it.modules.size >= 3 }.take(4)
            runCatching { call { me() }.user }.getOrNull()?.let { Session.update(it) }
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }

    val running = attempts?.firstOrNull { it.status != "completed" }
    val lastDone = attempts?.firstOrNull { it.status == "completed" }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = BottomBarSpace, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            Row(Modifier.fillMaxWidth().padding(top = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(greeting(), fontSize = 14.sp, color = Mn.Subtle, fontWeight = FontWeight.Medium)
                    Text(user?.name?.split(" ")?.firstOrNull()?.ifBlank { null } ?: str(R.string.student), fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink)
                }
                Box(Modifier.clip(androidx.compose.foundation.shape.CircleShape).clickable(onClick = openProfile)) { Avatar(user?.name ?: "") }
            }
        }

        error?.let { msg -> item { ErrorBox(msg) { reload++ } } }

        item {
            if (lastDone != null) BandCard(lastDone) { openResult(lastDone.id) }
            else GlassCard(Modifier.fillMaxWidth(), radius = 28.dp) {
                Text(str(R.string.first_test_title), fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                Spacer(Modifier.height(6.dp))
                Text(str(R.string.first_test_text), fontSize = 14.sp, color = Mn.Muted, lineHeight = 20.sp)
            }
        }

        if (running != null) {
            item { ContinueCard(running) { openExam(running.id) } }
        }

        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                SectionHeader(str(R.string.modules))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ModuleTile("Listening", Icons.Outlined.Headphones, Color(0x2E38BDF8), if (Mn.dark) Color(0xFF7DD3FC) else Color(0xFF0369A1), Modifier.weight(1f)) { openSkill("listening") }
                    ModuleTile("Reading", Icons.AutoMirrored.Outlined.MenuBook, Color(0x244F46E5), Mn.AccentDark, Modifier.weight(1f)) { openSkill("reading") }
                    ModuleTile("Writing", Icons.Outlined.Edit, Color(0x24EC4899), if (Mn.dark) Color(0xFFF9A8D4) else Color(0xFFBE185D), Modifier.weight(1f)) { openSkill("writing") }
                }
            }
        }

        item { SectionHeader(str(R.string.full_tests), str(R.string.all)) { openFullTests() } }
        items(tests.orEmpty(), key = { it.id }) { t ->
            Row(
                Modifier.fillMaxWidth().glass(RoundedCornerShape(22.dp)).clickable { openTest(t.id) }.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(t.name, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                    Text(
                        listOfNotNull(t.folder?.name?.trim(), t.modules.joinToString(" · ") { it.title.take(1) }, minutes(t.modules.sumOf { it.durationSeconds })).joinToString(" · "),
                        fontSize = 13.sp, color = Mn.Subtle,
                    )
                }
                Text("›", fontSize = 24.sp, color = Mn.Subtle)
            }
        }
    }
}

private fun greeting(): String = when (LocalTime.now().hour) {
    in 5..10 -> str(R.string.good_morning)
    in 11..17 -> str(R.string.good_day)
    else -> str(R.string.good_evening)
}

@Composable
private fun BandCard(item: AttemptSummary, onClick: () -> Unit) {
    val b = item.bands
    val main = b?.overall ?: b?.listening ?: b?.reading ?: b?.writing
    GlassCard(Modifier.fillMaxWidth(), radius = 28.dp, onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
            BandRing(main, 92)
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(if (b?.overall != null) str(R.string.last_overall) else str(R.string.last_result), fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Mn.Subtle)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    b?.listening?.let { Pill("L ${band(it)}") }
                    b?.reading?.let { Pill("R ${band(it)}") }
                    b?.writing?.let { Pill("W ${band(it)}") }
                }
                Text(str(R.string.see_result), fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Mn.Accent)
            }
        }
    }
}

@Composable
fun BandRing(value: Double?, sizeDp: Int, label: String? = null) {
    Box(Modifier.size(sizeDp.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = size.minDimension * 0.11f
            val arc = Size(size.width - stroke, size.height - stroke)
            val topLeft = Offset(stroke / 2, stroke / 2)
            drawArc(Mn.AccentSoft, 0f, 360f, false, topLeft, arc, style = Stroke(stroke))
            drawArc(Mn.Accent, -90f, 360f * ((value ?: 0.0) / 9.0).toFloat(), false, topLeft, arc, style = Stroke(stroke, cap = StrokeCap.Round))
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (label != null) Text(label, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Mn.Subtle, letterSpacing = 1.sp)
            Text(band(value), fontSize = (sizeDp * 0.28).sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink)
        }
    }
}

@Composable
private fun ContinueCard(item: AttemptSummary, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Mn.Accent)
            .clickable(onClick = onClick)
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(str(R.string.continue_caps), fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFFE0E7FF), letterSpacing = 1.sp)
        Text(
            (item.test.name ?: "Test") + (item.module?.let { " · " + moduleTitle(it) } ?: ""),
            fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White,
        )
        Text(str(R.string.unfinished), fontSize = 14.sp, color = Color(0xFFE0E7FF))
        Text(
            str(R.string.continue_),
            Modifier.clip(RoundedCornerShape(999.dp)).background(Color.White).padding(horizontal = 18.dp, vertical = 10.dp),
            color = Color(0xFF4338CA), fontWeight = FontWeight.Bold, fontSize = 14.sp,
        )
    }
}

@Composable
private fun ModuleTile(title: String, icon: ImageVector, bg: Color, fg: Color, modifier: Modifier, onClick: () -> Unit) {
    Column(
        modifier.glass(RoundedCornerShape(22.dp)).clickable(onClick = onClick).padding(horizontal = 12.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(Modifier.size(36.dp).clip(RoundedCornerShape(12.dp)).background(bg), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = fg, modifier = Modifier.size(18.dp))
        }
        Text(title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
    }
}
