import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Constant/farmer_provider.dart';
import '../farm_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🏡 Farm Cards (Top Content)
          Row(
            children: [
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
              SizedBox(width: 10),
              // The Divider in a Row might not behave as expected.
              // You might consider using a VerticalDivider instead.
              VerticalDivider(),
              Divider(),
              // Wrap the container in an Expanded to give it bounded width.
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
                                  onTap: () =>
                                      provider.selectFarm(provider.farms[i]),
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

          // 🗺 Google Map (Takes Remaining Space)
          Expanded(
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
                    onMapCreated: provider.setMapController,
                    initialCameraPosition: CameraPosition(
                      target: provider.initialPoint,
                      zoom: 15,
                    ),
                    scrollGesturesEnabled: provider.isMapInteractionAllowed(),
                    rotateGesturesEnabled: provider.isMapInteractionAllowed(),
                    tiltGesturesEnabled: provider.isMapInteractionAllowed(),
                    zoomGesturesEnabled: provider.isMapInteractionAllowed(),
                    polygons: provider.allPolygons,
                    polylines: provider.allPolylines,
                    markers: provider.allMarkers,
                    circles: provider.allCircles,
                    onTap: (latLng) {
                      // Only add a marker if the current tool is set to "marker"
                      if (provider.currentTool == "marker") {
                        provider.addMarkerAndUpdatePolyline(latLng);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
        heroTag: tool, // Unique tag required when using multiple FABs on screen
        onPressed: onPressed,
        mini: true, // Use a mini FAB for a more compact design
        backgroundColor: isActive ? Colors.green.shade500 : Colors.red[400],
        tooltip: tool.capitalize!, // Display the tool name as a tooltip
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // 📦 Box Decoration
}

class FarmCard extends StatelessWidget {
  final FarmPlot farm;

  const FarmCard({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 450,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Rounded corners
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
            farm.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16, // Increased font size
            ),
          ),
          const SizedBox(height: 4),
          Text(
            farm.id,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            _formatArea(farm.area),
            style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.bold), // Bold area text
          ),
        ],
      ),
    );
  }
}

// 📏 Format Area
String _formatArea(double area) {
  return area > 10000
      ? '${(area / 10000).toStringAsFixed(2)} ha'
      : '${area.toStringAsFixed(2)} m²';
}
