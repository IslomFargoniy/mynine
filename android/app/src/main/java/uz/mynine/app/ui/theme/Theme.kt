package uz.mynine.app.ui.theme

import uz.mynine.app.R
import uz.mynine.app.data.str

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Liquid glass tokens (web resources/css/app.css, design canvas "Mynine Mobile"). */
object Mn {
    val Bg = Color(0xFFEEF1F8)
    val Ink = Color(0xFF0F172A)
    val Ink2 = Color(0xFF1E293B)
    val Muted = Color(0xFF334155)
    val Subtle = Color(0xFF475569)
    val Accent = Color(0xFF4F46E5)
    val AccentDark = Color(0xFF4338CA)
    val AccentSoft = Color(0x1A4F46E5)
    val Indigo = Color(0xFF818CF8)
    val Sky = Color(0xFF38BDF8)
    val Pink = Color(0xFFF472B6)
    val Green = Color(0xFF047857)
    val GreenSoft = Color(0x2610B981)
    val Orange = Color(0xFFC2410C)
    val OrangeSoft = Color(0x24EA580C)
    val Red = Color(0xFFB91C1C)
    val Glass = Color(0x8CFFFFFF)
    val GlassStrong = Color(0xD9FFFFFF)
    val GlassEdge = Color(0xBFFFFFFF)

    // Exam room (official IELTS white UI, web practice room)
    val ExamRed = Color(0xFFE11D48)
    val ExamBlue = Color(0xFF2563EB)
    val ExamLine = Color(0xFFD1D5DB)
    val ExamPanel = Color(0xFFF3F4F6)
    val ExamText = Color(0xFF111827)
    val ExamTimer = Color(0xFFDC2626)
}

private val Scheme = lightColorScheme(
    primary = Mn.Accent,
    onPrimary = Color.White,
    background = Mn.Bg,
    surface = Color.White,
    onSurface = Mn.Ink,
    onBackground = Mn.Ink,
    error = Mn.Red,
)

@Composable
fun MynineTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = Scheme, content = content)
}

/** Soft coloured orbs behind the glass (variant changes their placement per screen). */
@Composable
fun GlassBackground(variant: Int = 0, content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Mn.Bg)) {
        val spots = when (variant % 3) {
            0 -> listOf(Triple(Mn.Indigo, -90 to -110, 340), Triple(Mn.Sky, 220 to 280, 320), Triple(Mn.Pink, 20 to 620, 320))
            1 -> listOf(Triple(Mn.Indigo, 170 to -120, 340), Triple(Mn.Sky, -140 to 380, 320), Triple(Mn.Pink, 160 to 640, 300))
            else -> listOf(Triple(Mn.Pink, -60 to -90, 320), Triple(Mn.Indigo, 180 to -40, 320), Triple(Mn.Sky, 40 to 620, 300))
        }
        spots.forEach { (color, pos, size) ->
            Box(
                Modifier
                    .offset(pos.first.dp, pos.second.dp)
                    .size(size.dp)
                    .background(Brush.radialGradient(listOf(color.copy(alpha = 0.45f), color.copy(alpha = 0f))), CircleShape),
            )
        }
        content()
    }
}

fun Modifier.glass(shape: Shape = RoundedCornerShape(24.dp), strong: Boolean = false): Modifier =
    this
        .clip(shape)
        .background(if (strong) Mn.GlassStrong else Mn.Glass, shape)
        .border(BorderStroke(1.dp, Mn.GlassEdge), shape)

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    radius: Dp = 24.dp,
    padding: PaddingValues = PaddingValues(18.dp),
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(radius)
    Column(
        modifier
            .glass(shape)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(padding),
        content = content,
    )
}

@Composable
fun PrimaryButton(text: String, modifier: Modifier = Modifier, enabled: Boolean = true, loading: Boolean = false, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier.height(54.dp),
        shape = RoundedCornerShape(999.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Mn.Accent, contentColor = Color.White),
    ) {
        if (loading) CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
        else Text(text, fontSize = 16.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun SecondaryButton(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    painter: androidx.compose.ui.graphics.painter.Painter? = null,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.height(52.dp),
        shape = RoundedCornerShape(999.dp),
        border = BorderStroke(1.dp, Color(0xFFE2E8F0)),
        colors = ButtonDefaults.outlinedButtonColors(containerColor = Color.White, contentColor = Mn.Ink),
    ) {
        if (painter != null) {
            // Brand marks keep their own colours.
            androidx.compose.foundation.Image(painter, null, Modifier.size(20.dp))
            Spacer(Modifier.width(10.dp))
        } else if (icon != null) {
            Icon(icon, null, Modifier.size(20.dp))
            Spacer(Modifier.width(10.dp))
        }
        Text(text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
fun Pill(text: String, bg: Color = Color(0xD9FFFFFF), fg: Color = Mn.Ink2, modifier: Modifier = Modifier) {
    Text(
        text,
        modifier.clip(RoundedCornerShape(999.dp)).background(bg).padding(horizontal = 10.dp, vertical = 5.dp),
        style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = fg),
    )
}

@Composable
fun ScreenTitle(text: String, modifier: Modifier = Modifier) {
    Text(text, modifier, fontSize = 30.sp, fontWeight = FontWeight.ExtraBold, color = Mn.Ink, letterSpacing = (-0.6).sp)
}

@Composable
fun LoadingBox(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().padding(40.dp), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = Mn.Accent)
    }
}

@Composable
fun ErrorBox(message: String, onRetry: (() -> Unit)? = null) {
    GlassCard(Modifier.fillMaxWidth()) {
        Text(message, color = Mn.Muted, fontSize = 15.sp)
        if (onRetry != null) {
            Spacer(Modifier.height(12.dp))
            Text(
                str(R.string.retry),
                Modifier.clip(RoundedCornerShape(999.dp)).clickable(onClick = onRetry).padding(vertical = 6.dp),
                color = Mn.Accent,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

@Composable
fun SectionHeader(title: String, action: String? = null, onAction: (() -> Unit)? = null) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, Modifier.weight(1f), fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Mn.Ink)
        if (action != null && onAction != null) {
            Text(action, Modifier.clip(RoundedCornerShape(8.dp)).clickable(onClick = onAction).padding(4.dp), color = Mn.Accent, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

/** Band like "6.5" (whole bands as "7.0"), or "–". */
fun band(value: Double?): String = value?.let { String.format(java.util.Locale.US, "%.1f", it) } ?: "–"

/** "reading" → "Reading"; a module practice of several ("listening,reading") → "Listening · Reading". */
fun moduleTitle(type: String): String =
    if (',' in type) type.split(',').joinToString(" · ") { moduleTitle(it.trim()) } else singleModuleTitle(type)

private fun singleModuleTitle(type: String): String = when (type) {
    "listening" -> "Listening"
    "reading" -> "Reading"
    "writing" -> "Writing"
    "speaking" -> "Speaking"
    else -> type.replaceFirstChar { it.uppercase() }
}

fun minutes(seconds: Int): String {
    val m = (seconds + 59) / 60
    return when {
        m >= 60 && m % 60 > 0 -> str(R.string.hours_minutes, m / 60, m % 60)
        m >= 60 -> str(R.string.hours, m / 60)
        else -> str(R.string.minutes, m)
    }
}
