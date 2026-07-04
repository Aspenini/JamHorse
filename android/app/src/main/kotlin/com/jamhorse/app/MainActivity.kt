package com.jamhorse.app

import android.content.Intent
import android.media.audiofx.AudioEffect
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.jamhorse.app/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapabilities" -> {
                        val equalizer = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
                            .resolveActivity(packageManager) != null
                        result.success(
                            mapOf(
                                "airPlay" to false,
                                "equalizer" to equalizer,
                                "automotive" to true,
                                "desktopMediaKeys" to false,
                            ),
                        )
                    }

                    "showEqualizer" -> {
                        val sessionId = call.argument<Int>("audioSessionId")
                        if (sessionId == null) {
                            result.error(
                                "NO_AUDIO_SESSION",
                                "Start playback before opening audio effects.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
                            putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                        }
                        if (intent.resolveActivity(packageManager) == null) {
                            result.error(
                                "NOT_SUPPORTED",
                                "This device does not provide an audio-effects panel.",
                                null,
                            )
                        } else {
                            startActivity(intent)
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
