import 'dart:developer';
import 'dart:io';

import 'package:cameraimage_converter/cameraimage_converter.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraExamplePage(),
    );
  }
}

class CameraExamplePage extends StatefulWidget {
  const CameraExamplePage({super.key});

  @override
  State<CameraExamplePage> createState() => _CameraExamplePageState();
}

class _CameraExamplePageState extends State<CameraExamplePage> {
  late CameraController _controller;
  int count = 0;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(_cameras[1], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});

      _controller.startImageStream((image) async {
        // save only 2 cameraImages
        if (count > 1) {
          await _controller.stopImageStream();
          return;
        }
        count++;

        //
        // conver png
        final start = DateTime.now().millisecondsSinceEpoch;
        final bytes = await CameraImageConverter.convertImageToPng(image);
        final end = DateTime.now().millisecondsSinceEpoch;

        // log to time
        if (bytes == null) return log('result null (png)');
        log('[time ${end - start} ms] convert png');

        // download to gallery (png)
        await ImageGallerySaver.saveImage(bytes);
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            log('CameraAccessDenied ${e.description}');
            break;
          default:
            log('CameraException ${e.description}');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
      ),
      body: (_controller.value.isInitialized)
          ? CameraPreview(_controller)
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            final file = await _controller.takePicture();

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPicturePage(imagePath: file.path),
              ),
            );
          } catch (e) {
            log(e.toString());
          }
        },
      ),
    );
  }
}

class DisplayPicturePage extends StatelessWidget {
  const DisplayPicturePage({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
      ),
      body: Image.file(
        File(imagePath),
      ),
    );
  }
}
