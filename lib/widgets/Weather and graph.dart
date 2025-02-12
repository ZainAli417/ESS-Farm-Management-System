import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../Constant/controller_weather.dart';

class WeatherAndTasksPanel extends StatefulWidget {
  const WeatherAndTasksPanel({super.key});

  @override
  _WeatherAndTasksPanelState createState() => _WeatherAndTasksPanelState();
}

class _WeatherAndTasksPanelState extends State<WeatherAndTasksPanel> {
  final WeatherController weatherController = Get.find<WeatherController>();
  bool _isCelsius = true;
  List<String> _farmIds = [];
  Map<String, String> _farmNames = {}; // Store farm names with farmIds
  final PageController _pageController = PageController(viewportFraction: 0.95); // PageController for Farm timelines, adjust viewportFraction
  int _currentPageIndex = 0; // Track current page for pagination

  @override
  void initState() {
    super.initState();
    _loadFarmData(); // Load both Farm IDs and Names
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
      });
    });
  }

  Future<void> _loadFarmData() async {
    try {
      final QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks')
          .get();

      Set<String> uniqueFarmIds = {};
      Map<String, String> farmNamesMap = {};
      for (var doc in taskSnapshot.docs) {
        var taskData = doc.data() as Map<String, dynamic>;
        String farmId = taskData['farmId'] as String? ?? '';
        String farmName = taskData['farmName'] as String? ?? 'Farm Name N/A'; // Get farmName
        if (farmId.isNotEmpty) {
          uniqueFarmIds.add(farmId);
          farmNamesMap[farmId] = farmName; // Store farm name with farmId
        }
      }
      setState(() {
        _farmIds = uniqueFarmIds.toList();
        _farmNames = farmNamesMap;
      });
    } catch (e) {
      print("Error loading Farm IDs: $e");
      // Handle error appropriately
    }
  }

  Widget _buildTimelineTile(Map<String, dynamic> taskData) {
    String taskType = taskData['type'] as String? ?? 'GENERAL';
    IconData taskIcon = _getTaskIcon(taskType);
    String dueDateStr = "";
    if (taskData['dueDate'] != null) {
      DateTime dueDate = DateTime.fromMillisecondsSinceEpoch(taskData['dueDate']);
      dueDateStr = DateFormat('MMM dd, yyy').format(dueDate.toLocal());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TimelineTile(
        nodeAlign: TimelineNodeAlign.start,
        node: TimelineNode(
          indicator: Icon(taskIcon, color: const Color(0xFF33691E), size: 24),
          startConnector: SolidLineConnector(color: Colors.red.shade400, thickness: 2),
          endConnector: SolidLineConnector(color: Colors.blue.shade400, thickness: 2),
        ),
        contents: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskData['taskName'] ?? 'Task Name',
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      taskData['taskDescription'] ?? 'Task Description',
                      style: GoogleFonts.quicksand(color: Colors.grey.shade700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                         Text("Status: ", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                        Text(
                          taskData['status'] ?? 'Pending',
                          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dueDateStr,
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType.toUpperCase()) {
      case 'HARVEST':
        return Icons.agriculture;
      case 'SOWING':
        return Icons.eco;
      case 'IRRIGATION':
        return Icons.water_drop;
      default:
        return Icons.task; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/weatherbg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken), // Added color filter to darken image
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(() {
            if (weatherController.weather.value.cityname == "N/A") {
              return const Center(child: CircularProgressIndicator());
            }
            double tempCelsius = weatherController.weather.value.temp;
            double tempDisplay = _isCelsius ? tempCelsius : (tempCelsius * 9 / 5) + 32;
            String unit = _isCelsius ? '°C' : '°F';

            DateTime now = DateTime.now();

            // Extract forecast data
            double maxTempCelsius = weatherController.weather.value.forecastMaxTemp;
            double minTempCelsius = weatherController.weather.value.forecastMinTemp;
            double feelsLikeCelsius = weatherController.weather.value.feelsLikeTemp;

            double maxTempDisplay = _isCelsius ? maxTempCelsius : (maxTempCelsius * 9 / 5) + 32;
            double minTempDisplay = _isCelsius ? minTempCelsius : (minTempCelsius * 9 / 5) + 32;
            double feelsLikeDisplay = _isCelsius ? feelsLikeCelsius : (feelsLikeCelsius * 9 / 5) + 32;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:  const Color(0xFF4E342E).withOpacity(0.8), // Reduced opacity for location container
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            weatherController.weather.value.cityname,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCelsius = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isCelsius ? const Color(0xFF4E342E) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'C',
                              style: GoogleFonts.quicksand(color: _isCelsius ? Colors.white : Colors.black87,fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCelsius = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: !_isCelsius ? const Color(0xFF4E342E) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'F',
                              style: GoogleFonts.quicksand(color: !_isCelsius ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  DateFormat('EEEE').format(now),
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('d MMM, yyyy').format(now),
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tempDisplay.toStringAsFixed(0)}$unit',
                      style: GoogleFonts.quicksand(
                        fontSize: 45,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        _buildLocalWeatherIcon(weatherController.weather.value.condition),
                        Text(
                          weatherController.weather.value.condition,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'High: ${maxTempDisplay.toStringAsFixed(0)}  Low: ${minTempDisplay.toStringAsFixed(0)}',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Feels Like ${feelsLikeDisplay.toStringAsFixed(0)}$unit',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),

        //LEVE THIS AS IT IS DONOT REMOVE MY COMMENT DO NOT TOUCH IT
        const SizedBox(height: 12),
        Expanded(
          child: Card(

            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Column(
              children: [
                Container(
                  width: double.infinity, // Take full width
                  padding: const EdgeInsets.all(16), // Adjust padding as needed
                  decoration: BoxDecoration(
                    color: Color(0xFF4E342E),// Brown color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child:  Center( // Or any other content you want here
                    child: Text(
                      'Task TimeLine', // Placeholder text, replace with your actual data
                      style: GoogleFonts.quicksand(color: Colors.white,fontWeight: FontWeight.w700,fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: _farmIds.isEmpty
                      ? const Center(child: Text("No farms with tasks yet"))
                      : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _farmIds.length,
                          itemBuilder: (context, index) {
                            final farmId = _farmIds[index];
                            final farmName =
                                _farmNames[farmId] ?? "Farm Timeline"; // Get farm name or default
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, bottom: 5.0),
                                  child: Text(farmName,
                                      style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.black87)), // Farm Name Title
                                ),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                        .instance.currentUser!.uid)
                                        .collection('tasks')
                                        .where('farmId', isEqualTo: farmId)
                                        .snapshots(), // Removed orderBy
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text('Error: ${snapshot.error}',
                                                style: GoogleFonts.quicksand(
                                                    color: Colors.red)));
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Center(
                                            child: Text(
                                                "No tasks for Farm ID: $farmName",
                                                style: GoogleFonts.quicksand(
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey.shade700)));
                                      }

                                      List<Map<String, dynamic>> farmTasks = [];
                                      for (var doc in snapshot.data!.docs) {
                                        farmTasks.add(
                                            doc.data() as Map<String, dynamic>);
                                      }
                                      farmTasks.sort((a, b) {
                                        int dueDateA = a['dueDate'] ?? 0;
                                        int dueDateB = b['dueDate'] ?? 0;
                                        return dueDateA.compareTo(dueDateB);
                                      });

                                      return Timeline(
                                        scrollDirection: Axis.vertical,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 4),
                                        children: farmTasks
                                            .map((taskData) =>
                                            _buildTimelineTile(taskData))
                                            .toList(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: _farmIds.length,
                            effect: WormEffect(
                              dotColor: Colors.grey.shade400,
                              activeDotColor: Colors.brown.shade700,
                              dotHeight: 8,
                              dotWidth: 8,
                              spacing: 8,
                            ),
                            onDotClicked: (index) {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ]),
                ),
                // Add this Container for the rounded bottom section
              ],
            ),
          ),
        ),
      ],
    );
  }
}


Widget _buildLocalWeatherIcon(String condition) {
  String iconName;

  switch (condition.toLowerCase()) {
    case 'sunny':
      iconName = 'images/sunny.svg';
      break;
    case 'clear':
      iconName = 'images/sunny.svg';
      break;
    case 'partly cloudy':
    case 'cloudy':
    case 'overcast':
      iconName = 'images/cloud.svg';
      break;
    case 'rainy':
    case 'moderate rain':
    case 'light rain':
    case 'heavy rain':
      iconName = 'images/rain.svg';
      break;
    case 'thunder':
    case 'thunderstorm':
      iconName = 'images/thunder.svg';
      break;
    case 'snow':
    case 'snowy':
      iconName = 'images/snow.svg';
      break;
    default:
      iconName = 'images/weather.svg';
      break;
  }

  return SvgPicture.asset(
    iconName,
    width: 100,
    height: 100,
    placeholderBuilder: (BuildContext context) => const Icon(Icons.image, size: 60, color: Colors.grey),
  );
}