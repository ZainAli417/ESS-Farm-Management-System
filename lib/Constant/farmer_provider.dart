import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turf/turf.dart' as turf;
import '../farm_model.dart';
import '../geoflutter/src/geoflutterfire.dart';

class MapDrawingProvider with ChangeNotifier {
  GoogleMapController? mapController;
  LatLng initialPoint = const LatLng(37.7749, -122.4194);
  bool isDrawing = false;
  bool _toolSelected = false;
  String currentTool = "";
  LatLng? initialPointForDrawing;
  final Geoflutterfire geo = Geoflutterfire();
  String _tempFarmName = "";

  // UI and state management
  bool isFarmSelected = false;
  FarmPlot? selectedFarm;
  final TextEditingController farmNameController = TextEditingController();

  // Drawing state
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

  Set<Polygon> get allPolygons => {
    ...polygons,
    if (isDrawing && (currentTool == "rectangle" || currentTool == "freehand"))
      Polygon(
        polygonId: const PolygonId('preview'),
        points: currentPolygonPoints,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
  };

  Set<Polyline> get allPolylines => {
    ...polylines,
    if (isDrawing && currentTool == "marker" && polylinePoints.isNotEmpty)
      Polyline(
        polylineId: const PolylineId('preview'),
        points: polylinePoints,
        color: Colors.blue.withOpacity(0.3),
        width: 2,
        patterns: [PatternItem.dot],
      ),
  };

  Set<Marker> get allMarkers => markers.toSet();
  Set<Circle> get allCircles => {
    ...circles,
    if (isDrawing && currentTool == "circle" && initialPointForDrawing != null)
      Circle(
        circleId: const CircleId('preview'),
        center: initialPointForDrawing!,
        radius: circleRadius,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
  };
  List<LatLng> currentPolylinePoints = [];


  void addMarkerAndUpdatePolyline(LatLng point) {
    // Check if the current tool is marker
    if (currentTool != "marker") return;

    // Create a new marker
    final marker = Marker(
      markerId: MarkerId('marker_${DateTime.now().millisecondsSinceEpoch}'),
      position: point,
    );

    // Add marker to the markers list
    markers.add(marker);
    currentPolylinePoints.add(point); // Keep track of points for polyline

    // Check if we need to update the polylines
    if (currentPolylinePoints.length > 1) {
      _updatePolylines();
    }

    // Check if the last marker tapped is the first one to close the polygon
    if (currentPolylinePoints.length > 2 && point == currentPolylinePoints.first) {
      finalizePolylineAndCreateFarm(); // Finalize polygon if tapped first marker
    }

    notifyListeners(); // Notify listeners to rebuild UI
  }

  void _updatePolylines() {
    polylines.clear();

    if (currentPolylinePoints.length > 1) {
      // Draw the polylines connecting the markers
      for (int i = 0; i < currentPolylinePoints.length - 1; i++) {
        polylines.add(Polyline(
          polylineId: PolylineId('polyline_$i'),
          points: [currentPolylinePoints[i], currentPolylinePoints[i + 1]],
          color: Colors.blue,
          width: 3,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ));
      }
    }
  }

  void finalizePolylineAndCreateFarm() {
    if (currentPolylinePoints.length < 3) return; // Need at least 3 points to create a polygon

    // Create a closed polygon with the polyline points
    List<LatLng> polygonPoints = List.from(currentPolylinePoints)
      ..add(currentPolylinePoints.first); // Close the polygon by adding the first point again

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

    farms.add(farm); // Add the farm to the list

    // Create the polygon and add it to the polygons list
    polygons.add(
      Polygon(
        polygonId: PolygonId(farm.id),
        points: polygonPoints,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.15), // Set the fill color
        strokeWidth: 2,
      ),
    );

    // Clear current polyline points for the next drawing
    currentPolylinePoints.clear();
    polylines.clear(); // Clear existing polylines
    notifyListeners(); // Notify listeners to update the UI
  }



  void setCurrentTool(String tool) {
    if (tool == "hand") {
      // Hand tool selected: disable drawing and reset any temporary drawing state.
      isDrawing = false;

      // Set _toolSelected to false so that the map remains interactive.
      _toolSelected = false;
      // Optionally, if you don’t want to store "hand" as a drawing tool,
      // you could also set currentTool = "" instead.
      currentTool = "";
    } else {
      // For any drawing tool, enable drawing mode.
      currentTool = tool;
      _toolSelected = true;
    }
    notifyListeners();
  }


  // ✅ Fixed: Define `startDrawing`
  void startDrawing(String tool, LatLng point) {
    isDrawing = true;
    currentTool = tool;
    initialPointForDrawing = point;
    currentPolygonPoints.clear();
    if (tool == "marker") polylinePoints.clear();
    notifyListeners();
  }

  // ✅ Fixed: Define `updateDrawing`
  void updateDrawing(LatLng point) {
    currentDragPoint = point;
    switch (currentTool) {
      case "circle":
        circleRadius = _calculateDistance(initialPointForDrawing!, currentDragPoint!);
        break;
      case "rectangle":
        currentPolygonPoints = _getRectanglePoints(initialPointForDrawing!, currentDragPoint!);
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

// ✅ Fixed: Update finalizeDrawing method
  List<Polygon> _tempPolygons = [];
  List<Marker> _tempMarkers = [];

// Update the finalizeDrawing method
  void finalizeDrawing(BuildContext context) {
    if ((currentTool == "rectangle" || currentTool == "freehand") &&
        currentPolygonPoints.isNotEmpty) {

      // Add to temporary polygons
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
      // Reset only the current drawing state
      currentPolygonPoints.clear();
      isDrawing = false;
    }
    notifyListeners();
  }

// ✅ Update _showFarmDetailsDialog method for discard button
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
                _FarmDetailsRow(title: "Area:", value: _formatArea(area ?? 0.0)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  clearCurrentFarm(); // Clear only the current farm being plotted
                  Navigator.pop(context);
                  _resetToolSelection();
                  notifyListeners();
                },
                child: const Text("Discard"),
              ),
              ElevatedButton(
                onPressed: _tempFarmName.isNotEmpty
                    ? () {
                  _saveFarmPlot(context, farmId, area ?? 0.0);
                  // Transfer temporary shapes to the permanent lists
                  polygons.addAll(_tempPolygons);
                  markers.addAll(_tempMarkers);
                  _tempPolygons.clear(); // Clear temp lists
                  _tempMarkers.clear();
                  Navigator.pop(context);
                  _resetToolSelection(); // Reset tool selection after saving
                }
                    : null,
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    _resetToolSelection(); // Ensures reset after dialog closes
  }

// New method to clear only the current farm being plotted
  void clearCurrentFarm() {
    currentPolygonPoints.clear();
    currentPolylinePoints.clear();
    _tempMarkers.clear(); // Clear only temporary markers for the current farm
    isDrawing = false;
    notifyListeners(); // Notify listeners to update the UI
  }

  void _resetToolSelection() {
    currentTool = "";
    _toolSelected = false;
    notifyListeners();
  }

  // ✅ Load farms from Firestore and plot them
  void loadFarms() {
    FarmPlot.loadFarms().listen((loadedFarms) {
      if (loadedFarms.isNotEmpty) {
        farms.addAll(loadedFarms);
      }

      // Populate polygons from loaded farms
      polygons.clear(); // Clear existing polygons before adding new ones
      for (var farm in farms) {
        polygons.add(
          Polygon(
            polygonId: PolygonId(farm.id),
            points: farm.coordinates,
            fillColor: Colors.green.withOpacity(0.3),
            strokeColor: Colors.green,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () => selectFarm(farm), // Allow selection on tap
          ),
        );
      }

      notifyListeners();
    });
  }


  // ✅ Select a farm to show details in the animated container
  void selectFarm(FarmPlot farm) {
    selectedFarm = farm;
    farmNameController.text = farm.name;
    isFarmSelected = true;

    // Animate the camera to the farm's polygon coordinates
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
          100, // Add some padding
        ),
      );
    }

