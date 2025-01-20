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
  List<LatLng> _currentPolygonPoints = [];
  bool _isDrawing = false;
  bool _isCircleDrawing = false;
  bool _isRectangleDrawing = false;
  bool _isFreehandDrawing = false;
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

  void _startCircleDrawing(LatLng point) {
    setState(() {
      _isDrawing = true;
      _isCircleDrawing = true;
      _isRectangleDrawing = false;
      _isFreehandDrawing = false;
      _initialPoint = point;
    });
  }

  void _startRectangleDrawing(LatLng point) {
    setState(() {
      _isDrawing = true;
      _isRectangleDrawing = true;
      _isCircleDrawing = false;
      _isFreehandDrawing = false;
      _initialPoint = point;
    });
  }

  void _startFreehandDrawing() {
    setState(() {
      _isDrawing = true;
      _isFreehandDrawing = true;
      _isCircleDrawing = false;
      _isRectangleDrawing = false;
      _currentPolygonPoints.clear();
    });
  }

  void _updateDrawing(LatLng point) {
    setState(() {
      _currentDragPoint = point;
      if (_isCircleDrawing) {
        _circleRadius = _calculateDistance(_initialPoint, _currentDragPoint);
      } else if (_isRectangleDrawing) {
        _currentPolygonPoints = _getRectanglePoints(_initialPoint, _currentDragPoint);
      } else if (_isFreehandDrawing) {
        _currentPolygonPoints.add(point);
      }
    });
  }

  void _finalizeDrawing() {
    setState(() {
      _isDrawing = false;
      _isCircleDrawing = false;
      _isRectangleDrawing = false;
      _isFreehandDrawing = false;
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
      body: MouseRegion(
        cursor: _isDrawing ? SystemMouseCursors.precise : SystemMouseCursors.basic,
        child: GestureDetector(
          onPanStart: (details) async {
            if (_mapController != null) {
              LatLng point = await _mapController.getLatLng(
                ScreenCoordinate(
                  x: details.localPosition.dx.toInt(),
                  y: details.localPosition.dy.toInt(),
                ),
              );
              if (_isCircleDrawing) {
                _startCircleDrawing(point);
              } else if (_isRectangleDrawing) {
                _startRectangleDrawing(point);
              } else if (_isFreehandDrawing) {
                setState(() {
                  _currentPolygonPoints.add(point);
                });
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
              if (_isRectangleDrawing || _isFreehandDrawing)
                Polygon(
                  polygonId: const PolygonId('drawing'),
                  points: _currentPolygonPoints,
                  fillColor: Colors.blue.withOpacity(0.5),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                ),
            },
            circles: {
              if (_isCircleDrawing)
                Circle(
                  circleId: const CircleId('circle'),
                  center: _initialPoint,
                  radius: _circleRadius,
                  fillColor: Colors.blue.withOpacity(0.5),
                  strokeColor: Colors.blue,
                  strokeWidth: 2,
                ),
            },
          ),
        ),

      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _startFreehandDrawing,
            child: const Icon(Icons.brush),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _startRectangleDrawing(_initialPoint);
            },
            child: const Icon(Icons.crop_square),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _startCircleDrawing(_initialPoint);
            },
            child: const Icon(Icons.radio_button_checked),
          ),
        ],
      ),
    );
  }
}
