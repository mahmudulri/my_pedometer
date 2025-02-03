import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PedometerScreen(),
    );
  }
}

class PedometerScreen extends StatefulWidget {
  const PedometerScreen({super.key});

  @override
  _PedometerScreenState createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  StreamSubscription<StepCount>? _subscription;
  int _stepCount = 0;
  int _initialStepCount = 0;
  bool _isTracking = false;
  String _status = "Paused";
  Timer? _timer;
  Timer? _stepCheckTimer;
  int _secondsElapsed = 0;
  int _lastStepCount = 0;
  bool _timerRunning = false;

  final double _stepLength = 0.78; // Step length in meters
  double _userWeight = 70.0; // Default user weight in kg
  String _selectedUnit = "km"; // Default distance unit

  final Map<String, double> _unitConversion = {
    "km": 1.0,
    "m": 1000.0,
    "mi": 0.621371,
  };

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await Permission.activityRecognition.request();
  }

  void _startTracking() {
    if (_isTracking) return;

    _subscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        setState(() {
          if (_initialStepCount == 0) {
            _initialStepCount = event.steps;
          }
          _stepCount = event.steps - _initialStepCount;
          _status = "Walking";
          _startTimerIfNeeded();
        });
      },
      onError: (error) => print("Error: $error"),
    );

    _monitorStepActivity();

    setState(() {
      _isTracking = true;
      _status = "Walking";
    });
  }

  void _stopTracking() {
    _subscription?.cancel();
    _stopTimer();
    _stepCheckTimer?.cancel();

    setState(() {
      _isTracking = false;
      _status = "Paused";
    });
  }

  void _resetSteps() {
    _stopTracking();
    setState(() {
      _stepCount = 0;
      _initialStepCount = 0;
      _secondsElapsed = 0;
    });
  }

  void _startTimerIfNeeded() {
    if (!_timerRunning) {
      _timerRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (_isTracking && _status == "Walking") {
          setState(() => _secondsElapsed++);
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  void _monitorStepActivity() {
    _stepCheckTimer?.cancel();
    _stepCheckTimer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      if (_stepCount == _lastStepCount) {
        // Walking stopped, stop the timer
        _stopTimer();
        setState(() {
          _status = "Paused";
        });
      } else {
        if (_status == "Paused") {
          setState(() {
            _status = "Walking";
          });
          _startTimerIfNeeded(); // Resume timer when walking resumes
        }
      }
      _lastStepCount = _stepCount;
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return "$minutes min ${remainingSeconds}s";
  }

  double _calculateCalories() {
    return (_stepCount * _userWeight * 0.0005);
  }

  double _calculateDistance() {
    double distanceKm = (_stepCount * _stepLength) / 1000;
    return distanceKm * _unitConversion[_selectedUnit]!;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    _stepCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pedometer App")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  "Steps: $_stepCount",
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Time: ${_formatTime(_secondsElapsed)}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(
                  "Status: $_status",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _status == "Walking" ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Distance: ${_calculateDistance().toStringAsFixed(2)} $_selectedUnit",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  "Calories Burned: ${_calculateCalories().toStringAsFixed(2)} kcal",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Weight (kg): ",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "70",
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _userWeight = double.tryParse(value) ?? 70.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: _selectedUnit,
                        items: const [
                          DropdownMenuItem(
                              value: "km", child: Text("Kilometers (km)")),
                          DropdownMenuItem(
                              value: "m", child: Text("Meters (m)")),
                          DropdownMenuItem(
                              value: "mi", child: Text("Miles (mi)")),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUnit = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: _startTracking, child: const Text("Start")),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: _stopTracking, child: const Text("Stop")),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: _resetSteps, child: const Text("Reset")),
            ],
          ),
        ],
      ),
    );
  }
}
