import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client
//      .get(Uri.parse('https://jsonplaceholder.typicode.com/photos'));
      .get(Uri.parse('https://commons.wikimedia.org/wiki/User:Zache/test.json?action=raw&ctype=application/json'));
  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}

// A function that converts a response body into a List<Photo>.
List<Photo> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}

class Photo {
  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  Photo({this.albumId, this.id, this.title, this.url, this.thumbnailUrl});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }
}
Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
//      home: MyApp()
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Isolate Demo';

    return MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<Photo>>(
        future: fetchPhotos(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? PhotosList(photos: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  final List<Photo> photos;

  PhotosList({Key key, this.photos}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return new GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(photo: photos[index]),
                ),
              );
            },
            child:Image.network(photos[index].thumbnailUrl)
        );
      },
    );
  }

}

class DetailScreen extends StatelessWidget {
  final Photo photo;

  // In the constructor, require a Photo.
  DetailScreen({Key key, @required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Align(
          alignment: Alignment.topCenter,
          child: Hero(
            tag: 'imageHero',
            child: Image.network(
              photo.thumbnailUrl,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}


// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  TransformationController controllerT = TransformationController();
  var initialControllerValue;
  var initialHeight;
  var initialWidth;
  double currentScaleValue=1.0;
  Offset lastInteractionFocalPoint;
  double initialTransparency=0.65;
  GlobalKey stickyKey = GlobalKey();
  GlobalKey stickyKey2 = GlobalKey();


  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown,DeviceOrientation.portraitUp]);
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: Listener(
          onPointerMove: (details) { print("onPointerMove" + details.localDelta.toString());

          // Handle transperency  panning

          double diffX=details.localDelta.dx;
          double diffY=details.localDelta.dy;

          // Include only events which doesn't include significant movement in X axis
          // Aproach doesn't work because values are different in different devices

          if ((diffX).abs()<5) {
            print("initialTransparency: diffX: " +diffX.toString() +" diffY: " + diffY.toString());

            if (diffY<0 && initialTransparency >0 ) {
              setState(() { initialTransparency -=0.01; });
            }
            else if (diffY>0 && initialTransparency <1 ) {
              setState(() { initialTransparency +=0.01; });
            }
          }
//          lastInteractionFocalPoint=details.focalPoint;

          },
          child: Stack(
              alignment: Alignment.center,
              children:<Widget>[
                FutureBuilder<void>(
                  key:stickyKey2,
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    /* Read the initial old photo size */
                    initialWidth=MediaQuery.of(context).size.width;
                    initialHeight=MediaQuery.of(context).size.height;

                    /* Initialize camera */
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the Future is complete, display the preview.
                      return CameraPreview(_controller);
                    } else {
                      // Otherwise, display a loading indicator.
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
                InteractiveViewer(
                  panEnabled: false,
                  maxScale: 10,
                  minScale: 0.3,
                  boundaryMargin: EdgeInsets.all(double.infinity),
                  transformationController: controllerT,
//              clipBehavior: Clip.none,
                  onInteractionStart: (details){
                    // Set
                    lastInteractionFocalPoint=details.focalPoint;
                  },
                  onInteractionUpdate: (details) {
                    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown,DeviceOrientation.portraitUp]);

                    // Pinch-to-zoom
                    // Move the center of the old image to the center of its area

                    Matrix4 translationMatrix = controllerT.value;
                    currentScaleValue = controllerT.value.getMaxScaleOnAxis();
                    double centerX=(initialWidth-initialWidth*currentScaleValue)/2;
                    double centerY=(initialHeight-initialHeight*currentScaleValue)/4;
                    translationMatrix.setTranslationRaw(centerX, centerY, 0.0);
                    controllerT.value=translationMatrix;
                  },
                  child:  Image.network(
                    "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Katarina_Taikon_1953.jpg/596px-Katarina_Taikon_1953.jpg",
                    color: Color.fromRGBO(255, 255, 255, initialTransparency),
                    colorBlendMode: BlendMode.modulate,
                    key: stickyKey,
                  ),
                ),
              ]
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {

            /* TAKE PHOTO */

            // Ensure that the camera is initialized.
            await _initializeControllerFuture;
            Orientation currentDeviceOrientation = MediaQuery.of(context).orientation;
            final keyContext = stickyKey.currentContext;

            Size oldPhotoSize = Size(0,0);
            Size newPhotoSize = Size(0,0);
            if (keyContext != null) {
              final box = keyContext.findRenderObject() as RenderBox;
              oldPhotoSize=box.size;
            }
            final keyContext2 = stickyKey2.currentContext;
            if (keyContext2 != null) {
              final box = keyContext2.findRenderObject() as RenderBox;
              newPhotoSize=box.size;
              print("Box2: " + box.size.toString());
            }

            bool oldPhotoRotation = false;
            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                    imagePath: image?.path,
                    newPhotoOrientation: currentDeviceOrientation,
                    oldPhotoRotation:  oldPhotoRotation,
                    oldPhotoSize: oldPhotoSize,
                    newPhotoSize: newPhotoSize,
                    currentScaleValue: currentScaleValue

                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final Orientation newPhotoOrientation;
  final bool oldPhotoRotation;
  final Size oldPhotoSize;
  final Size newPhotoSize;
  final double currentScaleValue;

  const DisplayPictureScreen({
    Key key,
    this.imagePath,
    this.newPhotoOrientation,
    this.oldPhotoRotation,
    this.oldPhotoSize,
    this.newPhotoSize,
    this.currentScaleValue
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: SingleChildScrollView(
          child: Column(
              children:<Widget>[
                Image.file(File(imagePath)),
                Text('newPhotoOrientation: $newPhotoOrientation'),
                Text('oldPhotoRotation: $oldPhotoRotation'),
                Text('oldPhotoSize: $oldPhotoSize'),
                Text('newPhotoSize: $newPhotoSize'),
                Text('currentScaleValue: $currentScaleValue'),
              ]
          ),
        )
    );
  }
}