part of 'image_filter.dart';

class BlackWhiteFilter extends ImageFilter {
  const BlackWhiteFilter()
      : super._(type: ImageFilterType.black_white, value: 1.0);
}
