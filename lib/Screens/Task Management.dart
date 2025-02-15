import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'drawer.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class TaskProgressData {
  final int taskCount;
  final String status;
  final Color chartColor;
  TaskProgressData(this.taskCount, this.status, {required this.chartColor});
}

class _TaskScreenState extends State<TaskScreen> {
  List<DocumentSnapshot> allTasks = [];
  List<DocumentSnapshot> filteredTasks = [];
  bool _isLoadingTasks = false;
  final TextEditingController _searchController = TextEditingController();

  // Added pagination variables
  int _currentPage = 0;
  final int _tasksPerPage = 25;
  static const primaryColor = Color(0xFF685BFF);
  static const canvasColor = Color(0xFF2E2E48);
  static const scaffoldBackgroundColor = Color(0xFF464667);
  static const accentCanvasColor = Color(0xFF3E3E61);
  final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  String? selectedStatusFilter; // Variable to hold selected status filter

  Future<void> _loadTasks() async {
    setState(() {
      _isLoadingTasks = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        allTasks = snapshot.docs;
        _filterTasks();
      });
    }
    setState(() {
      _isLoadingTasks = false;
    });
  }

  void _filterTasks() {
    String query = _searchController.text.toLowerCase();
    String statusFilter =
        selectedStatusFilter ?? ''; // Get selected status filter
    setState(() {
      filteredTasks = allTasks.where((task) {
        final taskData = task.data() as Map<String, dynamic>;
        final taskName = (taskData['taskName'] as String?)?.toLowerCase() ?? '';
        final taskDescription =
            (taskData['taskDescription'] as String?)?.toLowerCase() ?? '';
        final taskStatus = (taskData['status'] as String?)?.toLowerCase() ?? '';

        bool textMatch =
            taskName.contains(query) || taskDescription.contains(query);
        bool statusMatch = statusFilter.isEmpty ||
            taskStatus ==
                statusFilter.toLowerCase(); // Filter by status if selected

        return textMatch &&
            statusMatch; // Task must match both text and status filters
      }).toList();
      _currentPage = 0; // reset pagination on filter change
    });
  }

  final List<String> taskStatusesFilter = [
    'pending',
    'in progress',
    'completed'
  ]; // Filter options, include empty for "All"
  List<DocumentSnapshot> get _currentPageTasks {
    int startIndex = _currentPage * _tasksPerPage;
    int endIndex = startIndex + _tasksPerPage;
    if (endIndex > filteredTasks.length) {
      endIndex = filteredTasks.length;
    }
    return filteredTasks.sublist(startIndex, endIndex);
  }

  Widget buildStatusFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedStatusFilter,
      decoration: InputDecoration(
        labelText: "All Tasks",
        labelStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.white),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.white, width: 2)),
      ),
      // This style applies to the selected dropdown item
      style: GoogleFonts.quicksand(
          fontWeight: FontWeight.w700, color: Colors.white),
      // Optionally, you can set a contrasting background for the dropdown menu
      items: taskStatusesFilter.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            status.isEmpty ? 'All Tasks' : status,
            style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700, color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          selectedStatusFilter = val;
          _filterTasks(); // Re-filter tasks when status filter changes
        });
      },
    );
  }

  Widget buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _currentPage > 0 ? Color(0xFF2E2E48) : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.arrow_back),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              'Page ${_currentPage + 1} of ${((filteredTasks.length - 1) ~/ _tasksPerPage) + 1}',
              style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed:
                ((_currentPage + 1) * _tasksPerPage < filteredTasks.length)
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  ((_currentPage + 1) * _tasksPerPage < filteredTasks.length)
                      ? Color(0xFF2E2E48)
                      : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w700,
          fontSize: isHeader ? 17 : 15,
          color: isHeader ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTaskTable(BuildContext context) {
    List<TableRow> rows = [];

    // Header row
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Color(0xFF2E2E48)),
        children: [
          _buildTableCell('Farm-Id', isHeader: true),
          _buildTableCell('Crop Name', isHeader: true),
          _buildTableCell('Task To-Do', isHeader: true),
          _buildTableCell('Task Description', isHeader: true),
          _buildTableCell('Task Status', isHeader: true),
          _buildTableCell('Actions', isHeader: true),
          _buildTableCell('Due Date', isHeader: true),
        ],
      ),
    );

    // Data rows
    for (var doc in _currentPageTasks) {
      var taskData = doc.data() as Map<String, dynamic>;
      taskData['id'] = doc.id;
      String dueDateStr = "";
      if (taskData['dueDate'] != null) {
        DateTime dueDate =
            DateTime.fromMillisecondsSinceEpoch(taskData['dueDate']);
        dueDateStr = "${dueDate.toLocal()}".split(' ')[0];
      }
      rows.add(
        TableRow(
          children: [
            _buildTableCell(taskData['farmId'] ?? ""),
            _buildTableCell(taskData['farmName'] ?? ""),
            _buildTableCell(taskData['taskName'] ?? ""),
            _buildTableCell(taskData['taskDescription'] ?? ""),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TaskStatusDropdown(
                taskId: taskData['id'],
                initialStatus: taskData['status'] ?? 'pending',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showTaskDialog(context, taskDoc: doc),
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text('Edit',
                        style: GoogleFonts.quicksand(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showDeleteConfirmationDialog(
                          context,
                          taskData['taskName'] ?? "",
                          taskData['farmId'] ?? "",
                          _loadTasks,
                          taskData['id']);
                    },
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text('Delete',
                        style: GoogleFonts.quicksand(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                  ),
                ],
              ),
            ),
            _buildTableCell(dueDateStr),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: Container(
          // <-- Container for rounded corners

          child: ClipRRect(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15.0),
                topLeft: Radius.circular(15.0)),
            child: Table(
              columnWidths: {
                0: const FlexColumnWidth(1.5),
                1: const FixedColumnWidth(120),
                2: const FlexColumnWidth(1.5),
                3: const FlexColumnWidth(1.5),
                4: const FixedColumnWidth(120),
                5: const FlexColumnWidth(1.5),
                6: const FixedColumnWidth(105),
              },
              border: TableBorder.all(
                  color: Colors.black,
                  width: 1), // <-- Use TableBorder for Table itself
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: scaffoldBackgroundColor,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search and Filter widgets outside the table container
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Row for Search and Filter
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: "Search by Task Name/Description",
                        labelStyle:
                        GoogleFonts.quicksand(fontWeight: FontWeight.w700,color: Colors.white,fontSize: 14),
                        prefixIcon: const Icon(Icons.search,color: Colors.white,),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white,width: 2),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      onChanged: (value) {
                        _filterTasks();
                      },
                    ),
                  ),
                  const SizedBox(
                      width: 15), // Spacing between search and filter
                  SizedBox(
                    width: 200, // Adjust width as needed
                    child: buildStatusFilterDropdown(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20,),
            // Full width container for Task Table
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7F7F7), Colors.white70],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _isLoadingTasks
                          ? const Center(child: CircularProgressIndicator())
                          : filteredTasks.isEmpty
                          ? Center(
                        child: Text(
                          "No tasks available. Click '+' to add a new task.",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.grey.shade600),
                        ),
                      )
                          : Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                         Padding(padding: const EdgeInsets.all(10.0),
                          child:
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: _buildTaskTable(context),
                            ),
                          ),
                         ),
                          buildPaginationControls(), // Using the new pagination controls
                        ],
                      ),
                    ),
