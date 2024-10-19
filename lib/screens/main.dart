import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:my_app/services/provider_class.dart';
import 'package:wave/config.dart';
import 'camera_screen.dart';
import 'package:provider/provider.dart';
import 'package:wave/wave.dart';

//----------------------------------------------------------------------------------------------------
// The colors of the app
const Color primaryColor = Color(0xFF64C6A0);
const Color secondaryColor = Color(0xFF262A29);
const Color thirdColor = Color(0xFF0D0628);

var logger = Logger();

//----------------------------------------------------------------------------------------------------
// Entry point of the application
void main() async {
  // Ensure that all the necessary resources are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded<Future<void>>(() async {
    // ...
  }, (Object error, StackTrace stackTrace) {
    // Handle the error
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
    ));
  });

  // Run the application with CALIS as the root widget
  runApp(const CALIS());
}

// Root application widget
class CALIS extends StatefulWidget {
  // Constructor for CALIS widget
  const CALIS({super.key});

  @override
  // Create the state for CALIS widget
  MyAppState createState() => MyAppState();
}

final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

// State for CALIS widget
class MyAppState extends State<CALIS> {
  @override
  // Build the UI for CALIS widget
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PoseEstimationProvider>(
      create: (_) => PoseEstimationProvider(),
      // Set up the theme and home screen for the application
      child: MaterialApp(
        scaffoldMessengerKey: _scaffoldKey,
        // Adds a performance bar
        showPerformanceOverlay: false,
        // Disable the debug banner
        debugShowCheckedModeBanner: false,
        // Set the title of the application
        title: 'Preliminary CALIS App',
        // Define the theme for the application
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: thirdColor,
        ),
        // Set the home screen for the application
        home: const HomeScreen(),
      ),
    );
  }
}

//----------------------------------------------------------------------------------------------------
// Home screen of the application
class HomeScreen extends StatefulWidget {
  // Constructor for HomeScreen widget
  const HomeScreen({super.key});

  @override
  // Create the state for HomeScreen widget
  HomeScreenState createState() => HomeScreenState();
}

// State for HomeScreen widget
class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final double _initialRadius = .1;
  late AnimationController _animationController;

  @override
  initState() {
    super.initState();
    _animationController = AnimationController(
        value: 40,
        vsync: this,
        duration: const Duration(milliseconds: 3500),
        reverseDuration: const Duration(microseconds: 3500));
    _animationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI for HomeScreen widget

    // Navigate to the camera screen
    Future<void> goToCamera(BuildContext context) async {
      // Push the CameraScreen widget onto the navigation stack
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraScreen(),
        ),
      );

      // Call setState to rebuild the HomeScreen widget
      setState(() {});
    }

    return Scaffold(
        body: Stack(
      children: [
        // This is the Expanded container that will be behind everything else
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: MediaQuery.of(context).size.height / 1.4,
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 0.0, // Set elevation to 0 to remove shadow
              margin: EdgeInsets.zero, // Remove any margins
              clipBehavior: Clip.antiAlias,
              color: thirdColor, // Make the card's background transparent
              shape: const LinearBorder(),
              child: WaveWidget(
                config: CustomConfig(
                  gradients: const [
                    [
                      Color.fromARGB(70, 8, 4, 74),
                      Color.fromARGB(70, 8, 4, 74)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(85, 17, 31, 87),
                      Color.fromARGB(85, 4, 22, 94)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(95, 9, 31, 99),
                      Color.fromARGB(95, 18, 34, 114)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(115, 13, 82, 90),
                      Color.fromARGB(115, 16, 55, 78)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(105, 4, 30, 50),
                      Color.fromARGB(105, 13, 30, 50)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(129, 76, 160, 175),
                      Color.fromARGB(129, 68, 163, 168)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(140, 84, 207, 197),
                      Color.fromARGB(140, 76, 192, 182)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(188, 96, 226, 204),
                      Color.fromARGB(188, 97, 228, 206)
                    ],
                    [thirdColor, thirdColor],
                    [
                      Color.fromARGB(220, 68, 219, 166),
                      Color.fromARGB(220, 60, 224, 175)
                    ],
                  ],
                  durations: [
                    14000,
                    15000,
                    15000,
                    13000,
                    13000,
                    17000,
                    17000,
                    13500,
                    13500,
                    20000,
                    20000,
                    12500,
                    12500,
                    18000,
                    18000,
                    20000,
                    20000,
                  ],
                  heightPercentages: [
                    0,
                    0.06,
                    0.09,
                    0.16,
                    0.19,
                    0.28,
                    0.31,
                    0.37,
                    0.40,
                    0.47,
                    0.50,
                    0.58,
                    0.61,
                    0.70,
                    0.73,
                    0.81,
                    0.84
                  ],
                  gradientBegin: Alignment.bottomLeft,
                  gradientEnd: Alignment.bottomLeft,
                ),
                backgroundColor: thirdColor,
                size: Size(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height / 1.4,
                ),
                waveAmplitude: 10,
              ),
            ),
          ),
        ),
        Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // A text widget with a custom font and style
          Padding(
            padding: const EdgeInsets.only(bottom: 125),
            child: Stack(
              children: <Widget>[
                // Text with stroke
                Text(
                  'CALIS',
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 99,
                    letterSpacing: 15,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                          offset: Offset(-6.5, 5),
                          color: Color.fromARGB(255, 0, 66, 62))
                    ],
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 6
                      ..color = thirdColor,
                  ),
                ),
                // Text with fill
                const Text(
                  'CALIS',
                  style: TextStyle(
                    fontFamily: 'Barlow',
                    fontSize: 99,
                    letterSpacing: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 65),
          AnimatedBuilder(
              animation: _animationController,
              builder: (_, child) {
                return Transform.scale(
                  scale: 1 + _animationController.value * _initialRadius,
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    radius: MediaQuery.of(context).size.width / 2.9,
                    backgroundColor: thirdColor,
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 3.0,
                      backgroundColor: const Color.fromARGB(255, 100, 198, 160),
                      child: IconButton(
                        icon: CircleAvatar(
                            radius: MediaQuery.of(context).size.width / 3.2,
                            backgroundImage:
                                Image.asset("assets/images/logo_dark_1.png")
                                    .image),
                        onPressed: () => goToCamera(context),
                      ),
                    ),
                  ),
                );
              }),
        ]))
      ],
    ));
  }
}
