package club.ntut.npc.tat.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Icon
import android.os.Build
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import club.ntut.npc.tat.MainActivity
import club.ntut.npc.tat.R

class CourseTableWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        update(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        private const val OPEN_REQUEST_CODE = 436

        fun updateAll(context: Context) {
            val appContext = context.applicationContext
            val manager = AppWidgetManager.getInstance(appContext)
            val component = ComponentName(appContext, CourseTableWidgetProvider::class.java)
            update(appContext, manager, manager.getAppWidgetIds(component))
        }

        private fun update(
            context: Context,
            manager: AppWidgetManager,
            widgetIds: IntArray,
        ) {
            val storage = CourseWidgetStorage(context)
            val lightBitmap = decodeWidgetBitmap(storage.imageFile(dark = false))
            val darkBitmap = decodeWidgetBitmap(storage.imageFile(dark = true))
            val pendingIntent = PendingIntent.getActivity(
                context,
                OPEN_REQUEST_CODE,
                Intent(context, MainActivity::class.java).apply {
                    action = CourseWidgetChannelHandler.OPEN_COURSE_TABLE_ACTION
                    putExtra(
                        CourseWidgetChannelHandler.WIDGET_ROUTE_EXTRA,
                        CourseWidgetChannelHandler.COURSE_TABLE_ROUTE,
                    )
                    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            for (widgetId in widgetIds) {
                val views = if (lightBitmap == null || darkBitmap == null) {
                    RemoteViews(
                        context.packageName,
                        R.layout.course_table_widget_fallback,
                    ).also {
                        it.setTextViewText(
                            R.id.course_widget_setup_hint,
                            context.getString(
                                R.string.course_widget_setup_hint,
                                context.getString(R.string.app_name),
                            ),
                        )
                    }
                } else {
                    RemoteViews(context.packageName, R.layout.course_table_widget).also {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val lightIcon = Icon.createWithBitmap(lightBitmap)
                            val darkIcon = Icon.createWithBitmap(darkBitmap)
                            for (
                                imageId in
                                    intArrayOf(
                                        R.id.course_widget_image_light,
                                        R.id.course_widget_image_dark,
                                    )
                            ) {
                                it.setIcon(
                                    imageId,
                                    "setImageIcon",
                                    lightIcon,
                                    darkIcon,
                                )
                                it.setColorInt(
                                    imageId,
                                    "setBackgroundColor",
                                    lightBitmap.getPixel(0, 0),
                                    darkBitmap.getPixel(0, 0),
                                )
                            }
                        } else {
                            it.setInt(
                                R.id.course_widget_image_light,
                                "setBackgroundColor",
                                lightBitmap.getPixel(0, 0),
                            )
                            it.setImageViewBitmap(
                                R.id.course_widget_image_light,
                                lightBitmap,
                            )
                            it.setInt(
                                R.id.course_widget_image_dark,
                                "setBackgroundColor",
                                darkBitmap.getPixel(0, 0),
                            )
                            it.setImageViewBitmap(
                                R.id.course_widget_image_dark,
                                darkBitmap,
                            )
                        }
                    }
                }
                views.setOnClickPendingIntent(R.id.course_widget_root, pendingIntent)
                manager.updateAppWidget(widgetId, views)
            }
        }

        private fun decodeWidgetBitmap(imageFile: java.io.File?): Bitmap? {
            if (imageFile?.isFile != true) return null
            return try {
                val decoded = BitmapFactory.decodeFile(imageFile.absolutePath) ?: return null
                if (decoded.config == Bitmap.Config.RGB_565) {
                    decoded
                } else {
                    decoded.copy(Bitmap.Config.RGB_565, false).also { decoded.recycle() }
                }
            } catch (_: RuntimeException) {
                null
            }
        }
    }
}
