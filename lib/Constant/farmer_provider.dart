import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
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
  void setMapController(BuildContext context, GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(poistyle);
    loadFarms(context); // Pass the context here
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

    // New temporary state variables
    DateTime _tempSowingDate = DateTime.now();
    String _tempFertility = 'Medium';
    String _tempSoilType = 'Sandy';
    bool _tempPesticideUsage = false;
    int _tempSeedsPerHectare = 0;
    String _tempFarmName = ''; // Initialize _tempFarmName

    await showModalBottomSheet( // Changed to showModalBottomSheet
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent, // Make background transparent for blur
      builder: (context) => BackdropFilter( // Add BackdropFilter for blur
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container( // Container for bottom sheet styling
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8), // Silver White background for bottom sheet
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)), // Rounded top corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Increased padding for better spacing
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Save Farm Plot",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          fontSize: 28, // Increased title font size
                          color: const Color(0xFF643905), // Dark green for title
                        ),
                      ),
                      const SizedBox(height: 24), // Increased spacing below title
                      // Crop Name / Farm Name (already added)
                      TextFormField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: false, // Disable autofocus for bottom sheet
                        decoration: InputDecoration(
                          labelText: "Crop Name / Farm Name",
                          labelStyle: GoogleFonts.quicksand(color: const Color(
                              0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Focused border color
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white, // White fill for text field
                        ),
                        cursorColor: const Color(0xFF643905), // Dark green cursor
                        onChanged: (v) {
                          setState(() {
                            _tempFarmName = v;
                          });
                        },
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      // Sowing Date using Calendar
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tempSowingDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            builder: (BuildContext context, Widget? child) {
                              return Theme( // Custom theme for DatePicker
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF643905), // Dark green primary color
                                    onPrimary: Colors.white, // White text color on primary
                                    onSurface: Color(0xFF5D4037), // Olive green surface color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFF643905), // Dark green button text color
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _tempSowingDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Sowing Date",
                            labelStyle: GoogleFonts.quicksand(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0), // More rounded corners
                              borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                            ),
                            focusedBorder: OutlineInputBorder( // Focused border color
                              borderRadius: BorderRadius.circular(12.0), // More rounded corners
                              borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white, // White fill
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${_tempSowingDate.toLocal()}".split(' ')[0], style: GoogleFonts.quicksand(color: Colors.black87, fontWeight: FontWeight.w600)), // Bold date text
                              const Icon(Icons.calendar_today, size: 20, color: Color(0xFF5D4037)), // Olive green icon, slightly larger
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      // Existing Farm ID and Area details
                      _FarmDetailsRow(title: "Farm ID:", value: farmId),
                      _FarmDetailsRow(
                          title: "Area:", value: _formatArea(area, selectedAreaUnit)),
                      const SizedBox(height: 16), // Increased spacing
                      // Fertility Level (Low, Medium, High)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Fertility Level",
                          labelStyle: GoogleFonts.quicksand(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Focused border color
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white, // White fill
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['Low', 'Medium', 'High'].map((level) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: level,
                                  groupValue: _tempFertility,
                                  activeColor: const Color(0xFF643905), // Dark green active color for radio
                                  onChanged: (value) {
                                    setState(() {
                                      _tempFertility = value!;
                                    });
                                  },
                                ),
                                Text(level, style: GoogleFonts.quicksand(color: Colors.black87, fontWeight: FontWeight.w600)), // Bold level text
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      // Soil Type (Sandy, Clay Loamy)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Soil Type",
                          labelStyle: GoogleFonts.quicksand(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Focused border color
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white, // White fill
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['Sandy', 'Clay' ,'Loamy'].map((type) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: type,
                                  groupValue: _tempSoilType,
                                  activeColor: const Color(0xFF643905), // Dark green active color for radio
                                  onChanged: (value) {
                                    setState(() {
                                      _tempSoilType = value!;
                                    });
                                  },
                                ),
                                Text(type, style: GoogleFonts.quicksand(color: Colors.black87, fontWeight: FontWeight.w600)), // Bold type text
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      // Pesticide Usage (Yes/No)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Pesticide Usage",
                          labelStyle: GoogleFonts.quicksand(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Focused border color
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white, // White fill
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: _tempPesticideUsage,
                                  activeColor: const Color(0xFF643905), // Dark green active color for radio
                                  onChanged: (value) {
                                    setState(() {
                                      _tempPesticideUsage = true;
                                    });
                                  },
                                ),
                                Text("Yes", style: GoogleFonts.quicksand(color: Colors.black87, fontWeight: FontWeight.w600)), // Bold Yes/No text
                              ],
                            ),
                            Row(
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: _tempPesticideUsage,
                                  activeColor: const Color(0xFF643905), // Dark green active color for radio
                                  onChanged: (value) {
                                    setState(() {
                                      _tempPesticideUsage = false;
                                    });
                                  },
                                ),
                                Text("No", style: GoogleFonts.quicksand(color: Colors.black87, fontWeight: FontWeight.w600)), // Bold Yes/No text
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      // Seeds per Hectare counter with plus/minus buttons
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Seeds per Hectare",
                          labelStyle: GoogleFonts.quicksand(color: const Color(0xFF5D4037), fontWeight: FontWeight.w600), // Olive green label, bold label
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFFBDBDBD)), // Light grey border
                          ),
                          focusedBorder: OutlineInputBorder( // Focused border color
                            borderRadius: BorderRadius.circular(12.0), // More rounded corners
                            borderSide: const BorderSide(color: Color(0xFF643905)), // Dark green focused border
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white, // White fill
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Color(0xFF5D4037)), // Olive green icon
                              onPressed: () {
                                setState(() {
                                  if (_tempSeedsPerHectare > 0) _tempSeedsPerHectare--;
                                });
                              },
                            ),
                            Text('$_tempSeedsPerHectare',
                                style: GoogleFonts.quicksand(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600)), // Bold seeds count
                            IconButton(
                              icon: const Icon(Icons.add, color: Color(0xFF5D4037)), // Olive green icon
                              onPressed: () {
                                setState(() {
                                  _tempSeedsPerHectare++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24), // Increased spacing before buttons
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              clearCurrentFarm();
                              Navigator.pop(context);
                              _resetToolSelection();
                              notifyListeners();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF757575), // Grey for discard button
                            ),
                            child: Text("Discard", style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)), // Bold button text
                          ),
                          ElevatedButton(
                            onPressed: _tempFarmName.isNotEmpty
                                ? () {
                              _saveFarmPlot(
                                context,
                                farmId,
                                area,
                                sowingDate: _tempSowingDate,
                                fertilityLevel: _tempFertility,
                                soilType: _tempSoilType,
                                pesticideUsage: _tempPesticideUsage,
                                seedsPerHectare: _tempSeedsPerHectare,
                              );
// Transfer temporary shapes to the permanent lists
                              polygons.addAll(_tempPolygons);
                              markers.addAll(_tempMarkers);
                              _tempPolygons.clear();
                              _tempMarkers.clear();
                              Navigator.pop(context);
                              _resetToolSelection();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF643905), // Dark green save button background
                              foregroundColor: Colors.white, // White save button text color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners for button
                            ),
                            child: Text("Save", style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.white)), // Bold button text
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    _resetToolSelection();
  }

  Future<void> _saveFarmPlot(BuildContext context, String id, double area, {required DateTime sowingDate,required String fertilityLevel, required String soilType, required bool pesticideUsage, required int seedsPerHectare,}) async {
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
        sowingDate: sowingDate,
        fertilityLevel: fertilityLevel,
        soilType: soilType,
        pesticideUsage: pesticideUsage,
        seedsPerHectare: seedsPerHectare,
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


  void loadFarms(BuildContext context) {
    FarmPlot.loadFarms().listen((loadedFarms) async {
      farms.clear();
      if (loadedFarms.isNotEmpty) {
        farms.addAll(loadedFarms);
      }

      // Clear existing polygons and markers.
      polygons.clear();
      markers.clear();

      for (var farm in farms) {
        // Add the polygon.
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
        // Add the centroid marker.
        await _addFarmMarker(context, farm);
      }
      notifyListeners();
    });
  }



  Future<void> _addFarmMarker(BuildContext context, FarmPlot farm, {String markerAsset = 'images/farmer.png'}) async {
    // Calculate the centroid from the farm's coordinates.
    LatLng center = _calculateCentroid(farm.coordinates);

    // Load the custom marker icon with reduced size.
    BitmapDescriptor customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(50, 60)),
      markerAsset,
    );

    markers.add(
      Marker(
        markerId: MarkerId('farm_center_${farm.id}'),
        position: center,
        icon: customIcon,
        // We use an empty infoWindow here since tapping will show our custom widget.
        infoWindow: const InfoWindow(title: '', snippet: ''),
        onTap: () {
          _showCustomInfoWindow(context, farm);
        },
      ),
    );
  }

  /// Custom info window showing detailed farm information with rich text styling.
  void _showCustomInfoWindow(BuildContext context, FarmPlot farm) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Reduced outer spacing
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // More rounded corners
        elevation: 5, // Increased elevation for a more pronounced shadow
        backgroundColor: Colors.grey.shade50, // Soft background color
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increased padding inside the dialog
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure dialog wraps content
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
            children: [
              Text( // Farm Name as Title
                farm.name,
                style: GoogleFonts.quicksand(
                  fontSize: 22, // Larger font size for title
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333), // Darker title color
                ),
              ),
              const SizedBox(height: 15), // Increased spacing after title
              RichText(
                text: TextSpan(
                  style: GoogleFonts.quicksand(fontSize: 16, color: Colors.black87, height: 1.4), // Increased font size and line height for readability
                  children: [
                    TextSpan(
                      text: "Area: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)), // Slightly darker bold labels
                    ),
                    TextSpan(text: "${_formatArea(farm.area, 'ha')}\n"),
                    const TextSpan(text: "\n"), // Added more spacing between items
                    TextSpan(
                      text: "Sowing: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                    ),
                    TextSpan(text: "${farm.sowingDate.toLocal().toString().split(' ')[0]}\n"),
                    const TextSpan(text: "\n"), // Added more spacing between items
                    TextSpan(
                      text: "Fertility: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                    ),
                    TextSpan(text: "${farm.fertilityLevel}\n"),
                    const TextSpan(text: "\n"), // Added more spacing between items
                    TextSpan(
                      text: "Soil: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                    ),
                    TextSpan(text: "${farm.soilType}\n"),
                    const TextSpan(text: "\n"), // Added more spacing between items
                    TextSpan(
                      text: "Pesticide: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                    ),
                    TextSpan(text: "${farm.pesticideUsage ? 'Yes' : 'No'}\n"),
                    const TextSpan(text: "\n"), // Added more spacing between items
                    TextSpan(
                      text: "Seeds/Hectare: ",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                    ),
                    TextSpan(text: "${farm.seedsPerHectare}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void finalizePolylineAndCreateFarm(BuildContext context) {
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
      area: area,
      coordinates: polygonPoints,
      createdAt: DateTime.now(),
      geoHash: geoPoint.hash,
      // Placeholder values for new fields:
      sowingDate: DateTime.now(),
      fertilityLevel: 'Medium',
      soilType: 'Sandy',
      pesticideUsage: false,
      seedsPerHectare: 0,
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

    // Add marker for this new farm.
    _addFarmMarker(context, farm);

    currentPolylinePoints.clear();
    polylines.clear();
    notifyListeners();
  }

  Future<void> _closeAndFillPolygon(BuildContext context) async {
    // Create a closed polygon.
    List<LatLng> closedPolygon = List.from(currentPolylinePoints)
      ..add(currentPolylinePoints.first);
    currentPolygonPoints = closedPolygon;

    // Add a temporary preview polygon.
    _tempPolygons.add(
      Polygon(
        polygonId: PolygonId(DateTime.now().toString()),
        points: closedPolygon,
        fillColor: Colors.redAccent.withOpacity(0.4),
        strokeColor: Colors.red,
        strokeWidth: 3,
      ),
    );
    setCurrentTool('hand');
    // Show the farm details dialog (for entering details).
    await _showFarmDetailsDialog(context);

    markers.addAll(_tempMarkers);
    polylines.addAll(_tempPolylines);

    // For the last saved farm, add its center marker.
    if (farms.isNotEmpty) {
      FarmPlot lastFarm = farms.last;
      // Use a different marker asset if needed.
      await _addFarmMarker(context, lastFarm, markerAsset: 'images/farmer.png');
    }

    // Clear temporary data.
    _tempMarkers.clear();
    _tempPolylines.clear();
    currentPolylinePoints.clear();
    currentDragPoint = null;
    currentTool = '';
    notifyListeners();
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    double totalLat = 0;
    double totalLng = 0;
    for (var point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    return LatLng(totalLat / points.length, totalLng / points.length);
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

  const _FarmDetailsRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.quicksand(color: Colors.black87)),
        ],
      ),
    );
  }
}
