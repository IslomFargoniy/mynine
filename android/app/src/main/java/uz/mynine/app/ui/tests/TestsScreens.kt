package uz.mynine.app.ui.tests

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Headphones
import androidx.compose.material.icons.outlined.Save
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import uz.mynine.app.data.StartAttemptBody
import uz.mynine.app.data.TestItem
import uz.mynine.app.data.call
import uz.mynine.app.data.userMessage
import uz.mynine.app.ui.main.BottomBarSpace
import uz.mynine.app.ui.theme.ErrorBox
import uz.mynine.app.ui.theme.GlassBackground
import uz.mynine.app.ui.theme.LoadingBox
import uz.mynine.app.ui.theme.Mn
import uz.mynine.app.ui.theme.Pill
import uz.mynine.app.ui.theme.PrimaryButton
import uz.mynine.app.ui.theme.ScreenTitle
import uz.mynine.app.ui.theme.glass
import uz.mynine.app.ui.theme.minutes

private val Filters = listOf(null to "Hammasi", "listening" to "Listening", "reading" to "Reading", "writing" to "Writing")

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TestsTab(initialModule: String?, openTest: (Int) -> Unit) {
    var module by rememberSaveable { mutableStateOf(initialModule) }
    var search by rememberSaveable { mutableStateOf("") }
    var query by remember { mutableStateOf("") }
    var items by remember { mutableStateOf<List<TestItem>?>(null) }
    var page by remember { mutableIntStateOf(1) }
    var lastPage by remember { mutableIntStateOf(1) }
    var error by remember { mutableStateOf<String?>(null) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(search) {
        delay(350)
        query = search.trim()
    }
    LaunchedEffect(module, query) { page = 1; items = null }
    LaunchedEffect(module, query, page, reload) {
        error = null
        try {
            val r = call { tests(search = query.ifBlank { null }, module = module, page = page) }
            items = if (page == 1) r.data else items.orEmpty() + r.data
            lastPage = r.meta.lastPage
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = BottomBarSpace, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { ScreenTitle("Testlar", Modifier.padding(top = 20.dp)) }
        item {
            Row(
                Modifier.fillMaxWidth().height(50.dp).glass(RoundedCornerShape(999.dp), strong = true).padding(horizontal = 18.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Outlined.Search, null, tint = Mn.Subtle, modifier = Modifier.size(20.dp))
                Box(Modifier.weight(1f)) {
                    if (search.isEmpty()) Text("Test nomi bo'yicha qidirish", color = Mn.Subtle, fontSize = 15.sp)
                    BasicTextField(
                        search, { search = it },
                        singleLine = true,
                        textStyle = TextStyle(fontSize = 15.sp, color = Mn.Ink),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { query = search.trim() }),
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
        }
        item {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Filters.forEach { (id, label) ->
                    val on = module == id
                    Text(
                        label,
                        Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(if (on) Mn.Accent else Mn.Glass)
                            .border(1.dp, if (on) Color.Transparent else Mn.GlassEdge, RoundedCornerShape(999.dp))
                            .clickable { module = id }
                            .padding(horizontal = 16.dp, vertical = 9.dp),
                        color = if (on) Color.White else Mn.Ink2,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }
        error?.let { msg -> item { ErrorBox(msg) { reload++ } } }
        val list = items
        if (list == null && error == null) item { LoadingBox() }
        if (list != null && list.isEmpty()) {
            item { Text("Hech narsa topilmadi.", Modifier.fillMaxWidth().padding(24.dp), textAlign = TextAlign.Center, color = Mn.Subtle) }
        }
        items(list.orEmpty(), key = { it.id }) { t -> TestCard(t) { openTest(t.id) } }
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

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TestCard(t: TestItem, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp)).clickable(onClick = onClick).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(t.name, Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
            when {
                t.inProgressAttemptId != null -> Pill("Davom etmoqda", bg = Mn.AccentSoft, fg = Mn.AccentDark)
                t.lastFinishedAttemptId != null -> Pill("Yechilgan", bg = Mn.GreenSoft, fg = Mn.Green)
            }
        }
        FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            t.modules.forEach { Pill(it.title) }
            Text(minutes(t.modules.sumOf { it.durationSeconds }), Modifier.padding(start = 4.dp, top = 4.dp), fontSize = 13.sp, color = Mn.Subtle)
        }
        t.folder?.let { Text(it.name, fontSize = 13.sp, color = Mn.Subtle) }
    }
}

@Composable
fun TestDetailScreen(testId: Int, onBack: () -> Unit, openExam: (Int) -> Unit, openResult: (Int) -> Unit) {
    val scope = rememberCoroutineScope()
    var test by remember { mutableStateOf<TestItem?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var selected by remember { mutableStateOf<Set<String>>(emptySet()) }
    var starting by remember { mutableStateOf(false) }
    var reload by remember { mutableIntStateOf(0) }

    LaunchedEffect(testId, reload) {
        error = null
        try {
            val t = call { test(testId) }.test
            test = t
            selected = t.modules.map { it.type }.toSet()
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }

    GlassBackground(1) {
        Column(
            Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.statusBars)
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(horizontal = 20.dp, vertical = 12.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(
                    Modifier.size(44.dp).glass(CircleShape).clickable(onClick = onBack),
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, "Orqaga", tint = Mn.Ink2) }
                Text("Testlar", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Mn.Subtle)
            }

            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(top = 18.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                val t = test
                when {
                    error != null -> ErrorBox(error!!) { reload++ }
                    t == null -> LoadingBox()
                    else -> {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(t.name, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink, lineHeight = 32.sp)
                            Text(
                                listOfNotNull(
                                    t.folder?.name?.trim(),
                                    t.variant?.let { if (it == "general") "General Training" else "Academic" },
                                    "${t.modules.size} modul",
                                    minutes(t.modules.sumOf { it.durationSeconds }),
                                ).joinToString(" · "),
                                fontSize = 15.sp, color = Mn.Muted,
                            )
                        }

                        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(28.dp)).padding(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("Qaysi modullarni yechasiz?", Modifier.padding(start = 12.dp, top = 10.dp, bottom = 4.dp), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Mn.Subtle)
                            t.modules.forEach { m ->
                                val on = m.type in selected
                                Row(
                                    Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(22.dp))
                                        .background(if (on) Color(0xD9FFFFFF) else Color.Transparent)
                                        .clickable { selected = if (on) selected - m.type else selected + m.type }
                                        .padding(horizontal = 12.dp, vertical = 14.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                ) {
                                    Box(
                                        Modifier
                                            .size(26.dp)
                                            .clip(RoundedCornerShape(9.dp))
                                            .background(if (on) Mn.Accent else Color.White)
                                            .border(if (on) 0.dp else 1.5.dp, Color(0xFF94A3B8), RoundedCornerShape(9.dp)),
                                        contentAlignment = Alignment.Center,
                                    ) { if (on) Icon(Icons.Outlined.Check, null, tint = Color.White, modifier = Modifier.size(16.dp)) }
                                    Column(Modifier.weight(1f)) {
                                        Text(m.title, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                                        Text(
                                            "${m.partsCount} part · ${m.questionsCount} savol · ${minutes(m.durationSeconds)}",
                                            fontSize = 13.sp, color = Mn.Subtle,
                                        )
                                    }
                                }
                            }
                        }

                        Column(
                            Modifier.fillMaxWidth().glass(RoundedCornerShape(24.dp)).padding(18.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text("Qoidalar", fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                            Rule(Icons.Outlined.Headphones, "Listening audiosi faqat bir marta ijro etiladi. Quloqchin taqing.")
                            Rule(Icons.Outlined.Save, "Javoblar avtomatik saqlanadi — internet uzilsa ham davom etasiz.")
                            Rule(Icons.Outlined.Timer, "Vaqt server bo'yicha hisoblanadi, ilovadan chiqsangiz ham to'xtamaydi.")
                        }
                        Spacer(Modifier.height(8.dp))
                    }
                }
            }

            val t = test
            if (t != null) {
                val chosen = t.modules.filter { it.type in selected }
                val module = if (chosen.size == 1 && t.modules.size > 1) chosen.first().type else null
                val ready = chosen.isNotEmpty() && (chosen.size == 1 || chosen.size == t.modules.size)
                if (!ready && chosen.isNotEmpty()) {
                    Text("Bitta modulni yoki to'liq testni tanlang.", Modifier.fillMaxWidth().padding(bottom = 8.dp), textAlign = TextAlign.Center, color = Mn.Subtle, fontSize = 13.sp)
                }
                PrimaryButton(
                    if (t.inProgressAttemptId != null) "Davom etish" else "Boshlash · ${minutes(chosen.sumOf { it.durationSeconds })}",
                    Modifier.fillMaxWidth(),
                    enabled = ready,
                    loading = starting,
                ) {
                    starting = true
                    scope.launch {
                        try {
                            val attempt = call { startAttempt(StartAttemptBody(t.id, module)) }.attempt
                            openExam(attempt.id)
                        } catch (e: Exception) {
                            error = e.userMessage()
                        } finally {
                            starting = false
                        }
                    }
                }
                t.lastFinishedAttemptId?.let { last ->
                    Text(
                        "Oxirgi natijani ko'rish",
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(999.dp)).clickable { openResult(last) }.padding(12.dp),
                        textAlign = TextAlign.Center, color = Mn.Accent, fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                    )
                }
                Text("Tartib: Listening → Reading → Writing", Modifier.fillMaxWidth().padding(top = 6.dp), textAlign = TextAlign.Center, fontSize = 13.sp, color = Mn.Subtle)
            }
        }
    }
}

@Composable
private fun Rule(icon: ImageVector, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(icon, null, tint = Mn.Accent, modifier = Modifier.size(18.dp).padding(top = 1.dp))
        Text(text, fontSize = 14.sp, lineHeight = 20.sp, color = Mn.Muted)
    }
}
