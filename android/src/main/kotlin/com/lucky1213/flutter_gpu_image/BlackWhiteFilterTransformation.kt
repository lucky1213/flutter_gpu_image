package com.lucky1213.flutter_gpu_image

import android.content.Context
import android.opengl.GLES20
import jp.co.cyberagent.android.gpuimage.filter.GPUImageFilter
import jp.co.cyberagent.android.gpuimage.filter.GPUImageLuminanceThresholdFilter
import jp.wasabeef.transformers.coil.gpu.GPUFilterTransformation


class BlackWhiteFilterTransformation @JvmOverloads constructor(
    context: Context,
    private val threshold: Float = 0.1f,
) : GPUFilterTransformation(
    context,
    GPUImageLuminanceThresholdFilter(0.285f)
) {

    override val cacheKey: String get() = "$id(threshold=threshold)"
}

class GPUImageAdaptiveThresholdFilter @JvmOverloads constructor(private var threshold: Float = 0.5f) :
    GPUImageFilter(
        NO_FILTER_VERTEX_SHADER,
        LUMINANCE_THRESHOLD_FRAGMENT_SHADER
    ) {
    private var uniformThresholdLocation = 0
    override fun onInit() {
        super.onInit()
        uniformThresholdLocation = GLES20.glGetUniformLocation(program, "threshold")
    }

    override fun onInitialized() {
        super.onInitialized()
        setThreshold(threshold)
    }

    fun setThreshold(threshold: Float) {
        this.threshold = threshold
        setFloat(uniformThresholdLocation, threshold)
    }

    companion object {
        const val LUMINANCE_THRESHOLD_FRAGMENT_SHADER = "" +
                "varying highp vec2 textureCoordinate;\n" +
                "\n" +
                "uniform sampler2D inputImageTexture;\n" +
                "uniform highp float threshold;\n" +
                "\n" +
                "const highp vec3 W = vec3(0.5225, 0.7154, 0.1021);\n" +
                "\n" +
                "void main()\n" +
                "{\n" +
                "    highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\n" +
                "    highp float luminance = dot(textureColor.rgb, W);\n" +
                "    highp float thresholdResult = step(threshold, luminance);\n" +
                "    \n" +
                "    gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);\n" +
                "}"
    }
}

