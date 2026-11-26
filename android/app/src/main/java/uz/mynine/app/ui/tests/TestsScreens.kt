package uz.mynine.app.ui.tests

import uz.mynine.app.R
import uz.mynine.app.data.str

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

@OptIn(ExperimentalLayoutApi::class)
@Composable
/** A skill tab (module = listening|reading|writing) or the full-test list (full = true, opened from home). */
fun TestsTab(title: String, module: String?, full: Boolean, openTest: (Int) -> Unit, onBack: (() -> Unit)? = null) {
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
            val r = call { tests(search = query.ifBlank { null }, module = module, full = if (full) 1 else null, page = page) }
            // A full test has content in all three skills (the server also checks; empty modules are not listed).
            val data = if (full) r.data.filter { it.modules.size >= 3 } else r.data
            items = if (page == 1) data else items.orEmpty() + data
            lastPage = r.meta.lastPage
        } catch (e: Exception) {
            error = e.userMessage()
        }
    }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = BottomBarSpace, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Row(Modifier.padding(top = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (onBack != null) {
                    Box(Modifier.size(44.dp).glass(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.back), tint = Mn.Ink2)
                    }
                }
                ScreenTitle(title)
            }
        }
        item {
            Row(
                Modifier.fillMaxWidth().height(50.dp).glass(RoundedCornerShape(999.dp), strong = true).padding(horizontal = 18.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Outlined.Search, null, tint = Mn.Subtle, modifier = Modifier.size(20.dp))
                Box(Modifier.weight(1f)) {
                    if (search.isEmpty()) Text(str(R.string.search_hint), color = Mn.Subtle, fontSize = 15.sp)
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
        error?.let { msg -> item { ErrorBox(msg) { reload++ } } }
        val list = items
        if (list == null && error == null) item { LoadingBox() }
        if (list != null && list.isEmpty()) {
            item { Text(str(R.string.nothing_found), Modifier.fillMaxWidth().padding(24.dp), textAlign = TextAlign.Center, color = Mn.Subtle) }
        }
        items(list.orEmpty(), key = { it.id }) { t -> TestCard(t) { openTest(t.id) } }
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
                t.inProgressAttemptId != null -> Pill(str(R.string.in_progress), bg = Mn.AccentSoft, fg = Mn.AccentDark)
                t.lastFinishedAttemptId != null -> Pill(str(R.string.solved), bg = Mn.GreenSoft, fg = Mn.Green)
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
fun TestDetailScreen(testId: Int, skill: String? = null, onBack: () -> Unit, openExam: (Int) -> Unit, openResult: (Int) -> Unit) {
    val scope = rememberCoroutineScope()
    var test by remember { mutableStateOf<TestItem?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var selected by remember { mutableStateOf<Set<String>>(emptySet()) }
    var starting by remember { mutableStateOf(false) }
    var reload by remember { mutableIntStateOf(0) }
    var fullCount by remember { mutableIntStateOf(0) }

    LaunchedEffect(testId, reload) {
        error = null
        try {
            // All modules are listed; opened from a skill tab only that skill is ticked, the student may tick the rest.
            val t = call { test(testId) }.test
            test = t
            fullCount = t.modules.size
            selected = if (skill != null && t.modules.any { it.type == skill }) setOf(skill) else t.modules.map { it.type }.toSet()
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
                ) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, str(R.string.back), tint = Mn.Ink2) }
                Text(str(R.string.tests), fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Mn.Subtle)
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
                                    str(R.string.module_count, t.modules.size),
                                    minutes(t.modules.sumOf { it.durationSeconds }),
                                ).joinToString(" · "),
                                fontSize = 15.sp, color = Mn.Muted,
                            )
                        }

                        Column(Modifier.fillMaxWidth().glass(RoundedCornerShape(28.dp)).padding(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(str(R.string.which_modules), Modifier.padding(start = 12.dp, top = 10.dp, bottom = 4.dp), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Mn.Subtle)
                            t.modules.forEach { m ->
                                val on = m.type in selected
                                Row(
                                    Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(22.dp))
                                        .background(if (on) Mn.Raised else Color.Transparent)
                                        .clickable { selected = if (on) selected - m.type else selected + m.type }
                                        .padding(horizontal = 12.dp, vertical = 14.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                ) {
                                    Box(
                                        Modifier
                                            .size(26.dp)
                                            .clip(RoundedCornerShape(9.dp))
                                            .background(if (on) Mn.Accent else Mn.Surface)
                                            .border(if (on) 0.dp else 1.5.dp, Mn.FieldBorder, RoundedCornerShape(9.dp)),
                                        contentAlignment = Alignment.Center,
                                    ) { if (on) Icon(Icons.Outlined.Check, null, tint = Color.White, modifier = Modifier.size(16.dp)) }
                                    Column(Modifier.weight(1f)) {
                                        Text(m.title, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                                        Text(
                                            str(R.string.parts_questions, m.partsCount, m.questionsCount, minutes(m.durationSeconds)),
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
                            Text(str(R.string.rules), fontSize = 15.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
                            Rule(Icons.Outlined.Headphones, str(R.string.rule_audio))
                            Rule(Icons.Outlined.Save, str(R.string.rule_save))
                            Rule(Icons.Outlined.Timer, str(R.string.rule_timer))
                        }
                        Spacer(Modifier.height(8.dp))
                    }
                }
            }

            val t = test
            if (t != null) {
                val chosen = t.modules.filter { it.type in selected }
                // Some modules: "listening,reading"; all of them: the full test (null).
                val module = if (chosen.size < fullCount) chosen.joinToString(",") { it.type } else null
                val ready = chosen.isNotEmpty()
                PrimaryButton(
                    if (t.inProgressAttemptId != null) str(R.string.continue_) else str(R.string.start_with, minutes(chosen.sumOf { it.durationSeconds })),
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
                        str(R.string.see_last_result),
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(999.dp)).clickable { openResult(last) }.padding(12.dp),
                        textAlign = TextAlign.Center, color = Mn.Accent, fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
                    )
                }
                if (t.modules.size > 1 && selected.size == t.modules.size) Text(str(R.string.order), Modifier.fillMaxWidth().padding(top = 6.dp), textAlign = TextAlign.Center, fontSize = 13.sp, color = Mn.Subtle)
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
