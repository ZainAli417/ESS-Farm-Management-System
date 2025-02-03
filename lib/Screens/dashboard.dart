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
import 'dart:html' as html; // Only for Flutter web.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Content: Farm Cards and Tool Buttons

          Column(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Search Field inside a capsule-like container

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


                        const SizedBox(width: 20), // Spacing between search field and tools
                        Expanded(
                          child: Container(
                            height: 50, // Fixed height for better appearance
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(25), // Capsule shape
                              border: Border.all(
                                  color: Colors.brown,
                                  width: 2), // Brown border
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
                                    color: Colors
                                        .brown), // Search icon with brown color
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w600), // Font styling
                                    decoration: const InputDecoration(
                                      hintText: "Search location",
                                      border: InputBorder
                                          .none, // Remove default border
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
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                  if (_predictions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(290, 59, 140, 0),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                              color: Color(0xFF826407),
                              width: 1.5), // Brown border
                        ),
                        child: Scrollbar(
                          // Adds a scrollbar
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 5),
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
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Consumer<MapDrawingProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          height: 150,
                          width: 250,
                          child: provider.farms.isEmpty
                              ? const Center(
                                  child: Text("No farms plotted yet"))
                              : ListView.builder(
                                  addAutomaticKeepAlives: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: provider.farms.length,
                                  itemBuilder: (ctx, i) => GestureDetector(
                                    onTap: () =>
                                        provider.selectFarm(provider.farms[i]),
                                    child: FarmCard(farm: provider.farms[i]),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          // The Map and Animated Panel
          Expanded(
            child: Stack(
              children: [
                // Google Map
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) async {
                      final provider = Provider.of<MapDrawingProvider>(context,
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
                          provider.startDrawing(provider.currentTool, point);
                        } catch (e) {
                          debugPrint("Error getting LatLng: $e");
                        }
                      }
                    },
                    onPanUpdate: (details) async {
                      final provider = Provider.of<MapDrawingProvider>(context,
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
                      final provider = Provider.of<MapDrawingProvider>(context,
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
                Positioned(
                  bottom: 30,
                  left: 5,
                 child:  GestureDetector(
                    onTap: () => _showMapTypeSelector(context),
                    child: Container(
                      width: 100,
                      height: 100,

                      child: Center(

                        child: SvgPicture.asset(
                          'images/layers.svg', // Ensure correct path
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),

                ),
                // Right-side Animated Panel
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
                                onNameChanged: provider.updateFarmName,
                                onClose: provider.closeFarmDetails,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
    final isActive = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: FloatingActionButton(
        heroTag: tool,
        onPressed: onPressed,
        mini: true,
        backgroundColor: isActive ? const Color(0xFFB59123) : Colors.red[500],
        tooltip: tool.capitalize!,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  void updateCursor(String tool) {
    if (tool == "hand") {
      html.document.documentElement!.style.cursor = 'auto';
    } else {
      // For freehand, rectangle, and marker use the custom image.
      html.document.documentElement!.style.cursor =
      'url(images/aim.png), auto';
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

                    contentPadding: const EdgeInsets.fromLTRB(10,10,0,10),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green, width: 2),
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
                      style: GoogleFonts.quicksand(fontSize: 16,fontWeight: FontWeight.w700),
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
class FarmCard extends StatefulWidget {
  final FarmPlot farm;

  const FarmCard({Key? key, required this.farm}) : super(key: key);

  @override
  _FarmCardState createState() => _FarmCardState();
}
class _FarmCardState extends State<FarmCard> {
  String _selectedAreaUnit = 'ha';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double containerHeight =
            constraints.maxHeight * 0.6; // Responsive height

        return Container(
          width: 200,
          height: containerHeight, // Now responsive
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.farm.name,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.farm.id,
                style: GoogleFonts.quicksand(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w800),
              ),
              Divider(),
              SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                    "Area: ${_formatArea(widget.farm.area, _selectedAreaUnit).split(' ').first}",
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA28119), // Brown color
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.brown, width: 1.5),
                      borderRadius: BorderRadius.circular(6), // Rectangular box
                    ),
                    child: DropdownButton<String>(
                      value: _selectedAreaUnit,
                      elevation: 4,
                      enableFeedback: true,
                      underline: const SizedBox(), // Remove default underline
                      style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: Colors.brown,
                          fontWeight: FontWeight.w800),
                      dropdownColor:
                          Colors.white, // White background for dropdown list
                      isDense: true, // Reduces height spacing
                      items: <String>['ha', 'ac']
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.quicksand(fontSize: 14),
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
            ],
          ),
        );
      },
    );
  }
}
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