    notifyListeners();
  }

  // ✅ Update farm name in Firestore
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

  // ✅ Close farm details container
  void closeFarmDetails() {
    isFarmSelected = false;
    selectedFarm = null;
    notifyListeners();
  }

  Future<void> _saveFarmPlot(BuildContext context, String id, double area) async {
    if (currentPolygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No coordinates found for the farm!")),
      );
      return; // Prevents crash
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
        coordinates: List.from(currentPolygonPoints), // Ensures data is valid
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

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    loadFarms(); // ✅ Load farms when map initializes
    notifyListeners();
  }

  // ✅ Prevents map interactions when UI elements are clicked
  bool isMapInteractionAllowed() => !isFarmSelected && !_toolSelected;

  // ❌ No changes below this line (keeps existing functionality)
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    final turfPolygon = turf.Polygon(
      coordinates: [
        points.map((p) => turf.Position(p.longitude, p.latitude)).toList()
      ],
    );
    return (turf.area(turfPolygon) ?? 0.0).toDouble();
  }

// Add this method to the MapDrawingProvider class
  void placeMarker(LatLng point) {
    if (currentTool == "marker") {
      // Place the marker
      markers.add(
        Marker(
          markerId: MarkerId(DateTime.now().toString()),
          position: point,
        ),
      );

      // Check if we need to close the polygon
      if (markers.length >= 2) {
        // Check if the first and last marker are the same
        if (markers.first.position == markers.last.position) {
          // Create a closed polygon with the polyline
          polylines.add(Polyline(
            polylineId: PolylineId(DateTime.now().toString()),
            points: markers.map((m) => m.position).toList(),
            color: Colors.blue,
            width: 3,
          ));
        }
      }

      notifyListeners(); // Notify listeners to update the UI
    }
  }

  String _formatArea(double area) => area > 10000
      ? '${(area / 10000).toStringAsFixed(2)} ha'
      : '${area.toStringAsFixed(2)} m²';





  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371e3;
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLng / 2) * sin(dLng / 2);
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
