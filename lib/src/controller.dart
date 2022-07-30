part of flutter_gpu_image;

class FlutterGpuImageException implements Exception {
  final String message;

  FlutterGpuImageException(this.message);
}

class FlutterGpuImageController extends ChangeNotifier
    implements ValueListenable<ImageInfo> {
  FlutterGpuImageController() : _value = ImageInfo.empty();

  @override
  ImageInfo get value => _value;
  ImageInfo _value;
  set value(ImageInfo newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  int? _textureId;
  int get textureId {
    if (_textureId == null) {
      throw FlutterGpuImageException('Not initialized');
    }
    return _textureId!;
  }

  final MethodChannel _channel = const MethodChannel('flutter_gpu_image');

  StreamSubscription<Map<String, dynamic>>? _subscription;

  Uint8List get bytes => value.bytes;

  Future<void> _initialize() async {
    if (_textureId != null) {
      return;
    }
    try {
      _textureId = await _channel.invokeMethod('initialize');
      _listen();
    } catch (e) {
      throw FlutterGpuImageException(e.toString());
    }
  }

  void _listen() {
    _subscription ??= EventChannel('flutter_gpu_image/listener_$textureId')
        .receiveBroadcastStream()
        .transform<Map<String, dynamic>>(
          StreamTransformer.fromHandlers(handleData: (event, sink) async {
            return sink.add(Map<String, dynamic>.from(event));
          }, handleError: (error, stack, sink) {
            return sink.addError(error, stack);
          }),
        )
        .listen((event) {
      value = ImageInfo.fromMap(event);
    }, onError: (e, s) {
      value = ImageInfo.fromMap({'state': LoadState.failed.index});
    });
  }

  Future<void> render({
    required FlutterGpuImageProvider image,
    List<ImageFilter> filter = const [],
  }) async {
    try {
      await _initialize();
      if (image is FlutterGpuFileImageProvider) {
        await _channel.invokeMethod('renderFromFile', {
          'id': textureId,
          'path': image.data,
          'filter': filter.map((e) => e.toJson()).toList(),
        });
      } else {
        final data = await _channel.invokeMethod('renderFromBytes', {
          'id': textureId,
          'bytes': image.data,
          'filter': filter.map((e) => e.toJson()).toList(),
        });
      }
    } catch (e) {
      throw FlutterGpuImageException(e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _subscription?.cancel();
      _subscription = null;
      if (_textureId != null) {
        await _channel.invokeMethod('dispose', {
          'id': textureId,
        });
      }
      super.dispose();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<void> setImage(FlutterGpuImageProvider image) async {
    try {
      await _initialize();
      if (image is FlutterGpuFileImageProvider) {
        await _channel.invokeMethod('setImageFromFile', {
          'id': textureId,
          'path': image.data,
        });
      } else {
        await _channel.invokeMethod('setImageFromBytes', {
          'id': textureId,
          'bytes': image.data,
        });
      }
    } catch (e) {
      throw FlutterGpuImageException(e.toString());
    }
  }

  Future<void> setFilter([
    List<ImageFilter> filter = const [],
  ]) async {
    try {
      await _initialize();
      await _channel.invokeMethod('setFilter', {
        'id': textureId,
        'filter': filter.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      throw FlutterGpuImageException(e.toString());
    }
  }
}
