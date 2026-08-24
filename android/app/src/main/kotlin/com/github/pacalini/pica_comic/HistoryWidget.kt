package com.github.pacalini.pica_comic

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream

// 与 Flutter 侧 AndroidWidgetService 的通道名保持一致
const val ANDROID_WIDGET_CHANNEL = "pica_comic/android_widget"

// 点击小组件后放入 Intent extra 的 key，Flutter 侧通过它解析 action
const val WIDGET_ACTION_EXTRA = "widget_action"

private val widgetActionKey = ActionParameters.Key<String>(WIDGET_ACTION_EXTRA)

// 小组件固定深色配色（day/night 保持一致，避免亮色主题下突兀）
private val widgetBackground = ColorProvider(day = Color(0xFF202124), night = Color(0xFF202124))
private val widgetTextPrimary = ColorProvider(day = Color.White, night = Color.White)
private val widgetTextSecondary = ColorProvider(day = Color(0xFF9AA0A6), night = Color(0xFF9AA0A6))
private val widgetTextTertiary = ColorProvider(day = Color(0xFF70757A), night = Color(0xFF70757A))
private val widgetCoverPlaceholder = ColorProvider(day = Color(0xFF3A3A3A), night = Color(0xFF3A3A3A))

/** 通过点击小组件启动 MainActivity 的广播接收器。 */
class HistoryWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = HistoryWidget()
}

class HistoryWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val items = withContext(Dispatchers.IO) {
            WidgetDataStore.loadHistoryItems(context)
        }
        provideContent {
            HistoryWidgetContent(items)
        }
    }

    @Composable
    private fun HistoryWidgetContent(items: List<HistoryItem>) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(widgetBackground)
                .padding(12.dp),
        ) {
            Text(
                text = "最近阅读",
                style = TextStyle(color = widgetTextPrimary, fontSize = 14.sp),
            )
            Spacer(modifier = GlanceModifier.height(8.dp))
            if (items.isEmpty()) {
                Text(
                    text = "暂无阅读记录",
                    style = TextStyle(color = widgetTextSecondary, fontSize = 12.sp),
                )
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                    items(items) { item ->
                        HistoryRow(item)
                    }
                }
            }
        }
    }

    @Composable
    private fun HistoryRow(item: HistoryItem) {
        val context = LocalContext.current
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val params = actionParametersOf(
            widgetActionKey to buildReaderPayload(item),
        )
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
                .clickable(actionStartActivity(intent, params)),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val cover = item.cover
            if (cover != null) {
                Image(
                    provider = ImageProvider(cover),
                    contentDescription = null,
                    modifier = GlanceModifier.width(36.dp).height(48.dp),
                )
            } else {
                Spacer(
                    modifier = GlanceModifier
                        .width(36.dp)
                        .height(48.dp)
                        .background(widgetCoverPlaceholder),
                )
            }
            Spacer(modifier = GlanceModifier.width(8.dp))
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                Text(
                    text = item.title,
                    maxLines = 1,
                    style = TextStyle(color = widgetTextPrimary, fontSize = 13.sp),
                )
                if (item.progress.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Text(
                        text = item.progress,
                        maxLines = 1,
                        style = TextStyle(color = widgetTextSecondary, fontSize = 11.sp),
                    )
                }
                if (item.time.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(1.dp))
                    Text(
                        text = item.time,
                        maxLines = 1,
                        style = TextStyle(color = widgetTextTertiary, fontSize = 10.sp),
                    )
                }
            }
        }
    }

    private fun buildReaderPayload(item: HistoryItem): String {
        return JSONObject().apply {
            put("action", "open_reader")
            put("type", item.type)
            put("target", item.target)
            put("ep", item.ep)
            put("page", item.page)
        }.toString()
    }
}

/** 最近阅读条目，封面已经被解码成 [Bitmap] 方便直接渲染。 */
data class HistoryItem(
    val title: String,
    val progress: String,
    val time: String,
    val cover: Bitmap?,
    val target: String,
    val type: Int,
    val ep: Int,
    val page: Int,
)

/** 负责把 Flutter 传来的快照落地到本地文件与 SharedPreferences。 */
object WidgetDataStore {
    private const val PREFS = "pica_widget"
    private const val KEY_SNAPSHOT = "history_snapshot"
    private const val COVER_DIR = "widget_covers"

    fun saveSnapshot(context: Context, snapshotJson: String) {
        val arr = try {
            JSONArray(snapshotJson)
        } catch (_: Exception) {
            return
        }
        val coverDir = File(context.filesDir, COVER_DIR)
        coverDir.mkdirs()

        val out = JSONArray()
        for (i in 0 until arr.length()) {
            val src = arr.optJSONObject(i) ?: continue
            val type = src.optInt("type")
            val target = src.optString("target")
            val cover = src.optString("cover")
            val coverFile = saveCover(coverDir, type, target, cover)

            out.put(
                JSONObject().apply {
                    put("title", src.optString("title"))
                    put("progress", src.optString("progress"))
                    put("time", src.optString("time"))
                    put("target", target)
                    put("type", type)
                    put("ep", src.optInt("ep"))
                    put("page", src.optInt("page"))
                    put("coverFile", coverFile ?: "")
                },
            )
        }

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SNAPSHOT, out.toString())
            .apply()
    }

    private fun saveCover(
        dir: File,
        type: Int,
        target: String,
        dataUri: String,
    ): String? {
        if (target.isEmpty() || !dataUri.startsWith("data:image")) {
            return null
        }
        return try {
            val comma = dataUri.indexOf(',')
            if (comma < 0) {
                return null
            }
            val bytes = Base64.decode(dataUri.substring(comma + 1), Base64.DEFAULT)
            val name = sanitizeFileName(target).take(100)
            val file = File(dir, "${type}_$name.jpg")
            FileOutputStream(file).use { it.write(bytes) }
            file.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun sanitizeFileName(value: String): String {
        return value.replace(Regex("[^A-Za-z0-9_-]"), "_")
    }

    fun loadHistoryItems(context: Context): List<HistoryItem> {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SNAPSHOT, null) ?: return emptyList()
        val arr = try {
            JSONArray(json)
        } catch (_: Exception) {
            return emptyList()
        }
        val list = ArrayList<HistoryItem>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val coverFile = o.optString("coverFile")
            val bitmap = if (coverFile.isNotEmpty()) {
                BitmapFactory.decodeFile(coverFile)
            } else {
                null
            }
            list.add(
                HistoryItem(
                    title = o.optString("title"),
                    progress = o.optString("progress"),
                    time = o.optString("time"),
                    cover = bitmap,
                    target = o.optString("target"),
                    type = o.optInt("type"),
                    ep = o.optInt("ep"),
                    page = o.optInt("page"),
                ),
            )
        }
        return list
    }
}