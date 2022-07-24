import BBMetalImage
import Flutter
import UIKit

public class SwiftFlutterGpuImagePlugin: NSObject, FlutterPlugin {
    let textureRegistry: FlutterTextureRegistry
    var textureId: Int64?
    let registrar: FlutterPluginRegistrar
    var imageSource: BBMetalStaticImageSource?
    var lastFilter: BBMetalBaseFilter?
    var texture: MetalTexture?
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        self.textureRegistry = registrar.textures()
        texture = MetalTexture()
        textureId = textureRegistry.register(texture!)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_gpu_image", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterGpuImagePlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var dict: NSDictionary?
        if call.arguments != nil {
            dict = (call.arguments as! NSDictionary)
        }
        switch call.method {
            case "render":
                let path: String = dict!.value(forKey: "path") as! String
                let filter: Array<NSDictionary> = dict!.value(forKey: "filter") as? Array ?? []
                render(result: result, path: path, filter: filter, width: 0, height: 0)
            case "setImage":
                let path: String = dict!.value(forKey: "path") as! String
                setImage(result: result, path: path)
            case "setFilter":
                let filter: Array<NSDictionary> = dict!.value(forKey: "filter") as? Array ?? []
                setFilter(result: result, filter: filter)
            case "dispose":
//          let textureId: Int64 = (dict!.value(forKey: "textureId") as! NSNumber).int64Value
                DispatchQueue.main.async {
                    if self.textureId != nil {
                        self.textureRegistry.unregisterTexture(self.textureId!)
                        self.imageSource = nil
                        self.texture = nil
                    } else {
                        result(FlutterError(code: "texture id does not exist", message: "纹理不存在", details: nil))
                    }
                }
          
                result(true)
            default:
                result(FlutterError(code: "NoImplemented", message: "Handles a call to an unimplemented method.", details: nil))
        }
    }
    
    private func render(result: @escaping FlutterResult, path: String, filter: Array<NSDictionary>, width _: Double, height _: Double) {
        let originalData: Data
        do {
            originalData = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            result(FlutterError(code: "Create Error", message: "Cannot load image data.", details: nil))
            return
        }
        
        // Set up image source
        imageSource = BBMetalStaticImageSource(imageData: originalData)
        
        print(filter)

        lastFilter = imageSource!.addAll(filter: filter)
        transmitTexture(result, initialize: true)
    }
    
    private func setImage(result: @escaping FlutterResult, path: String) {
        if (imageSource == nil) {
            return
        }
        let originalData: Data
        do {
            originalData = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            return
        }
        imageSource!.update(originalData)
        transmitTexture(result)
    }
    
    private func setFilter(result: @escaping FlutterResult, filter: Array<NSDictionary>) {
        if (imageSource == nil) {
            return
        }
        imageSource!.removeAllConsumers()
        lastFilter = imageSource!.addAll(filter: filter)
        transmitTexture(result)
    }
    
    private func transmitTexture(_ result: @escaping FlutterResult, initialize: Bool = false) {
        if (initialize) {
            lastFilter!.addCompletedHandler { [weak self] _ in
                guard let self = self else {
                    result(FlutterError(code: "Create Error", message: "Filter overlay failed.", details: nil))
                    return
                }
                DispatchQueue.main.async {
                    if (self.lastFilter!.outputTexture?.bb_image) != nil {
                        self.texture!.createPixelBuffer(texture: self.lastFilter!.outputTexture!)
                        self.textureRegistry.textureFrameAvailable(self.textureId!)
                        if (initialize) {
                            result(self.textureId)
                        }
                    } else {
                        result(FlutterError(code: "Create Error", message: "Unable to load image.", details: nil))
                    }
                }
            }
        }
        
        imageSource!.transmitTexture()
    }
}


public class MetalTexture: NSObject, FlutterTexture {
    var _buffer: CVPixelBuffer?
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = _buffer {
            return Unmanaged<CVPixelBuffer>.passRetained(buffer)
        } else {
            return nil
        }
    }
    
    public func imageToPixelBuffer(image: UIImage, outputSize: CGSize) {
        _buffer = image.imageToPixelBuffer(outputSize: outputSize)
    }
    
    public func createPixelBuffer(texture: MTLTexture) {
        _buffer = texture.cgimageToPixelBuffer()
    }
}

