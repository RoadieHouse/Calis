import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_app/screens/main.dart';
import 'package:provider/provider.dart';
import '../models/mp_pose_estimation.dart';
import 'pose_data_table_screen.dart';
import '../utils/mp_camera_input_utils.dart';
import 'package:my_app/services/provider_class.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/pose_painter.dart';
import '../models/yolo_tflite_pose_estimation.dart';

//-----------------------------------------------------------------------------------------------------------------------------------------------
// Camera screen
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

// State class for the CameraScreen widget
class CameraScreenState extends State<CameraScreen> {
  // track camera controller
  bool _isCameraControllerInitialized = false;

  // Instances of pose estimation services
  PoseEstimationMediapipe poseEstimationMediapipe = PoseEstimationMediapipe();
  PoseEstimationYOLO poseEstimationYolo = PoseEstimationYOLO();

  void updatePoseEstimationStatus(bool newValue) {
    final statusPoseEstimation = context.read<PoseEstimationProvider>();
    statusPoseEstimation.value = newValue;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isCameraControllerInitialized) {
        // Dispose of the existing camera controller
        controller?.dispose();
      }

      await requestCameraPermission();
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        camera = cameras.first;
        controller = CameraController(
          camera!,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );

        try {
          await controller!.initialize();
          _isCameraControllerInitialized = true;
          if (!mounted) return;
          setState(() {});
        } on CameraException catch (e) {
          // Handle the camera exception
          debugPrint('Error initializing camera: $e');
        }
      } else {
        // Handle the case where no cameras are available
        Fluttertoast.showToast(
            msg: "No cameras were found, please try again",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _isCameraControllerInitialized = false;
    super.dispose();
  }

  void _updatePose() {
    if (mounted) {
      setState(() {});
    }
  }

//-----------------------------------------------------------------------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Check if the camera controller is initialized
    if (controller == null ||
        !controller!.value.isInitialized ||
        _isCameraControllerInitialized == false) {
      return const Center(
        child: SpinKitChasingDots(
          color: primaryColor,
          size: 50.0,
        ),
      );
    }

    // Get the most recent PoseEstimationData object
    final poseData = poseEstimationMediapipe.completePoseData.isNotEmpty
        ? poseEstimationMediapipe.completePoseData.last
        : null;
//------------------------------------------------------------------------------
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1 /
                  (controller!.value.aspectRatio *
                      MediaQuery.of(context).size.aspectRatio),
              child: Center(
                child: CameraPreview(controller!),
              ),
            ),
            if (context.watch<PoseEstimationProvider>().value &&
                poseEstimationMediapipe.completePoseData.isNotEmpty)
              CustomPaint(
                painter: PosePainterMediapipe(
                  pose: poseData!,
                  imageSize: Size(
                    controller!.value.previewSize!.height,
                    controller!.value.previewSize!.width,
                  ),
                  lensDirection: camera!.lensDirection,
                ),
              ),
            // Footer button area
            Positioned(
              bottom: 5,
              left: 20,
              right: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                        color: thirdColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: primaryColor, width: 3)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch camera button
                        Opacity(
                          opacity: context.watch<PoseEstimationProvider>().value
                              ? 0.5
                              : 1,
                          child: Stack(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 50, minHeight: 50),
                              ),
                              Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.switch_camera,
                                    color: primaryColor,
                                  ),
                                  onPressed: context
                                          .watch<PoseEstimationProvider>()
                                          .value
                                      ? null
                                      : _switchCamera,
                                  padding: EdgeInsets.zero,
                                  iconSize: 45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Center(child: SizedBox(width: 130)), // Spacer
                        // Table button
                        Opacity(
                          opacity: poseEstimationMediapipe
                                      .completePoseData.isEmpty ||
                                  context.watch<PoseEstimationProvider>().value
                              ? 0.5
                              : 1,
                          child: Stack(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 50, minHeight: 50),
                              ),
                              Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.table_chart,
                                    color: primaryColor,
                                  ),
                                  iconSize: 45,
                                  onPressed: poseEstimationMediapipe
                                              .completePoseData.isEmpty ||
                                          context
                                              .watch<PoseEstimationProvider>()
                                              .value
                                      ? null
                                      : () async {
                                          try {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => PoseDataTable(
                                                    poseData:
                                                        poseEstimationMediapipe
                                                            .completePoseData),
                                              ),
                                            );
                                          } on PlatformException catch (e) {
                                            // Handle the platform exception
                                            debugPrint(
                                                'Error navigating to pose data screen: $e');
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  // Middle button with circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(1),
                            border: Border.all(color: thirdColor, width: 3)),
                        constraints:
                            const BoxConstraints(minWidth: 110, minHeight: 110),
                      ),
                      IconButton(
                        icon: Icon(
                          context.watch<PoseEstimationProvider>().value
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline_sharp,
                          color: thirdColor,
                          size: 100,
                        ),
                        onPressed: () {
                          if (context.read<PoseEstimationProvider>().value) {
                            setState(() {
                              updatePoseEstimationStatus(false);
                            });
                            poseEstimationYolo.disableYOLOPoseEstimation();
                          } else {
                            setState(() {
                              updatePoseEstimationStatus(true);
                            });
                            poseEstimationYolo
                                .enableYOLOPoseEstimation(_updatePose);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }

//------------------------------------------------------------------------------

  // Function to switch between pose estimation models
  void choosePoseEstimationModel(String model) {
    //used to use the functions of the choosen model from a dropdown list
  }

  // Function to switch between cameras
  Future<void> _switchCamera() async {
    // Check if there are cameras available
    if (cameras.isEmpty) return;

    // Dispose of the current controller
    await controller?.pausePreview();

    // Get the index of the current camera
    int newIndex = (cameras.indexOf(camera!) + 1) % cameras.length;
    camera = cameras[newIndex];
    // Switch to the next camera (circularly)

    // Set the new current camera
    camera = cameras[newIndex];

    // Reinitialize controller with the new camera
    controller = CameraController(
      camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});
      await controller?.resumePreview();
    } on CameraException catch (e) {
      // Handle the camera exception
      debugPrint('Error initializing camera: $e');
    }
  }
}
