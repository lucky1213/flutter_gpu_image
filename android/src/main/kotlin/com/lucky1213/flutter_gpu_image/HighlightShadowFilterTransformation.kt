package com.lucky1213.flutter_gpu_image

import android.content.Context
import jp.co.cyberagent.android.gpuimage.filter.GPUImageHighlightShadowFilter
import jp.wasabeef.transformers.coil.gpu.GPUFilterTransformation

class HighlightShadowFilterTransformation @JvmOverloads constructor(
    context: Context,
    private val shadow: Float = 0.0f,
) : GPUFilterTransformation(
    context,
    GPUImageHighlightShadowFilter().apply {
        setHighlights(1 - shadow)
        setShadows(shadow)
    }
) {

    override val cacheKey: String get() = "$id(shadow=$shadow)"
}