public extension BBMetalStaticImageSource {
    func addAll(filter: Array<NSDictionary>) -> BBMetalBaseFilter? {
        var lastFilter: BBMetalBaseFilter? = nil
        loop: for f in filter {
            let type: String = f.value(forKey: "type") as! String
            let _filter: BBMetalBaseFilter
            switch type {
                case "brightness":
                _filter = BBMetalBrightnessFilter(brightness: (f["value"] as! NSString).floatValue)
                case "contrast":
                    _filter = BBMetalContrastFilter(contrast: (f["value"] as! NSString).floatValue)
                case "saturation":
                    _filter = BBMetalSaturationFilter(saturation: (f["value"] as! NSString).floatValue)
                default:
                    continue loop
            }
            if (lastFilter == nil) {
                add(consumer: _filter)
            } else {
                lastFilter!.add(consumer: _filter)
            }
            lastFilter = _filter
        }
        return lastFilter!
    }
}

public extension MTLTexture {
    func imageToPixelBuffer() -> CVPixelBuffer? {
        return bb_image?.imageToPixelBuffer(outputSize: CGSize(width: width, height: height))
    }

    func cgimageToPixelBuffer() -> CVPixelBuffer? {
        guard let cgimage = bb_cgimage else {
            return nil
        }
        var pixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            String(kCVPixelBufferIOSurfacePropertiesKey): [:]
        ]
        /// 分配内存，创建CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
        
        if status == kCVReturnSuccess {
            // let ciImage = CIImage(mtlTexture: bb_cgimage!.bb_metalTexture!)!
            let ciImage = CIImage(cgImage: cgimage)
            print(ciImage)
            let ciContext = CIContext(mtlDevice: BBMetalDevice.sharedDevice)
            print(ciImage.extent)
            ciContext.render(ciImage, to: pixelBuffer!)
//            ciContext.render(ciImage, to: pixelBuffer!, bounds: CGRect(x: 0, y: 0, width: width, height: height), colorSpace: CGColorSpaceCreateDeviceRGB())
            return pixelBuffer
        }
        return nil
    }

    func toPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            String(kCVPixelBufferIOSurfacePropertiesKey): [:]
        ]
        /// 分配内存，创建CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
        if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
            /// 写入数据
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            getBytes(CVPixelBufferGetBaseAddress(pixelBuffer)!, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return pixelBuffer
        }
        return nil
    }
}

extension UIImage {
    /// 重绘图片大小
    func resizedImage(outputSize: CGSize) -> UIImage? {
        if size == outputSize {
            return self
        } else {
            UIGraphicsBeginImageContext(outputSize)
//            UIGraphicsBeginImageContextWithOptions(outputSize, false, 0.0)
            draw(in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let newImage = scaledImage else {
                return nil
            }
            return newImage
        }
    }
    
    /// UIImage -> CVPixelBuffer
    func imageToPixelBuffer(outputSize: CGSize) -> CVPixelBuffer? {
        let inputImage: UIImage = self
        var pixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            String(kCVPixelBufferIOSurfacePropertiesKey): [:]
        ]
        guard let cgImage: CGImage = inputImage.cgImage else {
            return pixelBuffer
        }
        /// 分配内存，创建CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(outputSize.width), Int(outputSize.height), kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
        if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
            /// 写入数据
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                    width: Int(outputSize.width),
                                    height: Int(outputSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        return pixelBuffer
    }
    
    /// CVPixelBuffer -> UIImage
    class func pixelBufferToImage(pixelBuffer: CVPixelBuffer, outputSize: CGSize) -> UIImage? {
//        let type = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
            let imageRef = context.makeImage()
        else {
            return nil
        }
        
        let newImage = UIImage(cgImage: imageRef, scale: 1, orientation: UIImage.Orientation.up).resizedImage(outputSize: outputSize)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return newImage
    }
}
