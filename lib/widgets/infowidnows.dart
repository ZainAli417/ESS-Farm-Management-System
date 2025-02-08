import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomInfoWindow extends StatelessWidget {
  final String farmName;
  final String area;
  final String sowingDate;
  final String fertilityLevel;
  final String soilType;
  final String pesticideUsage;
  final String seedsPerHectare;

  const CustomInfoWindow({
    Key? key,
    required this.farmName,
    required this.area,
    required this.sowingDate,
    required this.fertilityLevel,
    required this.soilType,
    required this.pesticideUsage,
    required this.seedsPerHectare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 6.0,
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important for correct sizing
        children: [
          Text(
            farmName,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          RichText(
            text: TextSpan(
              style: GoogleFonts.quicksand(fontSize: 16, color: Colors.black87),
              children: <TextSpan>[
                TextSpan(text: 'Area: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$area\n'),
                TextSpan(text: 'Sowing: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$sowingDate\n'),
                TextSpan(text: 'Fertility: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$fertilityLevel\n'),
                TextSpan(text: 'Soil: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$soilType\n'),
                TextSpan(text: 'Pesticide: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$pesticideUsage\n'),
                TextSpan(text: 'Seeds/Hectare: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '$seedsPerHectare'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}