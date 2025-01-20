import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

// Farm Model
class Farm {
  final String id;
  final String name;
  final List<LatLng> polygonPoints;
  final List<LatLng> polylinePoints;
  final double area;
  final Color color;

  Farm({
    required this.id,
    required this.name,
    required this.polygonPoints,
    required this.polylinePoints,
    required this.area,
    required this.color,
  });
}

// FarmProvider to manage farms state
class FarmProvider with ChangeNotifier {
  List<Farm> farms = [];

  // Add a new farm to the list
  void addFarm(Farm farm) {
    farms.add(farm);
    notifyListeners();
  }

  // Calculate the area of a polygon using LatLng points
  double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      LatLng p1 = points[i];
      LatLng p2 = points[(i + 1) % points.length];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    return area.abs() / 2.0;
  }

  // Method to get the rectangle polygon points from two LatLngs
  List<LatLng> getRectanglePoints(LatLng point1, LatLng point2) {
    return [
      point1,
      LatLng(point1.latitude, point2.longitude),
      point2,
      LatLng(point2.latitude, point1.longitude),
    ];
  }

  // Method to get the circle polygon points
  List<LatLng> getCirclePoints(LatLng center, double radius) {
    List<LatLng> points = [];
    int numSegments = 360; // Number of segments to approximate the circle
    for (int i = 0; i < numSegments; i++) {
      double angle = (i * 2 * pi) / numSegments;
      double latOffset = radius * cos(angle) / 111320; // Convert meters to degrees
      double lngOffset = radius * sin(angle) / (111320 * cos(center.latitude * pi / 180)); // Convert meters to degrees
      points.add(LatLng(center.latitude + latOffset, center.longitude + lngOffset));
    }
    return points;
  }
}