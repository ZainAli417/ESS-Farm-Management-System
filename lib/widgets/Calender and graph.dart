import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Constant/controller_weather.dart';

class CalendarAndTasksPanel extends StatefulWidget {
  const CalendarAndTasksPanel({Key? key}) : super(key: key);

  @override
  _CalendarAndTasksPanelState createState() => _CalendarAndTasksPanelState();
}

class _CalendarAndTasksPanelState extends State<CalendarAndTasksPanel> {
  final WeatherController weatherController = Get.find<WeatherController>();
  bool _isCelsius = true;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pendingTasks = [
      {'task': 'Water the corn field', 'icon': Icons.opacity},
      {'task': 'Fertilize the soybean crop', 'icon': Icons.local_florist},
      {'task': 'Prune the orchard trees', 'icon': Icons.grass},
      {'task': 'Inspect greenhouse conditions', 'icon': Icons.thermostat},
    ];

    final List<Map<String, dynamic>> completedTasks = [
      {'task': 'Harvest wheat', 'icon': Icons.agriculture},
      {'task': 'Inspect irrigation system', 'icon': Icons.build},
      {'task': 'Soil testing', 'icon': Icons.science},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
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
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 16),
                          SizedBox(width: 5),
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
                        _buildUnitSelector('C', true),
                        SizedBox(width: 5),
                        _buildUnitSelector('F', false),
                      ],
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
                              color: _isCelsius ? Colors.green : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'C',
                              style: TextStyle(color: _isCelsius ? Colors.white : Colors.black87),
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
                              color: !_isCelsius ? Colors.green : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'F',
                              style: TextStyle(color: !_isCelsius ? Colors.white : Colors.black87),
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
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('d MMM, yyyy').format(now), // Updated date format to include year
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
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
                        color: Colors.black87,
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
                            color: Colors.black87,
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
                        color: Colors.grey.shade800,
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
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add,size: 30,),
            label: Text(
              'Add Task',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600,fontSize: 15,wordSpacing: 1),
            ),
            onPressed: () {
              // _showAddAgendaDialog(); // Removed calendar related functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: TabBar(
                      indicatorColor: Colors.blue,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black45,
                      labelStyle: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: pendingTasks.length,
                          separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final task = pendingTasks[index];
                            return TaskItem(
                              task: task['task'],
                              icon: task['icon'],
                            );
                          },
                        ),
                        ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: completedTasks.length,
                          separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final task = completedTasks[index];
                            return TaskItem(
                              task: task['task'],
                              icon: task['icon'],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildUnitSelector(String unit, bool isCelsius) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCelsius = isCelsius;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (_isCelsius == isCelsius) ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          unit,
          style: TextStyle(color: (_isCelsius == isCelsius) ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

}

Widget _buildLocalWeatherIcon(String condition) {
  String iconName;

  switch (condition.toLowerCase()) {
    case 'sunny':
      iconName = 'images/sunny.svg'; // Replace with your sunny icon asset path
      break;
    case 'clear':
      iconName = 'images/sunny.svg'; // Treat clear as sunny for icon purposes
      break;
    case 'partly cloudy':
    case 'cloudy':
    case 'overcast':
      iconName = 'images/cloud.svg'; // Replace with your cloudy icon asset path
      break;
    case 'rainy':
    case 'moderate rain':
    case 'light rain':
    case 'heavy rain':
      iconName = 'images/rain.svg'; // Replace with your rainy icon asset path
      break;
    case 'thunder':
    case 'thunderstorm':
      iconName = 'images/thunder.svg'; // Replace with your thunder icon asset path
      break;
    case 'snow':
    case 'snowy':
      iconName = 'images/snow.svg'; // Replace with your snowy icon asset path
      break;
    default:
      iconName = 'images/weather.svg'; // Default icon for unknown conditions
      break;
  }

  return SvgPicture.asset(
    iconName,
    width: 100,
    height: 100,
    placeholderBuilder: (BuildContext context) => const Icon(Icons.image, size: 60, color: Colors.grey), // Placeholder if icon loading fails
  );
}

class TaskItem extends StatefulWidget {
  final String task;
  final IconData icon;

  const TaskItem({Key? key, required this.task, required this.icon})
      : super(key: key);

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.task,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}