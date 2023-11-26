import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue,
            onPrimary: Colors.black, // Text color for buttons
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.blue,
        ),
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late int _currentCameraIndex;

  @override
  void initState() {
    super.initState();
    _currentCameraIndex = 0;
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.cameras[_currentCameraIndex],
      ResolutionPreset.medium,
    );
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  void _onCameraButtonPressed(int cameraIndex) async {
    try {
      await _controller.dispose();
      _controller = CameraController(
        widget.cameras[cameraIndex],
        ResolutionPreset.medium,
      );
      await _controller.initialize();
    } catch (e) {
      print(e);
    }

    if (_controller.value.isInitialized) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(controller: _controller),
        ),
      );
    }
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
        title: Text('PaperKraft'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://i.pinimg.com/564x/d8/c6/2d/d8c62d2aea956a3a6894f75b81636e75.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _onCameraButtonPressed(0),
                  child: Text('Bird Origami'),
                ),
                ElevatedButton(
                  onPressed: () => _onCameraButtonPressed(0),
                  child: Text('Animal Origami'),
                ),
                ElevatedButton(
                  onPressed: () => _onCameraButtonPressed(0),
                  child: Text('Math Origami'),
                ),
                ElevatedButton(
                  onPressed: () => _onCameraButtonPressed(0),
                  child: Text('Insect Origami'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraController controller;

  const CameraScreen({Key? key, required this.controller}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final XFile picture = await widget.controller.takePicture();
      int prediction = await _sendImageAndGetPrediction(File(picture.path));
      _handlePredictionResult(prediction);
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<int> _sendImageAndGetPrediction(File image) async {
    try {
      var uri = Uri.parse('http://172.16.21.129:5000/predict');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var result = jsonDecode(utf8.decode(responseData));
      return result['prediction'];
    } catch (e) {
      print('Error sending image and getting prediction: $e');
      return -1; // Return a default value or handle the error as needed
    }
  }

  void _handlePredictionResult(int prediction) {
    String origamiType = (prediction == 1 ? 'Swan' : 'Unknown Origami');
    String message = 'Detected Origami Type: $origamiType';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Origami Recognition Result'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
      ),
      body: Stack(
        children: [
          Center(
            child: CameraPreview(widget.controller),
          ),
          Align(
            alignment: Alignment.center,
            child: _buildScanningAnimation(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: _takePicture,
              child: Text('Take Picture'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 59, 157, 255),
          width: 4.0,
        ),
      ),
      child: SlideTransition(
        position: _animationController.drive(
          Tween<Offset>(
            begin: Offset(0, -1),
            end: Offset(0, 1),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 2.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color.fromARGB(255, 246, 246, 246),
                const Color.fromARGB(0, 244, 244, 244)
              ],
              stops: [0.25, 0.5, 0.75],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}
