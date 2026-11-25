package uz.mynine.app.ui.main

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.AccessTime
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import uz.mynine.app.data.AttemptSummary
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.theme.ErrorBox
import uz.mynine.app.ui.theme.GlassCard
import uz.mynine.app.ui.theme.LoadingBox
import uz.mynine.app.ui.theme.ScreenTitle
import uz.mynine.app.ui.tests.TestsTab
import uz.mynine.app.ui.theme.GlassBackground
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.Pill
import uz.mynine.app.ui.theme.band
import uz.mynine.app.ui.theme.glass
import uz.mynine.app.ui.theme.moduleTitle

enum class Tab(val label: String, val icon: ImageVector) {
    Home("Bosh", Icons.Outlined.Home),
    Tests("Testlar", Icons.AutoMirrored.Outlined.MenuBook),
    History("Tarix", Icons.Outlined.AccessTime),
    Profile("Profil", Icons.Outlined.Person),
}

@Composable
fun MainScreen(openTest: (Int) -> Unit, openExam: (Int) -> Unit, openResult: (Int) -> Unit) {
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    var testsModule by rememberSaveable { mutableStateOf<String?>(null) }

    GlassBackground(tab.ordinal) {
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.statusBars)) {
            when (tab) {
                Tab.Home -> HomeTab(
                    openTest = openTest,
                    openExam = openExam,
                    openResult = openResult,
                    openTests = { module -> testsModule = module; tab = Tab.Tests },
                    openProfile = { tab = Tab.Profile },
                )
                Tab.Tests -> TestsTab(initialModule = testsModule, openTest = openTest)
                Tab.History -> HistoryTab(openExam = openExam, openResult = openResult)
                Tab.Profile -> ProfileTab(openHistory = { tab = Tab.History })
            }
            BottomBar(tab, Modifier.align(Alignment.BottomCenter)) { tab = it; if (it != Tab.Tests) testsModule = null }
        }
    }
}

@Composable
private fun BottomBar(current: Tab, modifier: Modifier, onSelect: (Tab) -> Unit) {
    Row(
        modifier
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(horizontal = 16.dp, vertical = 14.dp)
            .fillMaxWidth()
            .height(68.dp)
            .glass(RoundedCornerShape(999.dp), strong = true)
            .padding(6.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Tab.entries.forEach { t ->
            val active = t == current
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(999.dp))
                    .background(if (active) Mn.Accent else Color.Transparent)
                    .clickable { onSelect(t) },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(t.icon, t.label, tint = if (active) Color.White else Mn.Muted, modifier = Modifier.size(20.dp))
                Text(t.label, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = if (active) Color.White else Mn.Muted)
            }
        }
    }
}

/** Space the floating bottom bar covers. */
val BottomBarSpace = PaddingValues(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 120.dp)

@Composable
fun Avatar(name: String, size: Int = 44) {
    Box(
        Modifier.size(size.dp).clip(CircleShape).background(Brush.linearGradient(listOf(Color(0xFF6366F1), Color(0xFFEC4899)))),
        contentAlignment = Alignment.Center,
    ) {
        Text(name.trim().firstOrNull()?.uppercase() ?: "M", color = Color.White, fontWeight = FontWeight.Bold, fontSize = (size * 0.38).sp)
    }
}

/** One attempt in a list: test, modules, date, band or "davom etmoqda". */
@Composable
fun AttemptRow(item: AttemptSummary, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().glass(RoundedCornerShape(22.dp)).clickable(onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(item.test.name ?: "Test", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Mn.Ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            val modules = when {
                item.module != null -> moduleTitle(item.module)
                item.modules.isNotEmpty() -> item.modules.joinToString(" · ") { moduleTitle(it) }
                else -> "To'liq test"
            }
            Text("$modules · ${shortDate(item.startedAt)}", fontSize = 13.sp, color = Mn.Subtle)
        }
        if (item.status == "completed") {
            val b = item.bands
            val value = b?.overall ?: b?.listening ?: b?.reading ?: b?.writing
            Pill("Band ${band(value)}", bg = Mn.GreenSoft, fg = Mn.Green)
        } else {
            Pill("Davom etmoqda", bg = Mn.AccentSoft, fg = Mn.AccentDark)
        }
    }
}

fun shortDate(iso: String?): String {
    if (iso == null || iso.length < 10) return ""
    val months = listOf("yan", "fev", "mar", "apr", "may", "iyun", "iyul", "avg", "sen", "okt", "noy", "dek")
    val m = iso.substring(5, 7).toIntOrNull() ?: return iso.take(10)
    val d = iso.substring(8, 10).toIntOrNull() ?: return iso.take(10)
    return "$d-${months[(m - 1).coerceIn(0, 11)]}"
}

@Composable
fun HistoryTab(openExam: (Int) -> Unit, openResult: (Int) -> Unit) {
    var items by remember { mutableStateOf<List<AttemptSummary>?>(null) }
    var page by remember { mutableIntStateOf(1) }
    var lastPage by remember { mutableIntStateOf(1) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(page, reload) {
        error = null
        try {
            val r = call { attempts(page) }
            items = if (page == 1) r.data else (items.orEmpty() + r.data)
            lastPage = r.meta.lastPage
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = BottomBarSpace, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        item { ScreenTitle("Tarix", Modifier.padding(top = 20.dp, bottom = 8.dp)) }
        error?.let { msg -> item { ErrorBox(msg) { reload++ } } }
        val list = items
        if (list == null && error == null) item { LoadingBox() }
        if (list != null && list.isEmpty()) {
            item {
                GlassCard(Modifier.fillMaxWidth()) {
                    Text("Hali test yechmagansiz", fontWeight = FontWeight.Bold, color = Mn.Ink)
                    Spacer(Modifier.height(4.dp))
                    Text("Testlar bo'limidan birinchi testingizni boshlang.", color = Mn.Muted, fontSize = 14.sp)
                }
            }
        }
        items(list.orEmpty(), key = { it.id }) { a ->
            AttemptRow(a) { if (a.status == "completed") openResult(a.id) else openExam(a.id) }
        }
        if (list != null && page < lastPage) {
            item {
                Text(
                    "Yana yuklash",
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(999.dp)).clickable { page++ }.padding(14.dp),
                    color = Mn.Accent, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                )
            }
        }
    }
}
