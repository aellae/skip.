package com.skip.finance

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Home-screen icon follows the active aesthetic via activity-aliases
/// (`.MainActivityMinimal` / `.MainActivityY2K` in AndroidManifest.xml),
/// toggled here to mirror the iOS alternate-icon channel of the same name.
///
/// Disabling the alias the task was launched from makes Android close the
/// app on the spot, so a requested swap is only recorded here and applied
/// once the user leaves the app.
class MainActivity : FlutterActivity() {
    private val appIconChannelName = "skip/app_icon"

    /// Icon to switch to when the user leaves the app; `null` = nothing pending.
    private var pendingIsY2K: Boolean? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appIconChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "setAlternateIconName") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val iconName = call.argument<String>("iconName")
                pendingIsY2K = iconName == "AppIcon-Y2K"
                result.success(null)
            }
    }

    /// Set while an activity this app started (camera, photo picker,
    /// product link) is on top, where closing the task would lose the
    /// user's in-progress entry.
    private var isShowingOwnActivity = false

    /// Activity.startActivity funnels through here too, so this catches every
    /// plugin launch (image_picker, url_launcher).
    override fun startActivityForResult(intent: Intent, requestCode: Int, options: Bundle?) {
        isShowingOwnActivity = true
        super.startActivityForResult(intent, requestCode, options)
    }

    override fun onResume() {
        super.onResume()
        isShowingOwnActivity = false
    }

    /// Home/Recents, but also fires when the app starts its own activities,
    /// hence the isShowingOwnActivity check.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (!isShowingOwnActivity) applyPendingLauncherIcon()
    }

    /// Backing out of the app skips onUserLeaveHint.
    override fun onDestroy() {
        if (isFinishing) applyPendingLauncherIcon()
        super.onDestroy()
    }

    private fun applyPendingLauncherIcon() {
        val isY2K = pendingIsY2K ?: return
        pendingIsY2K = null
        setLauncherIcon(isY2K)
    }

    private fun setLauncherIcon(isY2K: Boolean) {
        val pm = applicationContext.packageManager
        val minimalAlias = ComponentName(applicationContext, "$packageName.MainActivityMinimal")
        val y2kAlias = ComponentName(applicationContext, "$packageName.MainActivityY2K")

        // The Y2K alias is disabled in the manifest, so only an explicit
        // ENABLED means it's the live icon. Skipping a no-op swap spares the
        // launcher a needless refresh (ThemeProvider re-requests the icon on
        // every launch).
        val isY2KActive =
            pm.getComponentEnabledSetting(y2kAlias) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        if (isY2KActive == isY2K) return

        val (enabled, disabled) = if (isY2K) {
            y2kAlias to minimalAlias
        } else {
            minimalAlias to y2kAlias
        }

        // DONT_KILL_APP keeps the process alive, so returning to the app
        // from Recents doesn't cold-start it.
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
