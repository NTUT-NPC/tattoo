package club.ntut.tattoo

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import club.ntut.tattoo.campuswifi.CampusWifiChannelHandler
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private val campusWifiChannelHandler by lazy { CampusWifiChannelHandler(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        campusWifiChannelHandler.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
