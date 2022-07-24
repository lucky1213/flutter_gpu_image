part of 'image_filter.dart';

/// * [contrast] 0.0 ~ 4.0
class ContrastFilter extends ImageFilter {
  const ContrastFilter({
    double contrast = 1.0,
  })  : assert(contrast >= 0 || contrast <= 4,
            'The adjusted contrast (0.0 ~ 4.0, with 1.0 as the default)'),
        super._(type: ImageFilterType.contrast, value: contrast);
}
