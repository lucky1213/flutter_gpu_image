part of 'image_filter.dart';

/// * [brightness] 0.0 ~ 1.0
class SobelEdgeDetectionFilter extends ImageFilter {
  const SobelEdgeDetectionFilter({
    double size = 1.0,
  })  : assert(size >= 0, 'The adjusted size > 0 with 1.0 as the default'),
        super._(type: ImageFilterType.sobel_edge_detection, value: size);
}
