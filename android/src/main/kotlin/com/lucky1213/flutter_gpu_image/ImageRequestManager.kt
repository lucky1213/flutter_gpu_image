package com.lucky1213.flutter_gpu_image

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.view.Surface
import androidx.annotation.NonNull
import com.facebook.common.executors.CallerThreadExecutor
import com.facebook.common.references.CloseableReference
import com.facebook.datasource.DataSource
import com.facebook.drawee.backends.pipeline.Fresco
import com.facebook.imagepipeline.core.ImagePipeline
import com.facebook.imagepipeline.datasource.BaseBitmapDataSubscriber
import com.facebook.imagepipeline.image.CloseableImage
import com.facebook.imagepipeline.request.ImageRequest
import com.facebook.imagepipeline.request.ImageRequestBuilder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import jp.wasabeef.transformers.fresco.gpu.BrightnessFilterPostprocessor
import jp.wasabeef.transformers.fresco.gpu.ContrastFilterPostprocessor
import java.io.ByteArrayOutputStream
import java.io.File

class ImageRequestManager(binding: FlutterPlugin.FlutterPluginBinding) : EventChannel.StreamHandler {
    private var textureRegistry: TextureRegistry
    private var eventChannel: EventChannel
    private var imagePipeline : ImagePipeline
    private var context : Context
    private var surfaceTextureEntry : TextureRegistry.SurfaceTextureEntry
    private var eventSink: EventChannel.EventSink? = null

    private var surface : Surface? = null
    private var builder: ImageRequestBuilder? = null
    private var mainHandler: Handler? = null
    private var filter: HashMap<String, Any>? = null

    init {
        prepare()
        context = binding.applicationContext
        textureRegistry = binding.textureRegistry
        surfaceTextureEntry = textureRegistry.createSurfaceTexture()
        eventChannel = EventChannel(binding.binaryMessenger,
            "flutter_gpu_image/listener_"+getTextureId()
        )
        eventChannel.setStreamHandler(this)
        imagePipeline = Fresco.getImagePipeline()

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

        builder = if (path != null) {
            ImageRequestBuilder.newBuilderWithSource(Uri.fromFile(File(path)))
        } else {
            val base64 = "data:image/jpeg;base64," + Base64.encodeToString(bytes, Base64.DEFAULT)
            ImageRequestBuilder.newBuilderWithSource(Uri.parse(base64))
        }

        builder!!.isProgressiveRenderingEnabled = false

        if (call.method == "renderFromBytes" || call.method == "renderFromFile") {
            filter = call.argument<HashMap<String, Any>?>("filter")
        }

        val request = setFilter(filter).build()

        transmitTexture(request, {
            onSuccess(it, result)
        }, {
            onFailure(result)
        })
    }

     fun updateFilter(@NonNull call: MethodCall, @NonNull result: Result) {
        onProcess()
        filter = call.argument<HashMap<String, Any>?>("filter")
        val request: ImageRequest = setFilter(filter).build()

        transmitTexture(request, {
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

    private fun setFilter(filter: HashMap<String, Any>?) : ImageRequestBuilder {
        val type = filter?.get("type") as String?
        builder!!.postprocessor = null
        if (type == "brightness") {
            val value = filter!!["value"] as Double
            builder!!.postprocessor = BrightnessFilterPostprocessor(context, value.toFloat())
        } else if (type == "contrast") {
            val value = filter!!["value"] as Double
            builder!!.postprocessor = ContrastFilterPostprocessor(context, value.toFloat())
        }
        return builder!!
    }

    private fun rebuild(bitmap: Bitmap): Bitmap {
        if (surface != null) {
            surface!!.release()
            surface = null
        }
        if (surface == null) {
            surface = Surface(surfaceTextureEntry!!.surfaceTexture())
        }
        surfaceTextureEntry!!.surfaceTexture().setDefaultBufferSize(bitmap.width, bitmap.height)
        if (surface != null && surface!!.isValid) {
            val rect = Rect(0, 0, bitmap.width, bitmap.height)
            val canvas = surface!!.lockCanvas(null)
            canvas!!.drawBitmap(bitmap, null, rect, null)
            surface!!.unlockCanvasAndPost(canvas)
            // bitmap.recycle()
        }
        return bitmap
    }

    private fun transmitTexture(request: ImageRequest, onSuccess: ((bitmap: Bitmap) -> Unit)?, onFailure: ((dataSource : DataSource<CloseableReference<CloseableImage>>) -> Unit)?) {
        val dataSource = imagePipeline.fetchDecodedImage(request, context)
        dataSource.subscribe(
            object : BaseBitmapDataSubscriber() {
                override fun onNewResultImpl(bitmap: Bitmap?) {
                    runOnMainThread {
                        if (bitmap != null) {
                            val image = rebuild(bitmap)
                            if (onSuccess != null) {
                                onSuccess(image)
                            }
                        } else {
                            onFailureImpl(dataSource)
                        }
                    }
                }
                override fun onFailureImpl(dataSource : DataSource<CloseableReference<CloseableImage>>) {
                    if (onFailure != null) {
                        onFailure(dataSource)
                    }
                }
            },
            CallerThreadExecutor.getInstance()
        )
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