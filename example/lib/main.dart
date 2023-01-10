import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cameraimage_converter/cameraimage_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(_cameras[1], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
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
        actions: [
          Visibility(
              visible: _bytes != null,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _bytes = null;
                  count = 0;
                  setState(() {});
                },
              ))
        ],
      ),
      body: (_controller.value.isInitialized)
          ? (_bytes != null)
              ? Image.memory(_bytes!)
              : CameraPreview(_controller)
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _startImageStream,
            child: const Icon(Icons.run_circle_outlined),
          ),
          FloatingActionButton(
            onPressed: _takePicture,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  void _startImageStream() {
    _controller.startImageStream((image) async {
      // only 1
      if (count > 0) return await _controller.stopImageStream();
      count++;

      //
      // conver png
      final start = DateTime.now().millisecondsSinceEpoch;
      _bytes = await CameraImageConverter.convertImageToPng(image);
      final end = DateTime.now().millisecondsSinceEpoch;

      // log to time
      if (_bytes == null) return log('result null (png)');
      log('[time ${end - start} ms] convert png');

      setState(() {});

      // // download to gallery (png)
      // await ImageGallerySaver.saveImage(bytes);
    });
  }

  void _takePicture() async {
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
