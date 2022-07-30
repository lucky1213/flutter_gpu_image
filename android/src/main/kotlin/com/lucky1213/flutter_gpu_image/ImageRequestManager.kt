package com.lucky1213.flutter_gpu_image

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.annotation.NonNull
import coil.ImageLoader
import coil.request.ErrorResult
import coil.request.ImageRequest
import coil.target.Target
import coil.transform.Transformation
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import jp.wasabeef.transformers.coil.gpu.BrightnessFilterTransformation
import jp.wasabeef.transformers.coil.gpu.ContrastFilterTransformation
import jp.wasabeef.transformers.coil.gpu.SharpenFilterTransformation
import jp.wasabeef.transformers.coil.gpu.SketchFilterTransformation
import java.io.ByteArrayOutputStream
import java.io.File

class ImageRequestManager(binding: FlutterPlugin.FlutterPluginBinding) : EventChannel.StreamHandler {
    private var textureRegistry: TextureRegistry
    private var eventChannel: EventChannel
    private var context : Context
    private var surfaceTextureEntry : TextureRegistry.SurfaceTextureEntry
    private var eventSink: EventChannel.EventSink? = null

    private var surface : Surface? = null
    private var loader: ImageLoader? = null
    private var request: ImageRequest.Builder? = null
    private var mainHandler: Handler? = null
    private var filter: List<HashMap<String, Any>>? = null

    init {
        prepare()
        context = binding.applicationContext
        textureRegistry = binding.textureRegistry
        surfaceTextureEntry = textureRegistry.createSurfaceTexture()
        eventChannel = EventChannel(binding.binaryMessenger,
            "flutter_gpu_image/listener_"+getTextureId()
        )
        eventChannel.setStreamHandler(this)

        loader = ImageLoader.Builder(context).build()

        request = ImageRequest.Builder(context)
        Images.get().create(this)
    }

    fun getTextureId(): Long {
        return surfaceTextureEntry.id()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

     fun startRequest(@NonNull call: MethodCall, @NonNull result: Result) {
        onProcess()

        val path = call.argument<String>("path")
        val bytes = call.argument<ByteArray>("bytes")

         if (path != null) {
             request!!.data(File(path))
        } else {
            // val base64 = "data:image/jpeg;base64," + Base64.encodeToString(bytes, Base64.DEFAULT)
             request!!.data(bytes)
            //ImageRequestBuilder.newBuilderWithSource(Uri.parse(base64))
        }

        if (call.method == "renderFromBytes" || call.method == "renderFromFile") {
            filter = call.argument<List<HashMap<String, Any>>>("filter")
        }

        // val request = setFilter(filter).build()
        transmitTexture(setFilter(filter), {
            onSuccess(it, result)
        }, {
            onFailure(result)
        })
    }

     fun updateFilter(@NonNull call: MethodCall, @NonNull result: Result) {
        onProcess()
        filter = call.argument<List<HashMap<String, Any>>>("filter")

        transmitTexture(setFilter(filter), {
            onSuccess(it, result)
        }, {
            onFailure(result)
        })
    }

    fun releaseRequest(@NonNull call: MethodCall, @NonNull result: Result) {
        runOnMainThread {
            if (eventSink != null) {
                eventSink!!.endOfStream()
            }
            eventChannel.setStreamHandler(null)
            Images.get().release(getTextureId())
            surfaceTextureEntry.release()
            if (surface != null) {
                surface!!.release()
                surface = null
            }

        }
    }

    private fun onProcess() {
        eventSink?.success(hashMapOf<String, Any?>(
            "state" to 0,
        ))
    }

    private fun onSuccess(bitmap: Bitmap, @NonNull result: MethodChannel.Result) {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)

        val imageInfo = hashMapOf<String, Any?>(
            "width" to bitmap.width,
            "height" to bitmap.height,
            "texture_id" to getTextureId(),
            "bytes" to outputStream.toByteArray()
        )
        val data = hashMapOf<String, Any?>(
            "state" to 1,
            "image_info" to imageInfo,
        )
        eventSink?.success(data)
        result.success(data)
    }

    private fun onFailure(@NonNull result: MethodChannel.Result) {
        eventSink?.error("1001", "render image failed", null)
        result.error("1001", "render image failed", null)
    }

    private fun setFilter(filter: List<HashMap<String, Any>>?) : ImageRequest.Builder {
        val transformations = mutableListOf<Transformation>()

        filter?.forEach {
            when (it["type"] as String) {
                "brightness" -> {
                    val value = it["value"] as Double
                    transformations.add(BrightnessFilterTransformation(context, value.toFloat()))
                }
                "contrast" -> {
                    val value = it["value"] as Double
                    transformations.add(ContrastFilterTransformation(context, value.toFloat()))
                }
                "sharpen" -> {
                    val value = it["value"] as Double
                    transformations.add(SharpenFilterTransformation(context, value.toFloat()))
                }
                "gray_scale" -> {
                    transformations.add(GrayScaleFilterTransformation(context))
                }
                "highlight_shadow" -> {
                    val value = it["value"] as Double
                    transformations.add(HighlightShadowFilterTransformation(context, value.toFloat()))
                }
                "gaussian_blur" -> {
                    val value = it["value"] as Double
                    transformations.add(GaussianBlurFilterTransformation(context, value.toFloat()))
                }
                "black_white" -> {
                    transformations.add(BlackWhiteFilterTransformation(context))
                }
                "sobel_edge_detection" -> {
                    val value = it["value"] as Double
                    transformations.add(SobelEdgeDetectionFilterTransformation(context, value.toFloat()))
                }
                "sketch" -> {
                    val value = it["value"] as Double
                    transformations.add(SketchFilterTransformation(context))
                }
            }
        }
        if (transformations.isNotEmpty()) {
            request!!.transformations(transformations)
        } else {
            request!!.allowHardware(false)
        }

        return request!!
    }

    private fun rebuild(bitmap: Bitmap): Bitmap {
        if (surface != null) {
            surface!!.release()
            surface = null
        }
        if (surface == null) {
            surface = Surface(surfaceTextureEntry.surfaceTexture())
        }
        surfaceTextureEntry.surfaceTexture().setDefaultBufferSize(bitmap.width, bitmap.height)
        if (surface != null && surface!!.isValid) {
            val rect = Rect(0, 0, bitmap.width, bitmap.height)
            val canvas = surface!!.lockCanvas(null)
            canvas!!.drawBitmap(bitmap, null, rect, null)
            surface!!.unlockCanvasAndPost(canvas)
            // bitmap.recycle()
        }
        return bitmap
    }

    private fun transmitTexture(request: ImageRequest.Builder, onSuccess: ((bitmap: Bitmap) -> Unit)?, onFailure: ((error: Drawable?) -> Unit)?) {

        request.target(object : Target{
            override fun onSuccess(result: Drawable) {
                runOnMainThread {
                    val image = rebuild((result as BitmapDrawable).bitmap)
                    if (onSuccess != null) {
                        onSuccess(image)
                    }
                }
            }

            override fun onError(error: Drawable?) {
                runOnMainThread {
                    if (onFailure != null) {
                        onFailure(error)
                    }
                }
            }
        })

        request.listener(object: ImageRequest.Listener{
            override fun onError(request: ImageRequest, result: ErrorResult) {
                super.onError(request, result)
            }
        })
        loader!!.enqueue(request.build())
    }

    private fun prepare() {
        mainHandler = Handler(Looper.getMainLooper())
    }

    private fun runOnMainThread(runnable: Runnable?) {
        if (runnable == null || mainHandler == null) {
            return
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run()
            return
        }
        mainHandler!!.post(runnable)
    }
}