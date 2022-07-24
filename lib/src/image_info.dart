part of flutter_gpu_image;

enum LoadState {
  loading,
  successful,
  failed,
}

class ImageInfo {
  const ImageInfo({
    this.state = LoadState.loading,
    this.width,
    this.height,
    Uint8List? bytes,
  }) : _bytes = bytes;

  final LoadState state;
  final int? width;
  final int? height;
  final Uint8List? _bytes;

  Uint8List get bytes {
    if (_bytes == null) {
      throw FlutterGpuImageException('Image is not loaded');
    }
    return _bytes!;
  }

  factory ImageInfo.empty() => const ImageInfo(
        state: LoadState.loading,
      );

  factory ImageInfo.fromMap(Map<String, dynamic> map) {
    final state = LoadState.values[map['state'] as int];
    Map<String, dynamic>? imageInfo;
    if (state == LoadState.successful) {
      imageInfo = Map<String, dynamic>.from(map['image_info']);
    }
    return ImageInfo(
      state: state,
      width: imageInfo?['width'] as int?,
      height: imageInfo?['height'] as int?,
      bytes: imageInfo?['bytes'] as Uint8List?,
    );
  }

  factory ImageInfo.fromJson(String source) =>
      ImageInfo.fromMap(json.decode(source));
}
