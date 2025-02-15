import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sidebarx/sidebarx.dart';
import '../Constant/controller_weather.dart';
import 'Farm Insights.dart';
import 'Task Management.dart';
import 'dashboard.dart';

void main() {
  runApp(DrawerWidget());
}

class DrawerWidget extends StatelessWidget {
  DrawerWidget({Key? key}) : super(key: key);

  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final WeatherController weatherController = Get.put(WeatherController());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        canvasColor: canvasColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        textTheme: TextTheme(
          headlineSmall: GoogleFonts.quicksand(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      home: Scaffold(
        body: Row(
          children: [
            SidebarX(
              controller: _controller,
              theme: SidebarXTheme(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: canvasColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: GoogleFonts.quicksand(color: Colors.white),
                selectedTextStyle: GoogleFonts.quicksand(color: Colors.white),
                itemTextPadding: const EdgeInsets.only(left: 30),
                selectedItemTextPadding: const EdgeInsets.only(left: 30),
                itemDecoration: BoxDecoration(
                  border: Border.all(color: canvasColor),
                ),
                selectedItemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: actionColor.withOpacity(0.37),
                  ),
                  gradient: const LinearGradient(
                    colors: [accentCanvasColor, canvasColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 30,
                    )
                  ],
                ),
                iconTheme: const IconThemeData(
                  color: Colors.white,
                  size: 20,
                ),
                selectedIconTheme: const IconThemeData(
                  color: Colors.white,
                  size: 20,
                ),
              ),
              extendedTheme: const SidebarXTheme(
                width: 200,
                decoration: BoxDecoration(
                  color: canvasColor,
                ),
                margin: EdgeInsets.only(right: 10),
              ),
              headerBuilder: (context, extended) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    buildLogoHeader(extended),
                    const SizedBox(height: 8),
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                      indent: extended ? 16 : 0,
                      endIndent: extended ? 16 : 0,
                    ),
                    const SizedBox(height: 8),
                    buildProfileHeader(extended),
                  ],
                );
              },
              items: [
                SidebarXItem(
                  icon: Icons.map,
                  label: 'Plot Farms',
                ),
                SidebarXItem(
                  icon: Icons.landscape,
                  label: 'Soil Management',
                ),

                SidebarXItem(
                  icon: Icons.water_drop,
                  label: 'Irrigation Management',
                ),
                SidebarXItem(
                  icon: Icons.agriculture,
                  label: 'Crop Operations',
                ),
                SidebarXItem(
                  icon: Icons.workspaces,
                  label: 'Farm Operations',
                ),


                SidebarXItem(
                  icon: Icons.calendar_today,
                  label: 'Task Management',
                ),
                SidebarXItem(
                  icon: Icons.bug_report,
                  label: 'Pest & Disease Mgmt',
                ),
                SidebarXItem(
                  icon: Icons.cloud,
                  label: 'Weather Monitoring',
                ),
                SidebarXItem(
                  icon: Icons.inventory,
                  label: 'Inventory Mgmt',
                ),
                SidebarXItem(
                  icon: Icons.people,
                  label: 'Labour Mgmt',
                ),


                SidebarXItem(
                  icon: Icons.task_alt,
                  label: 'Harvest Mgmt',
                ),
                SidebarXItem(
                  icon: Icons.local_shipping,
                  label: 'Farm Shipping',
                ),
                SidebarXItem(
                  icon: Icons.attach_money,
                  label: 'Sales Mgmt',
                ),


                SidebarXItem(
                  icon: Icons.account_balance,
                  label: 'Financial Mgmt',
                ),
                SidebarXItem(
                  icon: Icons.analytics,
                  label: 'Farm Insights',
                ),
                SidebarXItem(
                  icon: Icons.insights,
                  label: 'Reports & Analytics',
                ),
                SidebarXItem(
                  icon: Icons.assignment_add,
                  label: 'Contract Farming',
                ),
                SidebarXItem(
                  icon: Icons.memory,
                  label: 'Farm.AI',
                ),
                SidebarXItem(
                  icon: Icons.settings,
                  label: 'Settings',
                ),
                SidebarXItem(
                  icon: Icons.account_circle,
                  label: 'Account Settings',
                ),
                SidebarXItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: _ScreensExample(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

// NEW: Static Stage Header Widget for SidebarX (non-interactive)


  /// Returns the logo header.
  Widget buildLogoHeader(bool extended) {
    final logo = Image.asset(
      extended ? 'images/logo1.png' : 'images/logo_collapsed.png',
      fit: BoxFit.contain,
    );
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: extended ? 200 : 60,
        child: logo,
      ),
    );
  }

  /// Returns the profile header.
  Widget buildProfileHeader(bool extended) {
    const avatar = CircleAvatar(
      radius: 26,
      backgroundImage: AssetImage('images/dummy.png'),
    );
    if (extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              child: avatar,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Zain Ali',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ess@mail.com',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Container(
          child: avatar,
        ),
      );
    }
  }
}

class _ScreensExample extends StatelessWidget {
  const _ScreensExample({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        switch (controller.selectedIndex) {
          case 0:
            return const MapScreen(); // GIS Mapping
          case 1:
            return const Center(child: Text("Soil Management Screen")); // Soil Management
          case 2:
            return const Center(child: Text("Irrigation Management Screen")); // Irrigation Management
          case 3:
            return const Center(child: Text("Crop Operations Screen")); // Crop Operations Management
          case 4:
            return const Center(child: Text("Farm Operations Screen")); // Farm Operations Management
          case 5:
            return TaskScreen(); // Task Management
          case 6:
            return const Center(child: Text("Pest & Disease Management Screen")); // Pest & Disease Management
          case 7:
            return const Center(child: Text("Weather Monitoring Screen")); // Weather Monitoring
          case 8:
            return const Center(child: Text("Inventory Management Screen")); // Inventory Management
          case 9:
            return const Center(child: Text("Labour Management Screen")); // Labour Management
          case 10:
            return const Center(child: Text("Equipment Management Screen")); // Equipment Management
          case 11:
            return const Center(child: Text("Harvest Management Screen")); // Harvest Management
          case 12:
            return const Center(child: Text("Farm Shipping Screen")); // Farm Shipping
          case 13:
            return const Center(child: Text("Sales Management Screen")); // Sales Management
          case 14:
            return const Center(child: Text("Financial Management Screen")); // Financial Management
          case 15:
            return const FarmInsights(); // Farm Insights
          case 16:
            return const Center(child: Text("Reports & Analytics Screen")); // Reports & Analytics
          case 17:
            return const Center(child: Text("Contract Farming Screen")); // Contract Farming
          case 18:
            return const Center(child: Text("Farm.AI Screen")); // Farm.AI
          case 19:
            return const Center(child: Text("Settings Screen")); // Settings
          case 20:
            return const Center(child: Text("Account Settings Screen")); // Account Settings
          case 21:
            return const Center(child: Text("Notifications Screen")); // Notifications
          default:
            return Center(
              child: Text(
                'Not found page',
                style: theme.textTheme.headlineSmall,
              ),
            );
        }
      },
    );
  }
}

const primaryColor = Color(0xFF685BFF);
const canvasColor = Color(0xFF2E2E48);
const scaffoldBackgroundColor = Color(0xFF464667);
const accentCanvasColor = Color(0xFF3E3E61);
final actionColor = const Color(0xFF5F5FA7).withOpacity(0.6);