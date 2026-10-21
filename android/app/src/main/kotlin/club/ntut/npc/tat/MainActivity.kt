package club.ntut.npc.tat

import android.content.Intent
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import club.ntut.npc.tat.campuswifi.CampusWifiChannelHandler
import club.ntut.npc.tat.widget.CourseWidgetChannelHandler
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private val campusWifiChannelHandler by lazy { CampusWifiChannelHandler(this) }
    private val systemSettingsChannelHandler by lazy { SystemSettingsChannelHandler(this) }
    private val courseWidgetChannelHandler by lazy { CourseWidgetChannelHandler(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        courseWidgetChannelHandler.handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        courseWidgetChannelHandler.handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        campusWifiChannelHandler.register(flutterEngine.dartExecutor.binaryMessenger)
        systemSettingsChannelHandler.register(flutterEngine.dartExecutor.binaryMessenger)
        courseWidgetChannelHandler.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
