package com.redbeak.audio_engine

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** AudioEnginePlugin */
class AudioEnginePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var engine: Engine? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "audio_engine")
    channel.setMethodCallHandler(this)
    engine = Engine(context)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val e = engine ?: return result.error("engine", "Not initialized", null)

    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android " + android.os.Build.VERSION.RELEASE)
      }
      // track lifecycle
      "createTrack" -> {
        val uri = call.argument<String>("uri") ?: return result.error("arg","uri required",null)
        val id = e.createTrack(uri)
        result.success(id)
      }
      "disposeTrack" -> {
        e.disposeTrack(call.argInt("id"))
        result.success(null)
      }

      // params
      "setGain"  -> { e.setGain(call.argInt("id"), call.argDouble("v")); result.success(null) }
      "setSpeed" -> { e.setSpeed(call.argInt("id"), call.argDouble("v")); result.success(null) }
      "setPitch" -> { e.setPitch(call.argInt("id"), call.argDouble("v")); result.success(null) }
      "setPan"   -> { e.setPan(call.argInt("id"), call.argDouble("v")); result.success(null) }

      // transport
      "start"    -> { e.start(call.argInt("id"), call.argLong("offsetMs")); result.success(null) }
      "stop"     -> { e.stop(call.argInt("id")); result.success(null) }
      "startAll" -> {
        @Suppress("UNCHECKED_CAST")
        val map = (call.argument<Map<String, Any>>("offsets") ?: emptyMap())
          .mapKeys { it.key.toInt() }
          .mapValues { (it.value as Number).toLong() }
        e.startAll(map)
        result.success(null)
      }
      "stopAll"  -> { e.stopAll(); result.success(null) }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    engine?.release()
    engine = null
  }

  // small helpers
  private fun MethodCall.argInt(key: String) = (argument<Number>(key) ?: 0).toInt()
  private fun MethodCall.argLong(key: String) = (argument<Number>(key) ?: 0L).toLong()
  private fun MethodCall.argDouble(key: String) = (argument<Number>(key) ?: 0.0).toDouble()
}