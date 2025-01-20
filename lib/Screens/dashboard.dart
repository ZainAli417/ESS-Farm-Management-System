import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  List<Polygon> _polygons = [];
  List<Circle> _circles = [];
  List<LatLng> _currentPolygonPoints = [];
  bool _isDrawing = false;
  String _currentTool = ""; // "circle", "rectangle", or "freehand"
  late LatLng _initialPoint;
  late LatLng _currentDragPoint;
  double _circleRadius = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  void _getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _initialPoint = LatLng(position.latitude, position.longitude);
    });
  }

  void _startDrawing(String tool, LatLng point) {
    setState(() {
      _isDrawing = true;
      _currentTool = tool;
      _initialPoint = point;
      _currentPolygonPoints.clear();
    });
  }

  void _updateDrawing(LatLng point) {
    setState(() {
      _currentDragPoint = point;
      if (_currentTool == "circle") {
        _circleRadius = _calculateDistance(_initialPoint, _currentDragPoint);
      } else if (_currentTool == "rectangle") {
        _currentPolygonPoints = _getRectanglePoints(_initialPoint, _currentDragPoint);
      } else if (_currentTool == "freehand") {
        _currentPolygonPoints.add(point);
      }
    });
  }

  void _finalizeDrawing() {
    setState(() {
      if (_currentTool == "circle") {
        _circles.add(
          Circle(
            circleId: CircleId(DateTime.now().toString()),
            center: _initialPoint,
            radius: _circleRadius,
            fillColor: Colors.redAccent.withOpacity(0.4),
            strokeColor: Colors.red,
            strokeWidth: 3,
          ),
        );
      } else if (_currentTool == "rectangle" || _currentTool == "freehand") {
        _polygons.add(
          Polygon(
            polygonId: PolygonId(DateTime.now().toString()),
            points: List.from(_currentPolygonPoints),
            fillColor: Colors.redAccent.withOpacity(0.4),
            strokeColor: Colors.red,
            strokeWidth: 3,
          ),
        );
      }
      _isDrawing = false;
    });
  }

  void _clearShapes() {
    setState(() {
      _polygons.clear();
      _circles.clear();
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double radius = 6371e3; // Earth's radius in meters
    double dLat = _toRadians(point2.latitude - point1.latitude);
    double dLng = _toRadians(point2.longitude - point1.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) *
            cos(_toRadians(point2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  List<LatLng> _getRectanglePoints(LatLng start, LatLng end) {
    return [
      start,
      LatLng(start.latitude, end.longitude),
      end,
      LatLng(end.latitude, start.longitude),
      start,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanStart: (details) async {
          if (_mapController != null) {
            LatLng point = await _mapController.getLatLng(
              ScreenCoordinate(
                x: details.localPosition.dx.toInt(),
                y: details.localPosition.dy.toInt(),
              ),
            );
            if (_currentTool.isNotEmpty) {
              _startDrawing(_currentTool, point);
            }
          }
        },
        onPanUpdate: (details) async {
          if (_isDrawing && _mapController != null) {
            LatLng point = await _mapController.getLatLng(
              ScreenCoordinate(
                x: details.localPosition.dx.toInt(),
                y: details.localPosition.dy.toInt(),
              ),
            );
            _updateDrawing(point);
          }
        },
        onPanEnd: (details) {
          if (_isDrawing) {
            _finalizeDrawing();
          }
        },
        child: GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _initialPoint,
            zoom: 15,
          ),
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          polygons: {
            ..._polygons,
            if ((_isDrawing && (_currentTool == "rectangle" || _currentTool == "freehand")))
              Polygon(
                polygonId: const PolygonId('preview'),
                points: _currentPolygonPoints,
                fillColor: Colors.blue.withOpacity(0.3),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
          },
          circles: {
            ..._circles,
            if (_isDrawing && _currentTool == "circle")
              Circle(
                circleId: const CircleId('preview'),
                center: _initialPoint,
                radius: _circleRadius,
                fillColor: Colors.blue.withOpacity(0.3),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentTool = "freehand";
              });
            },
            child: const Icon(Icons.brush),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentTool = "rectangle";
              });
            },
            child: const Icon(Icons.crop_square),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _currentTool = "circle";
              });
            },
            child: const Icon(Icons.radio_button_checked),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _clearShapes,
            child: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}
