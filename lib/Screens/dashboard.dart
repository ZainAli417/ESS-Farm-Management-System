import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Constant/farmer_provider.dart';
import '../widgets/Farm_plotted_List.dart';
import '../widgets/Weather and graph.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

bool _showOverlay = true;
GoogleMapController? mapController;
final places =
    GoogleMapsPlaces(apiKey: "AIzaSyBqEb5qH08mSFysEOfSTIfTezbhJjJZSRs");

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    // Display the overlay for 6 seconds, then remove it.
    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        _showOverlay = false;
      });
    });

    // Removed getCurrentLocation() from here.
    // Location fetching is handled in provider.setMapController.
  }

  final TextEditingController _controller = TextEditingController();
  List<Prediction> _predictions = [];
  bool _isLoading = false;

  void _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _isLoading = true);

    // Call the autocomplete API
    final response = await places.autocomplete(input);
    if (response.isOkay) {
      setState(() => _predictions = response.predictions);
    } else {
      // Optionally handle the error
      debugPrint("Places Autocomplete error: ${response.errorMessage}");
    }

    setState(() => _isLoading = false);
  }

  Future<LatLng?> _getLatLngFromPlaceId(String placeId) async {
    final detail = await places.getDetailsByPlaceId(placeId);
    if (detail.isOkay) {
      final location = detail.result.geometry?.location;
      if (location != null) {
        return LatLng(location.lat, location.lng);
      }
    }
    return null;
  }

  void _onSuggestionTap(Prediction prediction) async {
    final latLng = await _getLatLngFromPlaceId(prediction.placeId!);
    if (latLng != null) {
      // Animate camera to the searched location using provider function
      Provider.of<MapDrawingProvider>(context, listen: false)
          .animateCameraTo(latLng);
      // Optionally update the search field and clear suggestions
      setState(() {
        _controller.text = prediction.description ?? "";
        _predictions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        body: Row(
          children: [
            // Left Section: Farm List View
            Container(
              width: 300,
              padding: const EdgeInsets.all(10),
              child: Consumer<MapDrawingProvider>(
                builder: (context, provider, _) {
                  print("Current farms list: ${provider.farms.map((farm) => farm.name).toList()}"); // Add this line for logging
                  if (provider.farms.isEmpty) {
                    return Center(
                      child: Text(
                        "No farms plotted yet",
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: provider.farms.length,
                    itemBuilder: (context, index) {
                      final farm = provider.farms[index];
                      return FarmListItem(
                        farm: farm,
                        onTap: () => provider.selectFarm(farm) ,
                      );
                    },
                  );
                },
              ),
            ),
            // Center Section: Search Bar, Build Tool Buttons & Maps Widget
            Expanded(
              child: Column(
                children: [
                  // Top Content: Build Tool Selection & Search Field
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Consumer<MapDrawingProvider>(
                              builder: (context, provider, _) {
                                return Row(
                                  children: [
                                    _buildToolButton(
                                      context,
                                      icon: Icons.brush,
                                      tool: "freehand",
                                      currentTool: provider.currentTool,
                                      onPressed: () {
                                        provider.setCurrentTool("freehand");
                                      },
                                    ),
                                    _buildToolButton(
                                      context,
                                      icon: Icons.crop_square,
                                      tool: "rectangle",
                                      currentTool: provider.currentTool,
                                      onPressed: () {
                                        provider.setCurrentTool("rectangle");
                                      },
                                    ),
                                    _buildToolButton(
                                      context,
                                      icon: Icons.place,
                                      tool: "marker",
                                      currentTool: provider.currentTool,
                                      onPressed: () {
                                        provider.setCurrentTool("marker");
                                      },
                                    ),
                                    _buildToolButton(
                                      context,
                                      icon: Icons.front_hand,
                                      tool: "hand",
                                      currentTool: provider.currentTool,
                                      onPressed: () {
                                        provider.setCurrentTool("hand");
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 40,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: Color(0xFF2E2E48), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search,
                                        color: Color(0xFF2E2E48)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        style: GoogleFonts.quicksand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: "Search location",
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onChanged: _searchPlaces,
                                        onSubmitted: (value) async {
                                          if (_predictions.isNotEmpty) {
                                            _onSuggestionTap(
                                                _predictions.first);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 50),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _predictions.isNotEmpty ? 1.0 : 0.0,
                        child: _predictions.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(290, 59, 140, 0),
                                child: Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF2E2E48),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(0.08),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Scrollbar(
                                    interactive: true,
                                    trackVisibility: true,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      itemCount: _predictions.length,
                                      itemBuilder: (context, index) {
                                        final prediction = _predictions[index];
                                        return ListTile(
                                          title: Text(
                                            prediction.description ?? "",
                                            style: GoogleFonts.quicksand(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          onTap: () =>
                                              _onSuggestionTap(prediction),
                                          tileColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          hoverColor: Colors.brown.shade100
                                              .withOpacity(0.3),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // Google Map
                        Positioned.fill(
                          child: ClipRRect(
                            // Add ClipRRect for rounded corners
                            borderRadius: BorderRadius.circular(
                                20.0), // Adjust radius as needed
                            child: GestureDetector(
                              onPanStart: (details) async {
                                final provider =
                                    Provider.of<MapDrawingProvider>(context,
                                        listen: false);
                                if (provider.toolSelected &&
                                    provider.mapController != null) {
                                  try {
                                    LatLng point =
                                        await provider.mapController!.getLatLng(
                                      ScreenCoordinate(
                                        x: details.localPosition.dx.toInt(),
                                        y: details.localPosition.dy.toInt(),
                                      ),
                                    );
                                    provider.startDrawing(
                                        provider.currentTool, point);
                                  } catch (e) {
                                    debugPrint("Error getting LatLng: $e");
                                  }
                                }
                              },
                              onPanUpdate: (details) async {
                                final provider =
                                    Provider.of<MapDrawingProvider>(context,
                                        listen: false);
                                if (provider.isDrawing &&
                                    provider.mapController != null) {
                                  try {
                                    LatLng point =
                                        await provider.mapController!.getLatLng(
                                      ScreenCoordinate(
                                        x: details.localPosition.dx.toInt(),
                                        y: details.localPosition.dy.toInt(),
                                      ),
                                    );
                                    provider.updateDrawing(point);
                                  } catch (e) {
                                    debugPrint("Error updating drawing: $e");
                                  }
                                }
                              },
                              onPanEnd: (details) {
                                final provider =
                                    Provider.of<MapDrawingProvider>(context,
                                        listen: false);
                                if (provider.isDrawing) {
                                  provider.finalizeDrawing(context);
                                }
                              },
                              child: Consumer<MapDrawingProvider>(
                                builder: (context, provider, child) {
                                  return GoogleMap(
                                    onMapCreated: (controller) {
                                      provider.setMapController(
                                          context, controller);
                                    },
                                    initialCameraPosition: CameraPosition(
                                      target: provider.initialPoint,
                                      zoom: 20,
                                    ),
                                    scrollGesturesEnabled:
                                        provider.isMapInteractionAllowed(),
                                    rotateGesturesEnabled:
                                        provider.isMapInteractionAllowed(),
                                    tiltGesturesEnabled:
                                        provider.isMapInteractionAllowed(),
                                    zoomGesturesEnabled:
                                        provider.isMapInteractionAllowed(),
                                    myLocationButtonEnabled: true,
                                    myLocationEnabled: true,
                                    compassEnabled: true,
                                    mapToolbarEnabled: true,
                                    polygons: provider.allPolygons,
                                    polylines: provider.allPolylines,
                                    markers: provider.allMarkers,
                                    circles: provider.allCircles,
                                    mapType: provider.mapType,
                                    onTap: (latLng) {
                                      if (provider.currentTool == "marker") {
                                        provider.addMarkerAndUpdatePolyline(
                                            context, latLng);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 5,
                          child: GestureDetector(
                            onTap: () => _showMapTypeSelector(context),
                            child: Container(
                              width: 100,
                              height: 100,
                              child: Center(
                                child: SvgPicture.asset(
                                  'images/layers.svg',
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),

            // Right Section: Calendar and Tasks Panel
            Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 350,
                child: WeatherAndTasksPanel(),
              ),
            ),
          ],
        ),
      ),
      if (_showOverlay)
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5), // blue overlay effect
            child: Center(
              child: Lottie.asset(
                'images/loading.json', // update with your Lottie JSON file path
                width: 1080,
                height: 1920,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
    ]);
  }

  void _showMapTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<MapDrawingProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: provider.mapTypes.map((mapType) {
                return ListTile(
                  leading: Icon(
                    provider.mapType == mapType ? Icons.check : Icons.map,
                    size: 20,
                    color: provider.mapType == mapType
                        ? const Color(0xFF2E2E48)
                        : null,
                  ),
                  title: Text(
                    mapType.toString().split('.').last.toUpperCase(),
                  ),
                  onTap: () {
                    provider.setMapType(mapType);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String tool,
    required String currentTool,
    required VoidCallback onPressed,
  }) {
    final isSelected = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 6.0), // Reduced horizontal padding
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50), // More rounded buttons
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF2E2E48)
                : Colors.grey[100], //  Softer background colors
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey[300]!), // Subtle border
            boxShadow: [
              //  Softer shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF31315A)), // Dark brown icon color
        ),
      ),
    );
  }
}
