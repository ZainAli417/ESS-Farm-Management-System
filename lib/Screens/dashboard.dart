import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Constant/farmer_provider.dart';
import '../farm_model.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}
GoogleMapController? mapController;


class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    // Removed getCurrentLocation() from here.
    // Location fetching is handled in provider.setMapController.
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
              Row(
                children: [
                  Container(
                    child: Center(
        //code for search field which will auto list the places as suer types in location and we will get that location latlng and assing to a variable name searched area if search button is pressed or enter is pressed we wil re animate camera to that searched lcoation
                    ),
                  ),
                  Container(
                    child: Consumer<MapDrawingProvider>(
                      builder: (context, provider, _) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildToolButton(
                              context,
                              icon: Icons.brush,
                              tool: "freehand",
                              currentTool: provider.currentTool,
                              onPressed: () => provider.setCurrentTool("freehand"),
                            ),
                            _buildToolButton(
                              context,
                              icon: Icons.crop_square,
                              tool: "rectangle",
                              currentTool: provider.currentTool,
                              onPressed: () => provider.setCurrentTool("rectangle"),
                            ),
                            _buildToolButton(
                              context,
                              icon: Icons.place,
                              tool: "marker",
                              currentTool: provider.currentTool,
                              onPressed: () => provider.setCurrentTool("marker"),
                            ),
                            _buildToolButton(
                              context,
                              icon: Icons.front_hand,
                              tool: "hand",
                              currentTool: provider.currentTool,
                              onPressed: () => provider.setCurrentTool("hand"),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      child: Consumer<MapDrawingProvider>(
                        builder: (context, provider, _) {
                          return Container(
                            height: 130,
                            child: provider.farms.isEmpty
                                ? const Center(child: Text("No farms plotted yet"))
                                : ListView.builder(
                              addAutomaticKeepAlives: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: provider.farms.length,
                              itemBuilder: (ctx, i) => GestureDetector(
                                onTap: () => provider.selectFarm(provider.farms[i]),
                                child: FarmCard(farm: provider.farms[i]),
                              ),
                            ),
                          );
                        },
                      ),
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
                      final provider =
                      Provider.of<MapDrawingProvider>(context, listen: false);
                      if (provider.toolSelected && provider.mapController != null) {
                        try {
                          LatLng point = await provider.mapController!.getLatLng(
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
                      final provider =
                      Provider.of<MapDrawingProvider>(context, listen: false);
                      if (provider.isDrawing && provider.mapController != null) {
                        try {
                          LatLng point = await provider.mapController!.getLatLng(
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
                      Provider.of<MapDrawingProvider>(context, listen: false);
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
                          scrollGesturesEnabled: provider.isMapInteractionAllowed(),
                          rotateGesturesEnabled: provider.isMapInteractionAllowed(),
                          tiltGesturesEnabled: provider.isMapInteractionAllowed(),
                          zoomGesturesEnabled: provider.isMapInteractionAllowed(),
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
                              provider.addMarkerAndUpdatePolyline(context, latLng);
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
                  child: FloatingActionButton(
                    mini: true,
                    child: const Icon(Icons.layers, size: 30, color: Color(0xFF826407)),
                    onPressed: () => _showMapTypeSelector(context),
                  ),
                ),
                // Right-side Animated Panel
                Consumer<MapDrawingProvider>(
                  builder: (context, provider, child) {
                    return Positioned(
                      top: 10,
                      bottom: 10,
                      right: provider.isFarmDetailsVisible ? 0 : -250,
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(left: BorderSide(color: Colors.grey[300]!)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
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
                    color: provider.mapType == mapType ? const Color(0xFF826407) : null,
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
  String _selectedAreaUnit = 'm²';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose),
        ),
        const Text(
          "Farm Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: "Farm Name"),
          onChanged: widget.onNameChanged,
        ),
        const SizedBox(height: 10),
        Text("ID: ${widget.farm.id}",
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              "Area: ${_formatArea(widget.farm.area, _selectedAreaUnit)}",
              style: const TextStyle(color: Color(0xFF826407)),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _selectedAreaUnit,
              items: <String>['m²', 'ha', 'Acres']
                  .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
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
          ],
        ),
      ],
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
  String _selectedAreaUnit = 'm²';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 450,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.farm.id,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                "Area: ${_formatArea(widget.farm.area, _selectedAreaUnit)}",
                style: const TextStyle(color: Color(0xFF826407)),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedAreaUnit,
                items: <String>['m²', 'ha', 'Acres']
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
            ],
          ),
        ],
      ),
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
    case 'Acres':
      final converted = area * 0.000247105;
      return '${converted.toStringAsFixed(2)} Acres';
    default: // m²
      return '${area.toStringAsFixed(2)} m²';
  }

}


