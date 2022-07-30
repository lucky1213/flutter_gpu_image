part of 'image_filter.dart';

/// * [shadow] 0.0 ~ 1.0
class HighlightShadowFilter extends ImageFilter {
  const HighlightShadowFilter({
    double shadow = 0,
  })  : assert(shadow >= 0 || shadow <= 1,
            'The adjusted shadow (0.0 ~ 1.0, with 0.0 as the default)'),
        super._(type: ImageFilterType.highlight_shadow, value: shadow);
}