/*


                       */
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E2E48),
        onPressed: () => _showTaskDialog(context),
        tooltip: 'Add New Task',
        elevation: 5,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, {DocumentSnapshot? taskDoc}) {
    final bool isEditing = taskDoc != null;
    final Map<String, dynamic> taskData =
    isEditing ? taskDoc.data() as Map<String, dynamic> : {};
    final TextEditingController taskNameController =
    TextEditingController(text: taskData['taskName'] ?? '');
    final TextEditingController taskDescController =
    TextEditingController(text: taskData['taskDescription'] ?? '');
    DateTime? dueDate = taskData['dueDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(taskData['dueDate'])
        : null;
    String? selectedType = taskData['type'];
    String? selectedFarmId = taskData['farmId'];
    String? selectedFarmName = taskData['farmName'];
    String? selectedStatus = taskData['status'] ?? 'pending';

    final List<String> taskTypes = ['HARVEST', 'SOWING', 'IRRIGATION'];
    final List<String> taskStatuses = ['pending', 'in progress', 'completed'];

    showModalBottomSheet(
      isScrollControlled:
      true, // Allows the bottom sheet to take up full screen height if needed
      context: context,
      backgroundColor:
      Colors.transparent, // Make background transparent to see blur
      builder: (BuildContext context) {
        return BackdropFilter(
          // To blur the background
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust padding when keyboard is visible
              ),
              decoration: BoxDecoration(
                color: Colors.white, // Background color for bottom sheet
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isEditing ? "Edit Task" : "Add New Task",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700, fontSize: 28),
                        ),
                        const SizedBox(height: 24),
                        // Task Name Field
                        TextFormField(
                          controller: taskNameController,
                          decoration: InputDecoration(
                            labelText: "Task Name*",
                            labelStyle:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Task Description Field
                        TextFormField(
                          controller: taskDescController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Task Description*",
                            labelStyle:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Type and Due Date in a Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                focusColor: Colors.white,
                                elevation: 4,
                                enableFeedback: true,
                                isDense: true,
                                value: selectedType,
                                dropdownColor: Colors.black,
                                decoration: InputDecoration(
                                  labelText: "Type of Task*",
                                  labelStyle: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0)),
                                ),
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black),
                                // This builder ensures that after selection, the text displays in black
                                selectedItemBuilder: (BuildContext context) {
                                  return taskTypes.map((type) {
                                    return Text(
                                      type,
                                      style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black),
                                    );
                                  }).toList();
                                },
                                items: taskTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type,
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedType = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: "Due Date*",
                                  labelStyle: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0)),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      dueDate = picked;
                                    });
                                  }
                                },
                                controller: TextEditingController(
                                  text: dueDate != null
                                      ? "${dueDate!.toLocal()}".split(' ')[0]
                                      : "",
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Farm Dropdown
                        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('farms')
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final farmsData = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              focusColor: Colors.white,
                              elevation: 4,
                              enableFeedback: true,
                              isDense: true,
                              value: selectedFarmId,
                              isExpanded: true,
                              dropdownColor: Colors.black,
                              decoration: InputDecoration(
                                labelText:
                                "Choose Crop for which Task is intended to*",
                                labelStyle: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                              ),
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black),
                              // Render selected farm value in black
                              selectedItemBuilder: (BuildContext context) {
                                return farmsData.map((farmDoc) {
                                  final data = farmDoc.data();
                                  return Text(
                                    data['name'] ?? "Unnamed Farm",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black),
                                  );
                                }).toList();
                              },
                              items: farmsData.map((farmDoc) {
                                final data = farmDoc.data();
                                return DropdownMenuItem<String>(
                                  value: farmDoc.id,
                                  child: Text(
                                    data['name'] ?? "Unnamed Farm",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedFarmId = val;
                                  QueryDocumentSnapshot<Map<String, dynamic>>?
                                  matchingFarm;
                                  for (var farmDoc in farmsData) {
                                    if (farmDoc.id == val) {
                                      matchingFarm = farmDoc;
                                      break;
                                    }
                                  }
                                  if (matchingFarm != null) {
                                    final data = matchingFarm.data();
                                    selectedFarmName =
                                        data['name'] ?? "Unnamed Farm";
                                  } else {
                                    selectedFarmName = "Unnamed Farm";
                                  }
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Status Dropdown
                        DropdownButtonFormField<String>(
                          focusColor: Colors.white,
                          elevation: 4,
                          enableFeedback: true,
                          isDense: true,
                          value: selectedStatus,
                          dropdownColor: Colors.black,
                          decoration: InputDecoration(
                            labelText: "Status",
                            labelStyle: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w700, color: Colors.black),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700, color: Colors.black),
                          // Render selected status value in black
                          selectedItemBuilder: (BuildContext context) {
                            return taskStatuses.map((status) {
                              return Text(
                                status,
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700, color: Colors.black),
                              );
                            }).toList();
                          },
                          items: taskStatuses.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status,
                                  style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedStatus = val;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel",
                                  style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E2E48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed: () async {
                                if (taskNameController.text.isEmpty ||
                                    taskDescController.text.isEmpty ||
                                    selectedType == null ||
                                    dueDate == null ||
                                    selectedFarmId == null ||
                                    selectedFarmName == null) {
                                  return;
                                }
                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final tasksCollection = FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('tasks');
                                    if (isEditing) {
                                      await tasksCollection.doc(taskDoc.id).update({
                                        'taskName': taskNameController.text,
                                        'taskDescription': taskDescController.text,
                                        'type': selectedType,
                                        'dueDate': dueDate!.millisecondsSinceEpoch,
                                        'farmId': selectedFarmId,
                                        'farmName': selectedFarmName,
                                        'status': selectedStatus,
                                      });
                                    } else {
                                      await tasksCollection.add({
                                        'taskName': taskNameController.text,
                                        'taskDescription': taskDescController.text,
                                        'type': selectedType,
                                        'dueDate': dueDate!.millisecondsSinceEpoch,
                                        'farmId': selectedFarmId,
                                        'farmName': selectedFarmName,
                                        'createdAt': DateTime.now()
                                            .millisecondsSinceEpoch,
                                        'status': selectedStatus,
                                      });
                                    }
                                    _loadTasks();
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Failed to update task. Please try again.'
                                            : 'Failed to save task. Please try again.',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              child: Text("Save",
                                  style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFFFFF))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    ).whenComplete(() {
      // Any actions after bottom sheet is dismissed, if needed
    });
  }
}

