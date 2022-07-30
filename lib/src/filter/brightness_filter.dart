part of 'image_filter.dart';

/// * [brightness] -1.0 ~ 1.0
class BrightnessFilter extends ImageFilter {
  const BrightnessFilter({
    double brightness = 0,
  })  : assert(brightness >= -1 || brightness <= 1,
            'The adjusted brightness (-1.0 ~ 1.0, with 0.0 as the default)'),
        super._(type: ImageFilterType.brightness, value: brightness);
}
