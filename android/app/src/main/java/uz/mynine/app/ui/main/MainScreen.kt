package uz.mynine.app.ui.main

import uz.mynine.app.R
import uz.mynine.app.data.str

import androidx.activity.compose.BackHandler
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.material.icons.automirrored.rounded.MenuBook
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material.icons.rounded.AccessTime
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.Headphones
import androidx.compose.material.icons.rounded.Home
import androidx.compose.runtime.key
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.semantics.Role
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

enum class Tab(private val fixedLabel: String?, val icon: ImageVector, val selectedIcon: ImageVector, val module: String? = null) {
    Home(null, Icons.Outlined.Home, Icons.Rounded.Home),
    Listening("Listening", Icons.Outlined.Headphones, Icons.Rounded.Headphones, "listening"),
    Reading("Reading", Icons.AutoMirrored.Outlined.MenuBook, Icons.AutoMirrored.Rounded.MenuBook, "reading"),
    Writing("Writing", Icons.Outlined.Edit, Icons.Rounded.Edit, "writing"),
    Attempts(null, Icons.Outlined.AccessTime, Icons.Rounded.AccessTime);

    /** Skill tabs keep their English exam names in every language. */
    val label: String get() = fixedLabel ?: str(if (this == Home) R.string.nav_home else R.string.attempts)
}

/** Screens of the home tab without a tab of their own: Home stays lit and back returns home. */
private enum class HomeChild { Profile, FullTests }

@Composable
fun MainScreen(openTest: (Int, String?) -> Unit, openExam: (Int) -> Unit, openResult: (Int) -> Unit) {
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    var child by rememberSaveable { mutableStateOf<HomeChild?>(null) }

    BackHandler(enabled = child != null || tab != Tab.Home) {
        if (child != null) child = null else tab = Tab.Home
    }

    GlassBackground(tab.ordinal) {
        Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.statusBars)) {
            when {
                child == HomeChild.Profile -> ProfileTab(openHistory = { child = null; tab = Tab.Attempts }, onBack = { child = null })
                child == HomeChild.FullTests -> TestsTab(str(R.string.full_tests), module = null, full = true, openTest = { openTest(it, null) }, onBack = { child = null })
                tab == Tab.Home -> HomeTab(
                    openTest = { openTest(it, null) },
                    openExam = openExam,
                    openResult = openResult,
                    openSkill = { module -> tab = Tab.entries.first { it.module == module } },
                    openFullTests = { child = HomeChild.FullTests },
                    openProfile = { child = HomeChild.Profile },
                )
                tab == Tab.Attempts -> HistoryTab(openExam = openExam, openResult = openResult)
                else -> key(tab) {
                    TestsTab(tab.label, module = tab.module, full = false, openTest = { openTest(it, tab.module) })
                }
            }
            BottomBar(if (child != null) Tab.Home else tab, Modifier.align(Alignment.BottomCenter)) { child = null; tab = it }
        }
    }
}

/** Floating tab bar (same design as the MultiTest app): a card with a pill that slides to the chosen tab. */
@Composable
private fun BottomBar(current: Tab, modifier: Modifier, onSelect: (Tab) -> Unit) {
    val shape = RoundedCornerShape(22.dp)
    Box(
        modifier
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(start = 12.dp, end = 12.dp, bottom = 12.dp)
            .fillMaxWidth()
            .height(62.dp)
            .shadow(14.dp, shape, ambientColor = Color.Black.copy(alpha = 0.10f), spotColor = Color.Black.copy(alpha = 0.16f))
            .clip(shape)
            .background(Color.White)
            .border(1.dp, Color(0xFFE2E8F0), shape),
    ) {
        BoxWithConstraints(Modifier.fillMaxSize().padding(4.dp)) {
            val itemWidth = maxWidth / Tab.entries.size
            val pillOffset by animateDpAsState(
                itemWidth * current.ordinal,
                spring(dampingRatio = 0.72f, stiffness = Spring.StiffnessMediumLow),
                label = "pill",
            )
            Box(Modifier.offset(x = pillOffset).width(itemWidth).fillMaxHeight().clip(RoundedCornerShape(18.dp)).background(Mn.AccentSoft))
            Row(Modifier.fillMaxSize()) {
                Tab.entries.forEach { t ->
                    val selected = t == current
                    val color by animateColorAsState(if (selected) Mn.Accent else Mn.Subtle, label = "tabColor")
                    Column(
                        Modifier
                            .width(itemWidth)
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(18.dp))
                            .selectable(
                                selected = selected,
                                onClick = { if (!selected) onSelect(t) },
                                role = Role.Tab,
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null,
                            ),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                    ) {
                        Icon(if (selected) t.selectedIcon else t.icon, null, tint = color, modifier = Modifier.size(26.dp))
                        Text(
                            t.label, color = color, fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1,
                            overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 1.dp, start = 2.dp, end = 2.dp),
                        )
                    }
                }
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
                else -> str(R.string.full_test)
            }
            Text("$modules · ${shortDate(item.startedAt)}", fontSize = 13.sp, color = Mn.Subtle)
        }
        if (item.status == "completed") {
            val b = item.bands
            val value = b?.overall ?: b?.listening ?: b?.reading ?: b?.writing
            Pill("Band ${band(value)}", bg = Mn.GreenSoft, fg = Mn.Green)
        } else {
            Pill(str(R.string.in_progress), bg = Mn.AccentSoft, fg = Mn.AccentDark)
        }
    }
}

fun shortDate(iso: String?): String {
    if (iso == null || iso.length < 10) return ""
    val months = str(R.string.months).split(",")
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
        item { ScreenTitle(str(R.string.attempts), Modifier.padding(top = 20.dp, bottom = 8.dp)) }
        error?.let { msg -> item { ErrorBox(msg) { reload++ } } }
        val list = items
        if (list == null && error == null) item { LoadingBox() }
        if (list != null && list.isEmpty()) {
            item {
                GlassCard(Modifier.fillMaxWidth()) {
                    Text(str(R.string.no_attempts), fontWeight = FontWeight.Bold, color = Mn.Ink)
                    Spacer(Modifier.height(4.dp))
                    Text(str(R.string.no_attempts_text), color = Mn.Muted, fontSize = 14.sp)
                }
            }
        }
        items(list.orEmpty(), key = { it.id }) { a ->
            AttemptRow(a) { if (a.status == "completed") openResult(a.id) else openExam(a.id) }
        }
        if (list != null && page < lastPage) {
            item {
                Text(
                    str(R.string.load_more),
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(999.dp)).clickable { page++ }.padding(14.dp),
                    color = Mn.Accent, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                )
            }
        }
    }
}
