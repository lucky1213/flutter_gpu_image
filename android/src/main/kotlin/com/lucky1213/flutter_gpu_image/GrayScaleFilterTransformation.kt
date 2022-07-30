package com.lucky1213.flutter_gpu_image

import android.content.Context
import jp.co.cyberagent.android.gpuimage.filter.GPUImageGrayscaleFilter
import jp.wasabeef.transformers.coil.gpu.GPUFilterTransformation

class GrayScaleFilterTransformation constructor(
    context: Context,
) : GPUFilterTransformation(
    context,
    GPUImageGrayscaleFilter()
) {

    override val cacheKey: String get() = "$id(GrayScale)"
}