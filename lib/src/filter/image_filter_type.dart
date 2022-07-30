// ignore_for_file: constant_identifier_names
part of 'image_filter.dart';

enum ImageFilterType {
  /// 原图
  normal,

  /// 亮度
  brightness,

  /// 对比度
  contrast,

  /// 饱和度
  // saturation,

  /// 灰度
  gray_scale,

  /// 灰度
  black_white,

  /// 伽马
  // gamma,

  /// 色调
  // hue,

  /// 白平衡
  // white_balance,

  /// 阴影突出
  highlight_shadow,

  /// 颜色反转
  // color_inversion,

  /// 锐化
  sharpen,

  /// 高斯模糊
  gaussian_blur,

  /// 索贝尔检测
  sobel_edge_detection,

  /// 线条sketch
  sketch
}

extension ImageFilterTypeExtension on ImageFilterType {
  static const Map<ImageFilterType, String> _map = <ImageFilterType, String>{
    ImageFilterType.normal: 'normal',
    ImageFilterType.brightness: 'brightness',
    ImageFilterType.contrast: 'contrast',
    ImageFilterType.gray_scale: 'gray_scale',
    ImageFilterType.black_white: 'black_white',
    ImageFilterType.highlight_shadow: 'highlight_shadow',
    ImageFilterType.sharpen: 'sharpen',
    ImageFilterType.gaussian_blur: 'gaussian_blur',
    ImageFilterType.sobel_edge_detection: 'sobel_edge_detection',
    ImageFilterType.sketch: 'sketch',
    // ImageFilterType.saturation: 'saturation',
    // ImageFilterType.gamma: 'gamma',
    // ImageFilterType.hue: 'hue',
    // ImageFilterType.white_balance: 'white_balance',
    // ImageFilterType.color_inversion: 'color_inversion',
  };

  String get value => _map[this]!;

  String get text {
    switch (this) {
      case ImageFilterType.normal:
        return '原图';
      case ImageFilterType.brightness:
        return '明暗度';
      case ImageFilterType.contrast:
        return '对比度';
      case ImageFilterType.gray_scale:
        return '灰度';
      case ImageFilterType.black_white:
        return '黑白';
      case ImageFilterType.highlight_shadow:
        return '阴影突出';
      case ImageFilterType.sharpen:
        return '锐化';
      case ImageFilterType.gaussian_blur:
        return '高斯模糊';
      case ImageFilterType.sobel_edge_detection:
        return '索贝尔检测';
      case ImageFilterType.sketch:
        return 'Sketch';

      // case ImageFilterType.saturation:
      //   return '饱和度';
      // case ImageFilterType.gamma:
      //   return '伽马';
      // case ImageFilterType.hue:
      //   return '色调';
      // case ImageFilterType.white_balance:
      //   return '白平衡';
      // case ImageFilterType.color_inversion:
      //   return '颜色反转';
    }
  }
}
