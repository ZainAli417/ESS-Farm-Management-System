/* FOR FARM ISNIGTS SCREEN
  Row(children: [

              Expanded(
                flex: 1,
                child:Row(
                  children: [
                    Obx(() {
                      if (controller.isLoading.value) {
                        return Center(child: CircularProgressIndicator());
                      } else if (controller.errorMessage.isNotEmpty) {
                        return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Error loading weather data: ${controller.errorMessage.value}',
                                textAlign: TextAlign.center,
                              ),
                            ));
                      } else {
                        print("_buildWeatherUI is being called!"); // ADDED PRINT
                        return _buildWeatherUI();
                      }
                    }),
                SizedBox(width: 20,),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('tasks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700, color: Colors.red),
                        ));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text("No tasks yet",
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700)));
                      }

                      // Process task data for chart
                      // We want to display: Pending, Progress, Completed.
                      Map<String, int> taskStatusCounts = {
                        'Pending': 0,
                        'Progress': 0,
                        'Completed': 0,
                      };

                      for (var doc in snapshot.data!.docs) {
                        var taskData = doc.data() as Map<String, dynamic>;
                        String status =
                            (taskData['status'] as String?)?.toLowerCase() ??
                                'pending';
                        String displayStatus = (status == 'in progress')
                            ? 'Progress'
                            : status[0].toUpperCase() + status.substring(1);
                        if (taskStatusCounts.containsKey(displayStatus)) {
                          taskStatusCounts[displayStatus] =
                              (taskStatusCounts[displayStatus] ?? 0) + 1;
                        } else {
                          taskStatusCounts['Pending'] =
                              (taskStatusCounts['Pending'] ?? 0) + 1;
                        }
                      }

// Dynamically compute total tasks available
                      int totalTasks = taskStatusCounts['Pending']! +
                          taskStatusCounts['Progress']! +
                          taskStatusCounts['Completed']!;
                      // Build the chart using three separate series so that each status shows in the legend.
                      return SfCartesianChart(
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.top,
                          textStyle: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87),
                        ),
                        plotAreaBorderColor: Colors.transparent,
                        title: ChartTitle(
                          text: 'Task Progress',
                          textStyle: GoogleFonts.quicksand(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        primaryXAxis: CategoryAxis(
                          majorGridLines: const MajorGridLines(width: 0),
                          axisLine:
                              const AxisLine(width: 2, color: Colors.black54),
                          labelStyle: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800),
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: totalTasks
                              .toDouble(), // Dynamic maximum equals total tasks
                          interval: 1, // Each label increments by 1
                          majorGridLines: const MajorGridLines(width: 0),
                          numberFormat: NumberFormat(
                              "0"), // Formats numbers as whole numbers
                          axisLine:
                              const AxisLine(width: 2, color: Colors.black54),
                          labelStyle: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800),
                        ),
                        series: <CartesianSeries<TaskProgressData, String>>[
                          // Series for Pending tasks
                          ColumnSeries<TaskProgressData, String>(
                            dataSource: [
                              TaskProgressData(
                                taskStatusCounts['Pending']!,
                                'Pending',
                                chartColor: Colors.red.shade700,
                              )
                            ],
                            color: Colors.red
                                .shade700, // <--- Explicit series color for the legend
                            xValueMapper: (TaskProgressData data, _) =>
                                data.status,
                            yValueMapper: (TaskProgressData data, _) =>
                                data.taskCount,
                            name: 'Pending',
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                            ),
                            width: 0.7,
                            pointColorMapper: (TaskProgressData data, _) =>
                                data.chartColor,
                          ),
                          // Series for Progress tasks
                          ColumnSeries<TaskProgressData, String>(
                            dataSource: [
                              TaskProgressData(
                                taskStatusCounts['Progress']!,
                                'Progress',
                                chartColor: Colors.amber.shade700,
                              )
                            ],
                            color: Colors.amber
                                .shade700, // <--- Explicit series color for the legend
                            xValueMapper: (TaskProgressData data, _) =>
                                data.status,
                            yValueMapper: (TaskProgressData data, _) =>
                                data.taskCount,
                            name: 'Progress',
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                            ),
                            width: 0.7,
                            pointColorMapper: (TaskProgressData data, _) =>
                                data.chartColor,
                          ),
                          // Series for Completed tasks
                          ColumnSeries<TaskProgressData, String>(
                            dataSource: [
                              TaskProgressData(
                                taskStatusCounts['Completed']!,
                                'Completed',
                                chartColor: Colors.green.shade700,
                              )
                            ],
                            color: Colors.green
                                .shade700, // <--- Explicit series color for the legend
                            xValueMapper: (TaskProgressData data, _) =>
                                data.status,
                            yValueMapper: (TaskProgressData data, _) =>
                                data.taskCount,
                            name: 'Completed',
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                            ),
                            width: 0.7,
                            pointColorMapper: (TaskProgressData data, _) =>
                                data.chartColor,
                          ),
                        ],
                        tooltipBehavior: TooltipBehavior(enable: true),
                      );
                    },
                  ),
                ),

      ]
    ),
              ),
            ]),
 */