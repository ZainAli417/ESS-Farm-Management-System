import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Constant/farmer_provider.dart';
import '../farm_model.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:html' as html;

import '../widgets/Weather and graph.dart';
import '../widgets/farm card.dart'; // Only for Flutter web.

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

GoogleMapController? mapController;
final places =
    GoogleMapsPlaces(apiKey: "AIzaSyBqEb5qH08mSFysEOfSTIfTezbhJjJZSRs");

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
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


  /*
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Panel: Farm List
          Container(
            width: 300,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(10),
            child: Consumer<MapDrawingProvider>(
              builder: (context, provider, _) {
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
                      onTap: () => provider.selectFarm(farm),
                    );
                  },
                );
              },
            ),
          ),

          // Middle Section: Search, Tools, and Map
          Expanded(
            child: Column(
              children: [
                // Search and Tools Row
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      // Build Tools
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
                                  updateCursor("freehand");
                                },
                              ),
                              // ... other tool buttons
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 20),

                      // Search Field
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.brown, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt_rounded,
                                  color: Colors.brown),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: "Search location",
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onChanged: _searchPlaces,
                                  onSubmitted: (value) async {
                                    if (_predictions.isNotEmpty) {
                                      _onSuggestionTap(_predictions.first);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Area
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: (details) async {
                            final provider = Provider.of<MapDrawingProvider>(
                                context,
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
                            final provider = Provider.of<MapDrawingProvider>(
                                context,
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
                            final provider = Provider.of<MapDrawingProvider>(
                                context,
                                listen: false);

                            if (provider.isDrawing) {
                              provider.finalizeDrawing(context);
                            }
                          },
                          child: Consumer<MapDrawingProvider>(
                            builder: (context, provider, child) {
                              return GoogleMap(
                                onMapCreated: (controller) {
                                  provider.setMapController(controller);
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
                      // Prediction List
                      if (_predictions.isNotEmpty)
                        Positioned(
                          left: 290,
                          top: 59,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border.all(
                                  color: const Color(0xFF826407), width: 1.5),
                            ),
                            child: Scrollbar(
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                itemCount: _predictions.length,
                                itemBuilder: (context, index) {
                                  final prediction = _predictions[index];
                                  return ListTile(
                                    title: Text(
                                      prediction.description ?? "",
                                      style: GoogleFonts.quicksand(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    onTap: () => _onSuggestionTap(prediction),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      // Map Type Selector
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
              ],
            ),
          ),

          // Right Panel: Calendar and Tasks
          Container(
            width: 300,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(10),
            child: CalendarAndTasksPanel(),
          ),
        ],
      ),
    );
  }
*/
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Left Section: Farm List View
          Container(
            width: 300,
            color: Colors.grey[100],
            padding: const EdgeInsets.all(10),
            child: Consumer<MapDrawingProvider>(
              builder: (context, provider, _) {
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
                      onTap: () => provider.selectFarm(farm),
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
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                            updateCursor("freehand");
                          },
                        ),
                        _buildToolButton(
                          context,
                          icon: Icons.crop_square,
                          tool: "rectangle",
                          currentTool: provider.currentTool,
                          onPressed: () {
                            provider.setCurrentTool("rectangle");
                            updateCursor("rectangle");
                          },
                        ),
                        _buildToolButton(
                          context,
                          icon: Icons.place,
                          tool: "marker",
                          currentTool: provider.currentTool,
                          onPressed: () {
                            provider.setCurrentTool("marker");
                            updateCursor("marker");
                          },
                        ),
                        _buildToolButton(
                          context,
                          icon: Icons.front_hand,
                          tool: "hand",
                          currentTool: provider.currentTool,
                          onPressed: () {
                            provider.setCurrentTool("hand");
                            updateCursor("hand");
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.brown.shade700, width: 2),
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
                        const Icon(Icons.search, color: Colors.brown),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: _searchPlaces,
                            onSubmitted: (value) async {
                              if (_predictions.isNotEmpty) {
                                _onSuggestionTap(_predictions.first);
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
              padding: const EdgeInsets.fromLTRB(290, 59, 140, 0),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF826407), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                    padding: const EdgeInsets.symmetric(vertical: 5),
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
                        onTap: () => _onSuggestionTap(prediction),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hoverColor: Colors.brown.shade100.withOpacity(0.3),
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

SizedBox(height: 20,),
                Expanded(
                  child: Stack(
                    children: [
                      // Google Map
                      Positioned.fill(
                  child: ClipRRect( // Add ClipRRect for rounded corners
                  borderRadius: BorderRadius.circular(20.0), // Adjust radius as needed
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
                                  provider.setMapController(context,controller);
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
                      Consumer<MapDrawingProvider>(
                        builder: (context, provider, child) {
                          return Positioned(
                            top: 10,
                            bottom: 10,
                            right: provider.isFarmDetailsVisible ? 0 : -250,
                            child: SizedBox(
                              width: 250,
                              child: provider.selectedFarm == null
                                  ? const SizedBox()
                                  : FarmDetailsPanel(
                                farm: provider.selectedFarm!,
                                onNameChanged:
                                provider.updateFarmName,
                                onClose: provider.closeFarmDetails,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

              ],
            ),
          ),

          // Right Section: Calendar and Tasks Panel
          SizedBox(
            width: 350,
            child: WeatherAndTasksPanel(),
          ),
        ],
      ),
    );
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
                        ? const Color(0xFF826407)
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
      padding: const EdgeInsets.symmetric(horizontal: 6.0), // Reduced horizontal padding
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50), // More rounded buttons
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF764A04) : Colors.grey[100], //  Softer background colors
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey[300]!), // Subtle border
            boxShadow: [ //  Softer shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF764A04)), // Dark brown icon color
        ),
      ),
    );
  }


  void updateCursor(String tool) {
    if (tool == "hand") {
      html.document.documentElement!.style.cursor = 'auto';
    } else {
      // For freehand, rectangle, and marker use the custom image.
      html.document.documentElement!.style.cursor = 'url(images/aim.png), auto';
    }
  }
}

