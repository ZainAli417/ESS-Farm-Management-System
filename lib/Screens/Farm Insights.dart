// farm_insights.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ess_fms/Constant/weather.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../Constant/controller_weather.dart';
import 'package:http/http.dart' as http;
import '../Constant/farmer_provider.dart';
import '../Constant/yield_controller.dart';
import 'Task Management.dart';

class FarmInsights extends StatefulWidget {
  final FarmPlot? farm;

  const FarmInsights({Key? key, this.farm}) : super(key: key);

  @override
  _FarmInsightsState createState() => _FarmInsightsState();
}

class _FarmInsightsState extends State<FarmInsights> {
  // Retrieve the WeatherController that's already been put in memory
  final WeatherController weatherController = Get.find<WeatherController>();

  // Instantiate the FarmController using Get.put
  final FarmController farmController = Get.put(FarmController());

  bool _isPredicting = false;
  String? _predictionResult;
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

  Future<void> _predictYield() async {
    // Use the selected farm from the controller.
    final selectedFarm = farmController.selectedFarm.value;
    if (selectedFarm == null) return;

    setState(() {
      _isPredicting = true;
      _predictionResult = null;
    });

    CropData? cropData = await _loadCropDataForFarm(selectedFarm.id);//selected farm crop will be loaded
    if (cropData == null) {
      setState(() {
        _predictionResult = 'Error: No crop data available for this farm.';
      });
      return;
    }
    // Build the prompt using the farm and crop details.
    String cropType = cropData.cropName;
    double area = selectedFarm.area;
    String soilType = cropData.soilType;
    String fertilityLevel = cropData.fertilityLevel;
    bool pesticideUsage = cropData.pesticideUsage;
    int seedsPerHectare = cropData.seedsPerHectare;

    String prompt =
        'Estimate the metric ton production (MT) for the following crop details. '
        'Crop Type: $cropType, '
        'Planted Area: ${_formatArea(area, 'ha')} hectares, '
        'Soil Type: $soilType, '
        'Fertility Level: $fertilityLevel, '
        'Pesticide Usage: ${pesticideUsage ? "Yes" : "No"}, '
        'Seeds per Hectare: $seedsPerHectare. '
        'Respond with only a single number followed by "MT".';

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    const apiKey =
        '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'; // Replace with your API key
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content':
          'You are an expert in agricultural yield estimation. When asked, estimate the crop yield and respond with only a single number followed by "MT".'
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 10,
      'temperature': 0.2,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'] as String;
        setState(() {
          _predictionResult = answer.trim();
        });
      } else {
        setState(() {
          _predictionResult = 'Error: Failed to fetch yield estimation';
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isPredicting = false;
      });
    }
  }

  Future<CropData?> _loadCropDataForFarm(String farmId) async {
    try {
      final currentYear = DateTime.now().year.toString();
      // Query to get the latest crop for the farm
      QuerySnapshot cropDocsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('farms')
          .doc(farmId)
          .collection('farms_crops')
          .doc('Year-$currentYear')
          .collection('crops')
          .get();
          //.orderBy('sowingDate', descending: true) // Assuming you want the latest crop
          //.limit(1)

      if (cropDocsSnapshot.docs.isNotEmpty) {
        return CropData.fromMap(cropDocsSnapshot.docs.first.data() as Map<String, dynamic>);
      } else {
        return null; // No crop data found
      }
    } catch (e) {
      print("Error loading crop data: $e");
      return null; // Error loading crop data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left Section: Farm details, prediction UI, and animation.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Farm selection and details section.
                    Obx(() {
                      final bool isFarmSelected =
                          farmController.selectedFarm.value != null;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Farm details.
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: isFarmSelected ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                                child: Visibility(
                                  visible: isFarmSelected,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                    ),
                                    child: Obx(() {
                                      final FarmPlot farm =
                                          farmController.selectedFarm.value!;
                                      return FutureBuilder<CropData?>(
                                        future: _loadCropDataForFarm(farm
                                            .id), // Function to fetch CropData
                                        builder: (context, snapshot) {
                                          CropData? cropData = snapshot.data;
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _buildDetailCapsule(
                                                  'Farm ID', farm.id),

                                              _buildDetailCapsule('Area',
                                                  _formatArea(farm.area, 'ha')),

                                              if (cropData != null) ...[
                                                // Conditionally display crop data
                                                _buildDetailCapsule('Crop Name',
                                                    cropData.cropName),
                                                _buildDetailCapsule(
                                                    'Sowing Date',
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(cropData
                                                            .sowingDate)),
                                                _buildDetailCapsule(
                                                    'Fertility Level',
                                                    cropData.fertilityLevel),
                                                _buildDetailCapsule('Soil Type',
                                                    cropData.soilType),
                                                _buildDetailCapsule(
                                                    'Pesticide Usage',
                                                    cropData.pesticideUsage
                                                        ? "Yes"
                                                        : "No"),
                                                _buildDetailCapsule(
                                                    'Seeds per Hectare',
                                                    cropData.seedsPerHectare
                                                        .toString()),
                                              ] else ...[
                                                _buildDetailCapsule('Crop Data',
                                                    'Not Available'), // Display if no crop data
                                              ],
                                            ],
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 10), // Correct horizontal spacing.
                            // Right Column: Dropdown and Predict button.
                            SizedBox(
                              width: 300, // Fixed width for the right column.
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Dropdown container.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: Colors.blueAccent),
                                    ),
                                    child: Obx(() {
                                      if (farmController.farms.isEmpty) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                      return DropdownButtonHideUnderline(
                                        child: DropdownButton<FarmPlot>(
                                          isDense: true,
                                          elevation: 4,
                                          dropdownColor: Colors.grey.shade100,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 18,
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          hint: Text(
                                            'Select a Crop',
                                            style: GoogleFonts.quicksand(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          value:
                                              farmController.selectedFarm.value,
                                          items:
                                              farmController.farms.map((farm) {
                                            return DropdownMenuItem<FarmPlot>(
                                              value: farm,
                                              child: Text(
                                                farm.name,
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (FarmPlot? newFarm) {
                                            if (newFarm != null) {
                                              farmController
                                                  .selectFarm(newFarm);
                                            }
                                          },
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 10),
                                  // ElevatedButton for production prediction.
                                  ElevatedButton(
                                    onPressed:
                                        (farmController.selectedFarm.value ==
                                                    null ||
                                                _isPredicting)
                                            ? null
                                            : _predictYield,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      'Predict Production',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    if (_predictionResult != null)
                      Text(
                        _predictionResult!,
                        style: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(
                      width: 600,
                      height: 400,
                      child: _isPredicting
                          ? Lottie.asset('images/perdict.json',
                              fit: BoxFit.cover)
                          : Lottie.asset('images/bot.json', fit: BoxFit.cover),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Right Section: Weather UI.
            Obx(() {
              if (weatherController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (weatherController.errorMessage.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error loading weather data: ${weatherController.errorMessage.value}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                // Debug print to verify the weather UI is being built.
                print("_buildWeatherUI is being called!");
                return _buildWeatherUI();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCapsule(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        color: Colors.white, // Soft silver grey capsule color
        borderRadius: BorderRadius.circular(10), // Capsule shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Make container wrap content
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.quicksand(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.quicksand(
                fontSize: 16,
                color: Colors.blueGrey[900],
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherUI() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Card(
          color: Colors.white,
          elevation: 4.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Weather Forecast',
                  style: GoogleFonts.quicksand(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 20),
                _buildSplineChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplineChart() {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        title: AxisTitle(text: 'Day'),
        labelRotation: 45,
        interval: 1,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Temperature (°C)'),
        opposedPosition: false,
      ),
      series: <SplineAreaSeries<WeeklyWeather, String>>[
        // Max Temperature Series
        SplineAreaSeries<WeeklyWeather, String>(
          animationDuration: 2500,
          dataSource: weatherController.weeklyWeatherList.value,
          xValueMapper: (WeeklyWeather weather, _) =>
              DateFormat('EEE').format(DateTime.parse(weather.date)),
          yValueMapper: (WeeklyWeather weather, _) => weather.maxTemp,
          name: 'Max Temp',
          markerSettings: MarkerSettings(isVisible: true),
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.5),
              Colors.red.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Min Temperature Series
        SplineAreaSeries<WeeklyWeather, String>(
          animationDuration: 2500,
          dataSource: weatherController.weeklyWeatherList.value,
          xValueMapper: (WeeklyWeather weather, _) =>
              DateFormat('EEE').format(DateTime.parse(weather.date)),
          yValueMapper: (WeeklyWeather weather, _) => weather.minTemp,
          name: 'Min Temp',
          markerSettings: MarkerSettings(isVisible: true),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.5),
              Colors.green.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Humidity Series (plotted on a separate Y-axis)

        // Wind Speed Series (plotted on a separate Y-axis)
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      title: ChartTitle(text: '7-Day Weather Parameters'),
    );
  }
}

/*
  Widget _buildCurrentWeatherCard() {

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              controller.weather.value.cityname,
              style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Image.network(
              "https:${controller.weather.value.icon}",
              width: 80,
              height: 80,
            ),
            SizedBox(height: 10),
            Text(
              "${controller.weather.value.temp}°C",
              style: GoogleFonts.quicksand(fontSize: 36, fontWeight: FontWeight.w700),
            ),
            Text(
              controller.weather.value.condition,
              style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWeatherDetail('Humidity', '${controller.weather.value.humidity}%'),
                SizedBox(width: 20),
                _buildWeatherDetail('Wind Speed', '${controller.weather.value.windspeed} km/h'),
                SizedBox(width: 20),
                _buildWeatherDetail('Feels Like', '${controller.weather.value.feelsLikeTemp}°C'),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWeatherDetail('Max Temp', '${controller.weather.value.forecastMaxTemp}°C'),
                SizedBox(width: 20),
                _buildWeatherDetail('Min Temp', '${controller.weather.value.forecastMinTemp}°C'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String title, String value) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
        Text(value),
      ],
    );
  }
*/
