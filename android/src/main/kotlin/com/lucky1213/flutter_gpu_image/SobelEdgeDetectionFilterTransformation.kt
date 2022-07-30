package com.lucky1213.flutter_gpu_image

import android.content.Context
import jp.co.cyberagent.android.gpuimage.filter.GPUImageSobelEdgeDetectionFilter
import jp.wasabeef.transformers.coil.gpu.GPUFilterTransformation

class SobelEdgeDetectionFilterTransformation @JvmOverloads constructor(
    context: Context,
    private val size: Float = 1.0f,
) : GPUFilterTransformation(
    context,
    GPUImageSobelEdgeDetectionFilter().apply {
        setLineSize(size)
    }
) {

    override val cacheKey: String get() = "$id(size=$size)"
}