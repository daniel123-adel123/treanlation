import 'dart:io';
import 'package:bldapp/view/chat_bot.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bldapp/view/DonationView.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OCR_View extends StatefulWidget {
  @override
  _OCR_ViewState createState() => _OCR_ViewState();
}

class _OCR_ViewState extends State<OCR_View>
    with SingleTickerProviderStateMixin {
  File? _image;
  final picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  num x1 = 0;
  num x2 = 0;
  num x3 = 0;
  num x4 = 0;

  bool textScanning = false;

  XFile? imageFile;

  String scannedText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Center(
                  child: imageFile == null
                      ? Text('No image selected.')
                      : Image.file(File(imageFile!.path)),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return DonationView();
              }));
            },
            child: Text('Animate Image'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getImage(ImageSource.gallery);
        },
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        getRecognisedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  void getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognisedText = await textDetector.processImage(inputImage);
    await textDetector.close();

    List<num> numbersList = [];

    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.trim();
        RegExp regExp = RegExp(r'\b\d+(\.\d+)?\b');
        Iterable<Match> matches = regExp.allMatches(lineText);
        for (Match match in matches) {
          String number = match.group(0)!;
          if (number.startsWith('.') || number.endsWith('.')) {
            continue;
          }
          if (number.contains('.')) {
            numbersList.add(double.parse(number));
          } else {
            numbersList.add(int.parse(number));
          }
        }
      }
    }

    print(numbersList);

    textScanning = false;
    setState(() {
      x1 = numbersList[0];
      x2 = numbersList[1];
      x3 = numbersList[2];
      x4 = numbersList[3];

      setState(() {
        if (x1 >= 4 &&
            x1 <= 11 &&
            x2 >= 4.40 &&
            x2 <= 6 &&
            x3 >= 13.5 &&
            x3 <= 18 &&
            x4 >= 40 &&
            x4 <= 52) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Good analysis',
            desc: 'press Ok to complete your donation check',
            btnCancelOnPress: () {
              Navigator.pop(context);
            },
            btnOkOnPress: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonationView(),
                  ));

              setState(() {});
            },
          ).show();
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'Sorry',
            desc: ' you can\'t donate press continue to check the reasons',
            btnCancelOnPress: () {
              Navigator.pop(context);
            },
            btnOkOnPress: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatTwoPage(),
                  ));

              setState(() {});
            },
          ).show();
        }
      });
    });
  }
}
