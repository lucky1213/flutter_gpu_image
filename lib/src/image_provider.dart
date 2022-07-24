part of flutter_gpu_image;

abstract class FlutterGpuImageProvider<T> extends Equatable {
  final T data;

  const FlutterGpuImageProvider(this.data);

  @override
  List<Object?> get props => [data];
}

class FlutterGpuFileImageProvider<File> extends FlutterGpuImageProvider {
  const FlutterGpuFileImageProvider(File file) : super(file);
}

class FlutterGpuMemoryImageProvider<File> extends FlutterGpuImageProvider {
  const FlutterGpuMemoryImageProvider(Uint8List bytes) : super(bytes);
}
