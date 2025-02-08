import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FarmPlot {
  final String id;
  late final String name;
  final double area;
  final List<LatLng> coordinates;
  final DateTime createdAt;
  final String geoHash;
  // New fields
  final DateTime sowingDate;
  final String fertilityLevel;
  final String soilType;
  final bool pesticideUsage;
  final int seedsPerHectare;

  FarmPlot({
    required this.id,
    required this.name,
    required this.area,
    required this.coordinates,
    required this.createdAt,
    required this.geoHash,
    required this.sowingDate,
    required this.fertilityLevel,
    required this.soilType,
    required this.pesticideUsage,
    required this.seedsPerHectare,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'coordinates': coordinates
          .map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude})
          .toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'geoHash': geoHash,
      'sowingDate': sowingDate.millisecondsSinceEpoch,
      'fertilityLevel': fertilityLevel,
      'soilType': soilType,
      'pesticideUsage': pesticideUsage,
      'seedsPerHectare': seedsPerHectare,
    };
  }

  static Stream<List<FarmPlot>> loadFarms() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FarmPlot(
          id: data['id'] as String,
          name: data['name'] as String,
          area: (data['area'] as num).toDouble(),
          coordinates: (data['coordinates'] as List)
              .map((coord) => LatLng(
            (coord['lat'] as num).toDouble(),
            (coord['lng'] as num).toDouble(),
          ))
              .toList(),
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
          geoHash: data['geoHash'] as String,
          // Use defaults if these fields are missing.
          sowingDate: data['sowingDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['sowingDate'] as int)
              : DateTime.now(),
          fertilityLevel: data['fertilityLevel'] ?? 'Medium',
          soilType: data['soilType'] ?? 'Sandy',
          pesticideUsage: data['pesticideUsage'] ?? false,
          seedsPerHectare: data['seedsPerHectare'] ?? 0,
        );
      }).toList();
    });
  }
}