void _showDeleteConfirmationDialog(BuildContext context, String taskName,
    farmId, VoidCallback loadTasks, taskId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Confirm Delete",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w700,color: Colors.black)),
        content: Text("Are you sure you want to delete task '$taskName'?",
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800,color: Colors.black)),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text("Delete",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            onPressed: () async {
              try {
                Navigator.of(context).pop();
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('tasks')
                      .doc(taskId)
                      .delete();
                  loadTasks();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete task. Please try again.',
                        style:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

// New widget for Task Status Dropdown inside the table cell.
class TaskStatusDropdown extends StatefulWidget {
  final String taskId;
  final String initialStatus;
  const TaskStatusDropdown(
      {super.key, required this.taskId, required this.initialStatus});

  @override
  _TaskStatusDropdownState createState() => _TaskStatusDropdownState();
}

class _TaskStatusDropdownState extends State<TaskStatusDropdown> {
  String? _currentStatus;
  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _currentStatus,
      focusColor: Colors.white,
      elevation: 4,
      enableFeedback: true,
      isDense: true,
      items: ['pending', 'in progress', 'completed']
          .map((status) => DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status,
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, fontSize: 14,color: Colors.black),
                ),
              ))
          .toList(),
      onChanged: (val) async {
        if (val != null) {
          setState(() {
            _currentStatus = val;
          });
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .doc(widget.taskId)
                  .update({'status': val});
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update task status.',
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() {
              _currentStatus = widget.initialStatus;
            });
          }
        }
      },
    );
  }
}
