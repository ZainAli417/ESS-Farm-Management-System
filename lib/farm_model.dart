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

  FarmPlot({
    required this.id,
    required this.name,
    required this.area,
    required this.coordinates,
    required this.createdAt,
    required this.geoHash,
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
    };
  }

  static Stream<List<FarmPlot>> loadFarms() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .snapshots()
        .map((snapshot) {
      final farms = snapshot.docs.map((doc) {
        final data = doc.data();
        return FarmPlot(
          id: data['id'],
          name: data['name'],
          area: data['area'],
          coordinates: (data['coordinates'] as List)
              .map((coord) => LatLng(coord['lat'], coord['lng']))
              .toList(),
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
          geoHash: data['geoHash'],
        );
      }).toList();
      return farms;
    });
  }
}
