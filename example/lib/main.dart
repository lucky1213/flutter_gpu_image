import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gpu_image/flutter_gpu_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? file;
  Uint8List? byte;
  @override
  void initState() {
    super.initState();
  }

  Future<void> init(BuildContext context, RequestType type) async {
    final PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          requestType: type,
          maxAssets: 1,
        ),
      );
      if ((assets ?? []).isNotEmpty) {
        Directory? directory;
        if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
          file = await assets!.first.originFile;
          byte = await assets.first.originBytes;
        } else {
          directory = await getExternalStorageDirectory();
          file = await assets!.first.file;
          byte = await assets.first.originBytes;
        }
        setState(() {});
        return;
      } else {
        throw Exception("No files selected");
      }
    }
    throw Exception("Permission denied");
  }

// /private/var/mobile/Containers/Data/Application/B6CB65FE-2755-467F-BCB2-6F5C5DAA1D62/tmp/image_picker_9880EA81-5257-4CBB-8FDD-6E0FED4C85F0-7890-000002063CF3FAA0.png
// /Users/imac/Library/Developer/CoreSimulator/Devices/97433C75-B0E7-4065-85CA-4C11B8A45775/data/Containers/Data/Application/7D104799-B07C-47EA-BD32-1E2B99E10042/tmp/image_picker_15241AFE-A53C-4D54-BE95-B29B5D2E61DD-59558-000582102D6AB3B0.png
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Builder(builder: (_) {
            return Column(
              children: [
                if (file != null)
                  Image.file(
                    file!,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                if (file != null) ...[
                  // FlutterGpuImage(
                  //   image: FlutterGpuMemoryImageProvider(byte!),
                  //   filter: [
                  //     ImageFilter.blackWhite(),
                  //     ImageFilter.sketch(),
                  //   ],
                  //   width: 200,
                  //   loadingBuilder: (context) {
                  //     return const Center(child: Text('loading'));
                  //   },
                  //   fit: BoxFit.cover,
                  // ),
                  FlutterGpuImage(
                    image: FlutterGpuMemoryImageProvider(byte!),
                    filter: [
                      // ImageFilter.brightness(0.5),
                      // ImageFilter.contrast(1.0),
                      ImageFilter.normal(),
                    ],
                    width: 200,
                    loadingBuilder: (context) {
                      return const Center(child: Text('loading'));
                    },
                    fit: BoxFit.cover,
                  ),
                  // FlutterGpuImage(
                  //   image: FlutterGpuMemoryImageProvider(byte!),
                  //   filter: [
                  //     ImageFilter.sobelEdgeDetection(2),
                  //   ],
                  //   width: 100,
                  //   loadingBuilder: (context) {
                  //     return const Center(child: Text('loading'));
                  //   },
                  //   fit: BoxFit.cover,
                  // ),
                ],
                TextButton(
                  onPressed: () async {
                    await init(_, RequestType.image);
                  },
                  child: const Text('init'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
