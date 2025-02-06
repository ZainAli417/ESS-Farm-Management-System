import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turf/turf.dart' as turf;
import '../farm_model.dart';
import '../geoflutter/src/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';

class MapDrawingProvider with ChangeNotifier {
  GoogleMapController? mapController;
  bool isDrawing = false;
  bool _toolSelected = false;
  String currentTool = "hand";
  LatLng? initialPointForDrawing;
  final Geoflutterfire geo = Geoflutterfire();
  String _tempFarmName = "";

  // UI and state management
  bool isFarmSelected = false;
  FarmPlot? selectedFarm;
  final TextEditingController farmNameController = TextEditingController();
  LatLng initialPoint = const LatLng(37.7749, -122.4194);
  // Drawing state
  bool isLoading = false; // Track loading state
  LatLng? currentDragPoint;
  List<Polygon> polygons = [];
  List<Circle> circles = [];
  List<Marker> markers = [];
  List<LatLng> polylinePoints = [];
  List<Polyline> polylines = [];
  List<LatLng> currentPolygonPoints = [];
  double circleRadius = 0.0;
  List<FarmPlot> farms = [];
  bool get toolSelected => _toolSelected;
  List<Polygon> _tempPolygons = [];
  List<Marker> _tempMarkers = [];
  List<LatLng> currentPolylinePoints = [];
  Set<Marker> get allMarkers => {
        ...markers,
        ..._tempMarkers,
      };
  Set<Polygon> get allPolygons => {
        ...polygons,
        if (isDrawing &&
            (currentTool == "rectangle" || currentTool == "freehand"))
          Polygon(
            polygonId: const PolygonId('preview'),
            points: currentPolygonPoints,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
      };
  Set<Polyline> get allPolylines {
    final Set<Polyline> lines = {
      ...polylines, // permanent polylines (already saved)
    };

    if (currentTool == "marker") {
      // Always draw a polyline connecting all tapped markers.
      if (currentPolylinePoints.length > 1) {
        lines.add(
          Polyline(
            polylineId: const PolylineId('preview_marker'),
            points: currentPolylinePoints,
            color: Colors.blue.withOpacity(0.3),
            width: 2,
            patterns: [PatternItem.dot],
          ),
        );
      } else if (currentPolylinePoints.length == 1) {
        // If there is only one marker, you might decide to display a very short line
        // or nothing. This example does nothing.
      }

      // If you are tracking cursor movements and have a drag point, add a preview line
      // from the last marker to the current cursor position.
      if (currentPolylinePoints.isNotEmpty && currentDragPoint != null) {
        lines.add(
          Polyline(
            polylineId: const PolylineId('preview_drag'),
            points: [currentPolylinePoints.last, currentDragPoint!],
            color: Colors.blue.withOpacity(0.3),
            width: 2,
            patterns: [PatternItem.dot],
          ),
        );
      }
    }

    // If using rectangle or freehand tools, you already have logic for a preview:
    if (isDrawing &&
        (currentTool == "rectangle" || currentTool == "freehand") &&
        currentPolygonPoints.isNotEmpty) {
      lines.add(
        Polyline(
          polylineId: const PolylineId('preview_polygon'),
          points: currentPolygonPoints,
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      );
    }

    return lines;
  }
  String _selectedAreaUnit = 'ha';
  String get selectedAreaUnit => _selectedAreaUnit;
  Set<Circle> get allCircles => {
        ...circles,
        if (isDrawing &&
            currentTool == "circle" &&
            initialPointForDrawing != null)
          Circle(
            circleId: const CircleId('preview'),
            center: initialPointForDrawing!,
            radius: circleRadius,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
      };
  List<Polyline> _tempPolylines = []; // Temporary polylines for current drawing
  bool isFarmDetailsVisible = false;
  MapType _mapType = MapType.satellite;
  MapType get mapType => _mapType;
  final List<MapType> mapTypes = [
    MapType.normal,
    MapType.satellite,
    MapType.hybrid
  ];
  void setMapController(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(poistyle);
    loadFarms();
    getCurrentLocation();
  }
  static const String poistyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';
  Future<void> getCurrentLocation() async {
    isLoading = true;
    notifyListeners();

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      isLoading = false;
      notifyListeners();
      return;
    }

    // Request location permission if needed.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        isLoading = false;
        notifyListeners();
        return;
      }
    }

    // Get current position.
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    // Update the initial point.
    initialPoint = LatLng(position.latitude, position.longitude);

    // Wait for 2 seconds before animating.
    await Future.delayed(const Duration(seconds: 5));
    animateCameraTo(initialPoint);

    // Hide loading screen
    isLoading = false;
    notifyListeners();
  }
  void animateCameraTo(LatLng latLng) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 20),
        ),
      );
    }
  }
  void setMapType(MapType newMapType) {
    _mapType = newMapType;
    notifyListeners();
  }
  Future<void> _showFarmDetailsDialog(BuildContext context) async {
    final area = _calculatePolygonArea(currentPolygonPoints);

    final farmId = 'FARM-${DateTime.now().millisecondsSinceEpoch}';
    final TextEditingController _controller = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Save Farm Plot"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Farm Name",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _tempFarmName = v;
                    });
                  },
                  onTap: () {
                    Future.delayed(Duration(milliseconds: 100), () {
                      _focusNode.requestFocus();
                    });
                  },
                ),
                const SizedBox(height: 15),
                _FarmDetailsRow(title: "Farm ID:", value: farmId),
                _FarmDetailsRow(
                    title: "Area:", value: _formatArea(area, selectedAreaUnit)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  clearCurrentFarm();
                  Navigator.pop(context);
                  _resetToolSelection();
                  notifyListeners();
                },
                child: const Text("Discard"),
              ),
              ElevatedButton(
                onPressed: _tempFarmName.isNotEmpty
                    ? () {
                        _saveFarmPlot(context, farmId, area);
                        // Transfer temporary shapes to the permanent lists
                        polygons.addAll(_tempPolygons);
                        markers.addAll(_tempMarkers);
                        _tempPolygons.clear();
                        _tempMarkers.clear();
                        Navigator.pop(context);
                        _resetToolSelection();
                      }
                    : null,
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    _resetToolSelection();
  }
  void addMarkerAndUpdatePolyline(BuildContext context, LatLng point) {
    if (currentTool != "marker") return;

    final String markerIdValue =
        'temp_marker_${DateTime.now().millisecondsSinceEpoch}';
    final MarkerId markerId = MarkerId(markerIdValue);

    // If this is the first marker, add it with a callback for closing the polygon.
    if (currentPolylinePoints.isEmpty) {
      currentPolylinePoints.add(point);
      _tempMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          onTap: () {
            // If the first marker is tapped again, close the polygon.
            if (currentPolylinePoints.isNotEmpty &&
                point == currentPolylinePoints.first) {
              _closeAndFillPolygon(context);
            }
          },
        ),
      );
      notifyListeners();
      return;
    }

    // If the tapped point is the same as the first marker, close the polygon.
    final firstPoint = currentPolylinePoints.first;
    if (point == firstPoint) {
      _closeAndFillPolygon(context);
      return;
    }

    // Otherwise, add the new marker.
    currentPolylinePoints.add(point);
    _tempMarkers.add(
      Marker(
        markerId: markerId,
        position: point,
      ),
    );

    // Optionally, update polylines if you have additional preview logic.
    _updatePolylines();
    currentDragPoint = null;
    notifyListeners();
  }
  void _closeAndFillPolygon(BuildContext context) {
    // Create a closed polygon by adding the first point at the end.
    List<LatLng> closedPolygon = List.from(currentPolylinePoints)
      ..add(currentPolylinePoints.first);

    // Set the closed polygon as the current polygon points.
    currentPolygonPoints = closedPolygon;

    // Add a temporary polygon for preview.
    _tempPolygons.add(
      Polygon(
        polygonId: PolygonId(DateTime.now().toString()),
        points: closedPolygon,
        fillColor: Colors.redAccent.withOpacity(0.4),
        strokeColor: Colors.red,
        strokeWidth: 3,
      ),
    );

    // Show the dialog to save the farm plot.
    _showFarmDetailsDialog(context);

    // When saving, add the temporary markers to the permanent markers list:
    markers.addAll(_tempMarkers);
    // Also add the temporary polylines to the permanent polylines list:
    polylines.addAll(_tempPolylines);

    // Clear the temporary data:
    _tempMarkers.clear();
    _tempPolylines.clear();
    currentPolylinePoints.clear();
    currentDragPoint = null;
    notifyListeners();
  }
  void clearCurrentFarm() {
    currentPolygonPoints.clear();
    currentPolylinePoints.clear();
    _tempMarkers.clear();
    _tempPolylines.clear();

    // Remove any temporary markers that might have been (if they ended up in permanent list)
    markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('temp_marker_'));

    isDrawing = false;
    notifyListeners();
  }
  void _updatePolylines() {
    // Remove any existing temporary marker-drawing polyline(s)
    _tempPolylines.removeWhere(
        (line) => line.polylineId.value.startsWith('temp_polyline_'));

    if (currentTool == "marker" &&
        currentPolylinePoints.isNotEmpty &&
        currentDragPoint != null) {
      _tempPolylines.add(
        Polyline(
          polylineId: PolylineId(
              'temp_polyline_${DateTime.now().millisecondsSinceEpoch}'),
          points: [currentPolylinePoints.last, currentDragPoint!],
          color: Colors.blue,
          width: 2,
          patterns: [PatternItem.dash(2)],
        ),
      );
    }

    // For rectangle or freehand drawing, update the temporary preview polyline:
    if (isDrawing &&
        (currentTool == "rectangle" || currentTool == "freehand") &&
        currentPolygonPoints.isNotEmpty) {
      _tempPolylines.removeWhere(
          (line) => line.polylineId.value == 'temp_polyline_preview');
      _tempPolylines.add(
        Polyline(
          polylineId: const PolylineId('temp_polyline_preview'),
          points: currentPolygonPoints,
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      );
    }

    notifyListeners();
  }



  void finalizePolylineAndCreateFarm() {
    if (currentPolylinePoints.length < 3) return;

    List<LatLng> polygonPoints = List.from(currentPolylinePoints)
      ..add(currentPolylinePoints.first);

    double area = _calculatePolygonArea(polygonPoints);
    final geoPoint = geo.point(
      latitude: polygonPoints.first.latitude,
      longitude: polygonPoints.first.longitude,
    );

    FarmPlot farm = FarmPlot(
      id: 'farm_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Farm ${farms.length + 1}',
      coordinates: polygonPoints,
      createdAt: DateTime.now(),
      geoHash: geoPoint.hash,
      area: area,
    );

    farms.add(farm);

    polygons.add(
      Polygon(
        polygonId: PolygonId(farm.id),
        points: polygonPoints,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeWidth: 2,
      ),
    );

    currentPolylinePoints.clear();
    polylines.clear();
    notifyListeners();
  }

  Future<void> _saveFarmPlot(BuildContext context, String id, double area) async {
    if (currentPolygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No coordinates found for the farm!")),
      );
      return;
    }

    try {
      final geoPoint = geo.point(
        latitude: currentPolygonPoints.first.latitude,
        longitude: currentPolygonPoints.first.longitude,
      );

      final newFarm = FarmPlot(
        id: id,
        name: _tempFarmName,
        area: area,
        coordinates: List.from(currentPolygonPoints),
        createdAt: DateTime.now(),
        geoHash: geoPoint.hash,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('farms')
          .doc(id)
          .set(newFarm.toMap());

      farms.add(newFarm);
      Navigator.pop(context);
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving farm: ${e.toString()}')),
      );
    }
  }

  void loadFarms() {
    FarmPlot.loadFarms().listen((loadedFarms) {
      if (loadedFarms.isNotEmpty) {
        farms.addAll(loadedFarms);
      }

      polygons.clear();
      for (var farm in farms) {
        polygons.add(
          Polygon(
            polygonId: PolygonId(farm.id),
            points: farm.coordinates,
            fillColor: Colors.green.withOpacity(0.3),
            strokeColor: Colors.green,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () => selectFarm(farm),
          ),
        );
      }

      notifyListeners();
    });
  }





  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    final turfPolygon = turf.Polygon(
      coordinates: [
        points.map((p) => turf.Position(p.longitude, p.latitude)).toList()
      ],
    );
    return (turf.area(turfPolygon) ?? 0.0).toDouble();
  }
  // New method to update the area unit
  void updateSelectedAreaUnit(String? newUnit) {
    if (newUnit == null || newUnit == _selectedAreaUnit) return;
    _selectedAreaUnit = newUnit;
    notifyListeners();
  }
  // Modified _formatArea function
  String _formatArea(double area, String unit) {
    switch (unit) {
      case 'ha':
        final converted = area / 10000;
        return '${converted.toStringAsFixed(2)} ha';

      default: // 'acres²'
        final converted = area * 0.000247105;
        return '${converted.toStringAsFixed(2)} Acres';
    }
  }
  void setCurrentTool(String tool) {
    if (tool == "hand") {
      isDrawing = false;
      _toolSelected = false;
      currentTool = "hand";
    } else {
      currentTool = tool;
      _toolSelected = true;
    }
    notifyListeners();
  }
  void startDrawing(String tool, LatLng point) {
    isDrawing = true;
    currentTool = tool;
    initialPointForDrawing = point;
    currentPolygonPoints.clear();
    if (tool == "marker") polylinePoints.clear();
    notifyListeners();
  }
  void updateDrawing(LatLng point) {
    currentDragPoint = point;
    switch (currentTool) {
      case "circle":
        circleRadius =
            _calculateDistance(initialPointForDrawing!, currentDragPoint!);
        break;
      case "rectangle":
        currentPolygonPoints =
            _getRectanglePoints(initialPointForDrawing!, currentDragPoint!);
        break;
      case "freehand":
        currentPolygonPoints.add(point);
        break;
      case "marker":
        if (polylinePoints.isNotEmpty) polylinePoints.add(point);
        break;
    }
    notifyListeners();
  }
  void finalizeDrawing(BuildContext context) {
    if ((currentTool == "rectangle" ||
            currentTool == "freehand" ||
            currentTool == "marker") &&
        currentPolygonPoints.isNotEmpty) {
      _tempPolygons.add(
        Polygon(
          polygonId: PolygonId(DateTime.now().toString()),
          points: List.from(currentPolygonPoints),
          fillColor: Colors.redAccent.withOpacity(0.4),
          strokeColor: Colors.red,
          strokeWidth: 3,
        ),
      );

      _showFarmDetailsDialog(context);
    } else {
      currentPolygonPoints.clear();
      isDrawing = false;
    }
    notifyListeners();
  }
  void _resetToolSelection() {
    currentTool = "";
    _toolSelected = false;
    notifyListeners();
  }
  void selectFarm(FarmPlot farm) {
    selectedFarm = farm;
    farmNameController.text = farm.name;
    isFarmDetailsVisible = true;

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              farm.coordinates.map((c) => c.latitude).reduce(min),
              farm.coordinates.map((c) => c.longitude).reduce(min),
            ),
            northeast: LatLng(
              farm.coordinates.map((c) => c.latitude).reduce(max),
              farm.coordinates.map((c) => c.longitude).reduce(max),
            ),
          ),
          100,
        ),
      );
    }

    notifyListeners();
  }
  void closeFarmDetails() {
    isFarmDetailsVisible = false;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      selectedFarm = null;
      notifyListeners();
    });
  }
  Future<void> updateFarmName(String newName) async {
    if (selectedFarm == null) return;

    selectedFarm!.name = newName;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('farms')
        .doc(selectedFarm!.id)
        .update({'name': newName});

    notifyListeners();
  }
  bool isMapInteractionAllowed() => !isFarmSelected && !_toolSelected;
  void placeMarker(LatLng point) {
    if (currentTool == "marker") {
      markers.add(
        Marker(
          markerId: MarkerId(DateTime.now().toString()),
          position: point,
        ),
      );

      if (markers.length >= 2) {
        if (markers.first.position == markers.last.position) {
          polylines.add(Polyline(
            polylineId: PolylineId(DateTime.now().toString()),
            points: markers.map((m) => m.position).toList(),
            color: Colors.blue,
            width: 3,
          ));
        }
      }

      notifyListeners();
    }
  }
  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371e3;
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
  double _toRadians(double degree) => degree * pi / 180;
  List<LatLng> _getRectanglePoints(LatLng start, LatLng end) => [
        start,
        LatLng(start.latitude, end.longitude),
        end,
        LatLng(end.latitude, start.longitude),
        start,
      ];
  void clearShapes() {
    polygons.clear();
    circles.clear();
    markers.clear();
    polylinePoints.clear();
    polylines.clear();
    isDrawing = false;
    notifyListeners();
  }
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}

class _FarmDetailsRow extends StatelessWidget {
  final String title;
  final String value;

  const _FarmDetailsRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
