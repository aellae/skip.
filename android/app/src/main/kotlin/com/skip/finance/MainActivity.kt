package com.skip.finance

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Home-screen icon follows the active aesthetic via activity-aliases
/// (`.MainActivityMinimal` / `.MainActivityY2K` in AndroidManifest.xml),
/// toggled here to mirror the iOS alternate-icon channel of the same name.
class MainActivity : FlutterActivity() {
    private val appIconChannelName = "skip/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appIconChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "setAlternateIconName") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val iconName = call.argument<String>("iconName")
                setLauncherIcon(isY2K = iconName == "AppIcon-Y2K")
                result.success(null)
            }
    }

    private fun setLauncherIcon(isY2K: Boolean) {
        val pm = applicationContext.packageManager
        val minimalAlias = ComponentName(applicationContext, "$packageName.MainActivityMinimal")
        val y2kAlias = ComponentName(applicationContext, "$packageName.MainActivityY2K")

        val (enabled, disabled) = if (isY2K) {
            y2kAlias to minimalAlias
        } else {
            minimalAlias to y2kAlias
        }

        // DONT_KILL_APP avoids restarting the running process, matching the
        // seamless in-app swap iOS's setAlternateIconName provides.
        pm.setComponentEnabledSetting(
            enabled,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
        pm.setComponentEnabledSetting(
            disabled,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}
