import 'package:equatable/equatable.dart';

part 'brightness_filter.dart';
part 'contrast_filter.dart';
part 'saturation_filter.dart';
part 'sharpen_filter.dart';
part 'gray_scale_filter.dart';
part 'highlight_shadow_filter.dart';
part 'gaussian_blur_filter.dart';
part 'black_white_filter.dart';
part 'sobel_edge_detection_filter.dart';
part 'sketch_filter.dart';
part 'image_filter_type.dart';

class ImageFilter extends Equatable {
  final ImageFilterType type;
  final dynamic value;

  const ImageFilter._({required this.type, required this.value});

  /// * [normal] 原图
  factory ImageFilter.normal() {
    return const ImageFilter._(type: ImageFilterType.normal, value: 0);
  }

  /// * [brightness] -1.0 ~ 1.0
  factory ImageFilter.brightness([
    double brightness = 0,
  ]) {
    return BrightnessFilter(brightness: brightness);
  }

  /// * [contrast] 0.0 ~ 4.0
  factory ImageFilter.contrast([
    double contrast = 1.0,
  ]) {
    return ContrastFilter(contrast: contrast);
  }

  /// * [saturation] 0.0 ~ 2.0
  // factory ImageFilter.saturation([
  //   double saturation = 1.0,
  // ]) {
  //   return SaturationFilter(saturation: saturation);
  // }

  /// * [sharpen] -4.0 ~ 4.0
  factory ImageFilter.sharpen([
    double sharpen = 1.0,
  ]) {
    return SharpenFilter(sharpen: sharpen);
  }

  /// * [shadow] 0.0 ~ 1.0
  factory ImageFilter.highlightShadow([
    double shadow = 0.0,
  ]) {
    return HighlightShadowFilter(shadow: shadow);
  }

  /// * [blurSize] 0.0 ~ 1.0
  factory ImageFilter.gaussianBlur([
    double blurSize = 0.0,
  ]) {
    return GaussianBlurFilter(blurSize: blurSize);
  }

  /// * [size] > 0.0
  factory ImageFilter.sobelEdgeDetection([
    double size = 1.0,
  ]) {
    return SobelEdgeDetectionFilter(size: size);
  }

  factory ImageFilter.grayScale() {
    return const GrayScaleFilter();
  }

  factory ImageFilter.blackWhite() {
    return const BlackWhiteFilter();
  }

  factory ImageFilter.sketch() {
    return const SketchFilter();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.value,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}
