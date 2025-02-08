import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timelines_plus/timelines_plus.dart'; // Import timelines_plus package

import '../Constant/controller_weather.dart';

class WeatherAndTasksPanel extends StatefulWidget {
  const WeatherAndTasksPanel({Key? key}) : super(key: key);

  @override
  _WeatherAndTasksPanelState createState() => _WeatherAndTasksPanelState();
}

class _WeatherAndTasksPanelState extends State<WeatherAndTasksPanel> {
  final WeatherController weatherController = Get.find<WeatherController>();
  bool _isCelsius = true;
  List<String> _farmIds = [];
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadFarmIds();
  }

  Future<void> _loadFarmIds() async {
    try {
      final QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks')
          .get();

      Set<String> uniqueFarmIds = {};
      for (var doc in taskSnapshot.docs) {
        var taskData = doc.data() as Map<String, dynamic>;
        String farmId = taskData['farmId'] as String? ?? '';
        if (farmId.isNotEmpty) {
          uniqueFarmIds.add(farmId);
        }
      }
      setState(() {
        _farmIds = uniqueFarmIds.toList();
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
    return TimelineTile(
      nodeAlign: TimelineNodeAlign.start,
      oppositeContents: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(dueDateStr, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.black54)),
      ),
      node: TimelineNode(
        indicator: Icon(taskIcon, color: const Color(0xFF33691E), size: 24), // Custom Icon as Node, Dark Green color
        startConnector: SolidLineConnector(color: Colors.red.shade400, thickness: 2), // Red part of gradient
        endConnector: SolidLineConnector(color: Colors.blue.shade400, thickness: 2), // Blue part of gradient
      ),
      contents: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(taskData['status'] ?? 'Pending', style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
              ],
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //LEVE THIS AS IT IS DONOT REMOVE MY COMMENT DO NOT TOUCH IT
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add,size: 30, color: Colors.black87,),
            label: Text(
              'Add Task',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600,fontSize: 15,wordSpacing: 1, color: Colors.black87),
            ),
            onPressed: () {
              // _showAddAgendaDialog(); // Removed calendar related functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Card(
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Task Timeline',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: _farmIds.isEmpty
                      ? const Center(child: Text("No farms with tasks yet"))
                      : PageView.builder(
                    controller: _pageController,
                    itemCount: _farmIds.length,
                    itemBuilder: (context, index) {
                      final farmId = _farmIds[index];
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('tasks')
                            .where('farmId', isEqualTo: farmId)
                            .orderBy('dueDate') // Sort tasks by dueDate
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.quicksand(color: Colors.red)));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(child: Text("No tasks for Farm ID: $farmId", style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.grey.shade700)));
                          }

                          List<Map<String, dynamic>> farmTasks = [];
                          for (var doc in snapshot.data!.docs) {
                            farmTasks.add(doc.data() as Map<String, dynamic>);
                          }

                          return Timeline(
                            scrollDirection: Axis.vertical,

                            // Optionally, you can customize the timeline's spacing, padding, etc.
                            children: farmTasks.map((taskData) => _buildTimelineTile(taskData)).toList(),
                          );

                        },
                      );
                    },
                  ),
                ),
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