part of 'image_filter.dart';

/// * [blurSize] 0.0 ~ 1.0
class GaussianBlurFilter extends ImageFilter {
  const GaussianBlurFilter({
    double blurSize = 0,
  })  : assert(blurSize >= 0 || blurSize <= 1,
            'The adjusted sharpen (-4.0 ~ 4.0, with 0.0 as the default)'),
        super._(type: ImageFilterType.gaussian_blur, value: blurSize);
}
