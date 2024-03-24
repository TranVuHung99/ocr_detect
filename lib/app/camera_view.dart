import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

const int imageQuality = 70;
const double imageResolution = 720;
const String tagOrientation = "Orientation";
const int undefineOrientation = 0;
const int orientationRotate90 = 6;
const int orientationRotate180 = 3;
const int orientationRotate270 = 8;

class CameraViewPage extends StatefulWidget {
  const CameraViewPage({Key? key}) : super(key: key);

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> with WidgetsBindingObserver {
  File? imageFile;
  CameraController? controller;
  late List<CameraDescription> _cameras;


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
   super.dispose();
  }

  Future<void> _initCamera() async {
    await controller?.dispose();
    _cameras = await availableCameras();
    controller = CameraController(_cameras.first, ResolutionPreset.max, enableAudio: false);

    await controller?.initialize();
    setState(() {

    });

  }

  String formatDateTime(DateTime? dateTime, {String pattern = "E, d MMM yyyy - HH:mm"}) {
    if (dateTime == null) {
      return "";
    }
    final dateFormatter = DateFormat(pattern);
    return dateFormatter.format(dateTime);
  }

  Future<File> createTempImageFile() async {
    final timeStamps = formatDateTime(DateTime.now(), pattern: "yyyyMMdd_HHmmss");
    final imageFileName = "JPEG_${timeStamps}_.jpg";
    final path = join(
      (await getTemporaryDirectory()).path,
      imageFileName,
    );
    return File(path);
  }

  Future<File> compressImageFile(XFile file) async {
    final resultsFile = File(file.path);
    final imageBytes = await file.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage != null) {
      double width = originalImage.width.toDouble();
      double height = originalImage.height.toDouble();
      if (width > imageResolution || height > imageResolution) {
        if (width < height) {
          height = imageResolution;
          width = imageResolution / originalImage.height * originalImage.width;
        } else {
          width = imageResolution;
          height = imageResolution / originalImage.width * originalImage.height;
        }
      }
      final compressImg = await FlutterImageCompress.compressWithList(
        imageBytes,
        rotate: 90,
        minWidth: width.toInt(),
        minHeight: height.toInt(),
      );

      await resultsFile.writeAsBytes(compressImg);
    }
    return resultsFile;
  }

  Future onCapture(BuildContext context) async {
    if (controller == null) return;
    File file = await createTempImageFile();
    final xFile = await controller!.takePicture();
    await compressImageFile(xFile);
    file = File(xFile.path);
    if(mounted) {
      Navigator.of(context).pop(file);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller;
    switch (state) {
      case AppLifecycleState.resumed:
        if(cameraController == null || !cameraController.value.isInitialized){
          _initCamera();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cameraController?.dispose();
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: Colors.grey,
                  width: 3.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ),
          _cameraButton(context),
        ],
      ),
    );
  }

  Widget _cameraButton(BuildContext context) {
    final CameraController? cameraController = controller;

    return IconButton(
      icon: const Icon(Icons.camera_alt),
      color: Colors.blue,
      onPressed: cameraController != null &&
          cameraController.value.isInitialized &&
          !cameraController.value.isRecordingVideo
          ? () => onCapture(context)
          : null,
    );
  }

  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;
    print(cameraController);
    if (cameraController == null || !cameraController.value.isInitialized) {return const SizedBox();}
    else{
      return CameraPreview(
        cameraController,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
              );
            }),
      );
    }

  }
}
