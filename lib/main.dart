import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File _pickedImage;
  List<String> readData = [];
  String imageUrl;
  final firestore = Firestore.instance;
  bool _isSaving = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _pickedImage = image;
      _forenameController.text = '';
      _surnameController.text = '';
      _dobController.text = '';
      _postcodeController.text = '';
      _addressController.text = '';
      _licenceNumberController.text = '';
    });
    saveImage();
  }

  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(_pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        print(line.text);
        readData.add(line.text);
      }
    }
    fillData();
  }

  final surnameRegEx = RegExp(r"^(1)[ .](\s)*");
  final forenameRegEx = RegExp(r"^(2)[ .](\s)*");
  final licenceNumberRegEx = RegExp(r"^(5)[ .](\s)*");

  void fillData() {
    for (String data in readData) {
      if (surnameRegEx.hasMatch(data)) {
        String surname =
            data.replaceFirst(surnameRegEx.firstMatch(data).group(0), '');
        setState(() {
          _surnameController.text = surname;
        });
      }
      if (forenameRegEx.hasMatch(data)) {
        String forename =
            data.replaceFirst(forenameRegEx.firstMatch(data).group(0), '');
        setState(() {
          _forenameController.text = forename;
        });
      }
      if (licenceNumberRegEx.hasMatch(data)) {
        String licenceNumber =
            data.replaceFirst(licenceNumberRegEx.firstMatch(data).group(0), '');
        setState(() {
          _licenceNumberController.text = licenceNumber;
        });
      }
    }
  }

  void saveImage() async {
    String filePath = '${DateTime.now()}.png';
    StorageReference ref = FirebaseStorage.instance.ref().child(filePath);
    StorageUploadTask task = ref.putFile(_pickedImage);
    imageUrl = await (await task.onComplete).ref.getDownloadURL();
  }

  void uploadData() async {
    setState(() {
      _isSaving = true;
    });
    await firestore.collection('Driver_details').add({
      "surname": _surnameController.value.text,
      "forename": _forenameController.value.text,
      "dob": _dobController.value.text,
      "licence": _licenceNumberController.value.text,
      "address": _addressController.value.text,
      "postcode": _postcodeController.value.text,
      "image": imageUrl,
    });
    new Future.delayed(new Duration(seconds: 2), () {
      setState(() {
        _isSaving = false;
        _pickedImage = null;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Data Uploaded !'),
        duration: Duration(seconds: 2),
      ));
    });
  }

  final _surnameController = TextEditingController();
  final _forenameController = TextEditingController();
  final _dobController = TextEditingController();
  final _licenceNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('OCR Project'),
      ),
      body: ModalProgressHUD(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: _pickedImage == null
                ? MainAxisAlignment.spaceAround
                : MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Center(
                  child: _pickedImage == null
                      ? Text('No image selected.')
                      : Image.file(_pickedImage),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              _pickedImage != null
                  ? Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 20),
                          child: Form(
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Surname',
                                  ),
                                  controller: _surnameController,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Forename',
                                  ),
                                  controller: _forenameController,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'DOB',
                                  ),
                                  controller: _dobController,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Licence Number',
                                  ),
                                  controller: _licenceNumberController,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Address',
                                  ),
                                  controller: _addressController,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Postcode',
                                  ),
                                  controller: _postcodeController,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            RaisedButton(
                              child: Text("Scan"),
                              onPressed: readText,
                            ),
                            RaisedButton(
                              child: Text("Upload"),
                              onPressed: uploadData,
                            )
                          ],
                        ),
                      ],
                    )
                  : Text(''),
            ],
          ),
        ),
        inAsyncCall: _isSaving,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_a_photo),
        tooltip: 'Pick Image',
        onPressed: getImage,
      ),
    );
  }
}
