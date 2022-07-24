#import "FlutterGpuImagePlugin.h"
#if __has_include(<flutter_gpu_image/flutter_gpu_image-Swift.h>)
#import <flutter_gpu_image/flutter_gpu_image-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_gpu_image-Swift.h"
#endif

@implementation FlutterGpuImagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterGpuImagePlugin registerWithRegistrar:registrar];
}
@end
