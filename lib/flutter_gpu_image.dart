library flutter_gpu_image;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gpu_image/src/filter/image_filter.dart';

export 'package:flutter_gpu_image/src/filter/image_filter.dart';

part 'src/controller.dart';
part 'src/image_info.dart';
part 'src/image_provider.dart';

class FlutterGpuImage extends StatefulWidget {
  const FlutterGpuImage({
    Key? key,
    required this.image,
    this.filter,
    this.controller,
    this.width,
    this.height,
    this.fit,
    this.loadingBuilder,
    this.failedBuilder,
  }) : super(key: key);

  final FlutterGpuImageProvider image;
  final ImageFilter? filter;
  final FlutterGpuImageController? controller;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? failedBuilder;

  @override
  State<FlutterGpuImage> createState() => _FlutterGpuImageState();
}

class _FlutterGpuImageState extends State<FlutterGpuImage> {
  late FlutterGpuImageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FlutterGpuImageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.render(image: widget.image, filter: widget.filter);
    });
  }

  @override
  void didUpdateWidget(covariant FlutterGpuImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter && widget.image != oldWidget.image) {
      _controller.render(image: widget.image, filter: widget.filter);
    } else {
      if (widget.image != oldWidget.image) {
        _controller.setImage(widget.image);
      } else if (widget.filter != oldWidget.filter) {
        _controller.setFilter(widget.filter);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ValueListenableBuilder<ImageInfo>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.state == LoadState.loading) {
              return widget.loadingBuilder?.call(context) ??
                  const Center(child: CircularProgressIndicator());
            } else if (value.state == LoadState.failed) {
              return widget.failedBuilder?.call(context) ??
                  const Center(
                    child: Text('failed'),
                  );
            }
            return FittedBox(
              fit: widget.fit ?? BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: value.width?.toDouble() ?? widget.width,
                height: value.height?.toDouble() ?? widget.height,
                child: Texture(
                  textureId: _controller.textureId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
