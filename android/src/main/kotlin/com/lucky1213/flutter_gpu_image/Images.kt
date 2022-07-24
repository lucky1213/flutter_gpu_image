package com.lucky1213.flutter_gpu_image

class Images private constructor() {
    companion object {
        private var instance: Images? = null
            get() {
                if (field == null) {
                    field = Images()
                }
                return field
            }
        //使用同步锁注解
        @Synchronized
        fun get(): Images{
            return instance!!
        }
    }

    private val images: HashMap<Long, ImageRequestManager> = HashMap()

    fun create(requestManager: ImageRequestManager) {
        images[requestManager.getTextureId()] = requestManager
    }

    fun get( id: Long): ImageRequestManager? {
        return images[id]
    }

    fun release( id: Long) {
        images.remove(id)
    }

    fun release(requestManager: ImageRequestManager) {
        release(requestManager.getTextureId())
    }

     fun release(id: Long, requestManager: ImageRequestManager) {
        release(id, requestManager)
    }
}