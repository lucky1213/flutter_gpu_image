import 'package:equatable/equatable.dart';

part 'brightness_filter.dart';
part 'contrast_filter.dart';
part 'saturation_filter.dart';
part 'image_filter_type.dart';

class ImageFilter extends Equatable {
  final ImageFilterType type;
  final dynamic value;

  const ImageFilter._({required this.type, required this.value});

  /// * [normal] 原图
  factory ImageFilter.normal() {
    return ImageFilter._(type: ImageFilterType.normal, value: 0);
  }

  /// * [brightness] 0.0 ~ 1.0
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
  factory ImageFilter.saturation([
    double saturation = 1.0,
  ]) {
    return SaturationFilter(saturation: saturation);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.value,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}
