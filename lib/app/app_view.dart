import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class AppViewPage extends StatefulWidget {
  const AppViewPage({Key? key}) : super(key: key);

  @override
  State<AppViewPage> createState() => _AppViewPageState();
}

class _AppViewPageState extends State<AppViewPage> {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  XFile? imageFile;

  List<TextBlock> textBlocks = [];

  String findText = "unknown";

  Future<void> _processImage() async {
    final filePath = imageFile?.path;
    if (filePath != null) {
      final InputImage inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        textBlocks = recognizedText.blocks;
      });
    }
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text(
          "OCR Detection App",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTapDown: _onTapDownDetect,
                child: Container(
                  width: 400,
                  height: 300,
                  color: Colors.grey,
                  child: imageFile != null
                      ? Image.file(
                    File(imageFile?.path ?? ""),
                    fit: BoxFit.contain,
                  )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.lightBlue,
                ),
                child: Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () => _showPicker(context),
                      child: const Text(
                        'Pick an image',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20,),
              Text(findText, style: const TextStyle(color: Colors.black, fontSize: 18),)
            ],
          ),
        ),
      ),
    ));
  }

  void _onTapDownDetect(TapDownDetails details) {
    print(details.globalPosition);

    print(details.localPosition);

    for (TextBlock block in textBlocks) {
      final Rect rect = block.boundingBox;
      final String text = block.text;
      print("~~~~~~~~~~~ rect: $rect ~~~~~~~~~~~~~text: $text");

      if(rect.contains(details.localPosition)){
        setState(() {
          findText = text;
        });
        break;
      }
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10))),
        context: context,
        builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  "Choose source to pick image",
                  style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    pickImage(0);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "From Camera",
                    style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                TextButton(
                  onPressed: () {
                    pickImage(1);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "From Gallery",
                    style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ));
  }

  Future<void> pickImage(int type) async {
    final ImagePicker picker = ImagePicker();
    switch (type) {
      case 0:
        final XFile? photo = await picker.pickImage(source: ImageSource.camera,maxWidth: 400, maxHeight: 300);
        if (photo != null) {
          setState(() {
            imageFile = photo;
          });
        }
        break;

      case 1:
        final XFile? image = await picker.pickImage(source: ImageSource.gallery,maxWidth: 400, maxHeight: 300);
        if (image != null) {
          setState(() {
            imageFile = image;
          });
        }
        break;
    }
    _processImage();
  }
}
