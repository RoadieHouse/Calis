import "package:flutter/material.dart";
import 'package:provider/provider.dart';

final globalProvider = ChangeNotifierProvider<PoseEstimationProvider>(
  create: (_) => PoseEstimationProvider(),
);

class PoseEstimationProvider extends ChangeNotifier {
  bool _isPoseEstimationRunning = false;

  bool get value => _isPoseEstimationRunning;

  set value(bool newValue) {
    _isPoseEstimationRunning = newValue;
    notifyListeners();
  }
}
