import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _image;
  final picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];
  String _predictionResult = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    if(_interpreter != null) return;
    try {
      // _interpreter = await Interpreter.fromAsset('yolomodel.tflite');
      _interpreter = await Interpreter.fromAsset('assets/yolomodel.tflite');
      print("Data from tensors input ${_interpreter!.getInputTensors()}");
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    if(_labels.isNotEmpty) return;
    try {
      final labelsData =
      await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      setState(() {
        _labels = labelsData.split('\n');
      });
      print('Labels loaded successfully');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera,
      maxHeight: 640,
      maxWidth: 640,);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _predictionResult = '';
      });
      _predictImage(_image!);
    }
  }



  Future<void> _predictImage(File image) async {
    print("Predict Image Method called");
    if (_interpreter == null || _labels.isEmpty) {
      print('Model or labels not loaded');
      return;
    }

    try {

      var input = image;

      // YOLO models typically return a large output tensor with predictions
      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run([input], output);

      if (output.isNotEmpty) {
        // Extract the highest probability prediction
        final maxIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
        setState(() {
          _predictionResult = _labels[maxIndex];
        });
        print("Prediction Result: $_predictionResult");
      } else {
        print("Output length is zero");
      }
    } catch (e) {
      print('Error during prediction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // future: Future.wait([debugAssetPath()]),
      future: Future.wait([_loadModel(), _loadLabels()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading model or labels'));
        } else {
          return Scaffold(
            appBar: AppBar(title: Text('Image Picker & Prediction')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null
                      ? Text('No image selected.')
                      : Image.file(_image!, width: 200, height: 200),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick Image'),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Prediction: $_predictionResult',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

}
