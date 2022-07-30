part of 'image_filter.dart';

class GrayScaleFilter extends ImageFilter {
  const GrayScaleFilter()
      : super._(type: ImageFilterType.gray_scale, value: null);
}
