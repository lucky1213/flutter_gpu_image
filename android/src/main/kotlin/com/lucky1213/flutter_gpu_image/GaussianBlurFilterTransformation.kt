package com.lucky1213.flutter_gpu_image

import android.content.Context
import jp.co.cyberagent.android.gpuimage.filter.GPUImageGaussianBlurFilter
import jp.wasabeef.transformers.coil.gpu.GPUFilterTransformation

class GaussianBlurFilterTransformation @JvmOverloads constructor(
    context: Context,
    private val blurSize: Float = 0.0f,
) : GPUFilterTransformation(
    context,
    GPUImageGaussianBlurFilter().apply {
        setBlurSize(blurSize)
    }
) {

    override val cacheKey: String get() = "$id(blurSize=$blurSize)"
}