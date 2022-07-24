package com.lucky1213.flutter_gpu_image

import androidx.annotation.NonNull
import com.facebook.drawee.backends.pipeline.Fresco
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** FlutterGpuImagePlugin */
class FlutterGpuImagePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var binding: FlutterPlugin.FlutterPluginBinding


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    binding = flutterPluginBinding
    channel = MethodChannel(binding.binaryMessenger, "flutter_gpu_image")
    channel.setMethodCallHandler(this)

    if (!Fresco.hasBeenInitialized()) {
      Fresco.initialize(binding.applicationContext)
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        val requestManager = ImageRequestManager(binding)
        result.success(requestManager.getTextureId())
      }
      "renderFromFile", "setImageFromFile", "renderFromBytes", "setImageFromBytes" -> {
        val requestManager = getRequestManager(call, result) ?: return
        requestManager.startRequest(call, result)
      }
      "setFilter" -> {
        val requestManager = getRequestManager(call, result) ?: return
        requestManager.updateFilter(call, result)
      }
      "dispose" -> {
        val requestManager = getRequestManager(call, result) ?: return
        requestManager.releaseRequest(call, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getRequestManager(@NonNull call: MethodCall, @NonNull result: Result) : ImageRequestManager? {
    val id = call.argument<Long>("id")!!
    val requestManager = Images.get().get(id)
    if (requestManager == null) {
      result.error("1003", "Not initialized", null)
    }
    return requestManager
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}