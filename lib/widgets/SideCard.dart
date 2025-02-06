import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../farm_model.dart';

class FarmDetailsPanel extends StatefulWidget {
  final FarmPlot farm;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onClose;

  const FarmDetailsPanel({
    Key? key,
    required this.farm,
    required this.onNameChanged,
    required this.onClose,
  }) : super(key: key);

  @override
  _FarmDetailsPanelState createState() => _FarmDetailsPanelState();
}

class _FarmDetailsPanelState extends State<FarmDetailsPanel> {
  String _selectedAreaUnit = 'ha';
  late TextEditingController _nameController;

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.farm.name);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),
          Text(
            "Farm Details",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Farm Name"),
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: 10),
          Text(
            "ID: ${widget.farm.id}",
            style: GoogleFonts.quicksand(color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Area: ${_formatArea(widget.farm.area, _selectedAreaUnit).split(' ').first}",
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF39890A),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _selectedAreaUnit,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                      const BorderSide(color: Colors.green, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                      const BorderSide(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    filled: true,
                    isDense: true,
                    isCollapsed: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                  isDense: true,
                  items: <String>['ha', 'ac']
                      .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.quicksand(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ))
                      .toList(),
                  onChanged: (newUnit) {
                    if (newUnit != null) {
                      setState(() {
                        _selectedAreaUnit = newUnit;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ADD TASK Header with icon and effects
          InkWell(
            onTap: () {
              // Implement add task action here if needed.
            },
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.blue.withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Add Task",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Dummy task list container
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Add Water",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Fertilizers",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.task_alt, color: Colors.green),
                  title: Text(
                    "Sowing Analysis",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
String _formatArea(double area, String unit) {
  switch (unit) {
    case 'ha':
      final converted = area / 10000;
      return '${converted.toStringAsFixed(2)} ha';
    default: // ac
      final converted = area * 0.000247105;
      return '${converted.toStringAsFixed(2)} ac';
  }
}