// ----------------------
// FarmDetailsPanel Widget
// ----------------------
class FarmDetailsPanel extends StatefulWidget {
  final FarmPlot farm;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onClose;

  const FarmDetailsPanel({
    Key? key,
    required this.farm,
    required this.onNameChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  _FarmDetailsPanelState createState() => _FarmDetailsPanelState();
}

class _FarmDetailsPanelState extends State<FarmDetailsPanel> {
  String _selectedAreaUnit = 'ha';
  late TextEditingController _nameController;

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.farm.name);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),
          Text(
            "Farm Details",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Farm Name"),
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: 10),
          Text(
            "ID: ${widget.farm.id}",
            style: GoogleFonts.quicksand(color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Area: ${_formatArea(widget.farm.area, _selectedAreaUnit).split(' ').first}",
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF39890A),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _selectedAreaUnit,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.green, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    filled: true,
                    isDense: true,
                    isCollapsed: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                  isDense: true,
                  items: <String>['ha', 'ac']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.quicksand(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ))
                      .toList(),
                  onChanged: (newUnit) {
                    if (newUnit != null) {
                      setState(() {
                        _selectedAreaUnit = newUnit;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ADD TASK Header with icon and effects
          InkWell(
            onTap: () {
              // Implement add task action here if needed.
            },
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.blue.withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Add Task",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Dummy task list container
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Dummy Task 1",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Dummy Task 2",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Dummy Task 3",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------
// FarmCard Widget
// ----------------------

// ----------------------
// Format Area Function
// ----------------------
String _formatArea(double area, String unit) {
  switch (unit) {
    case 'ha':
      final converted = area / 10000;
      return '${converted.toStringAsFixed(2)} ha';
    default: // ac
      final converted = area * 0.000247105;
      return '${converted.toStringAsFixed(2)} ac';
  }
}
