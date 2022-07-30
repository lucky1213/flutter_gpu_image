part of 'image_filter.dart';

/// * [sharpen] -4.0 ~ 4.0
class SharpenFilter extends ImageFilter {
  const SharpenFilter({
    double sharpen = 0,
  })  : assert(sharpen >= -4 || sharpen <= 4,
            'The adjusted sharpen (-4.0 ~ 4.0, with 0.0 as the default)'),
        super._(type: ImageFilterType.sharpen, value: sharpen);
}
