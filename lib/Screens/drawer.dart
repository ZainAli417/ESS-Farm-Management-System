import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dashboard.dart';

class DrawerNavbar extends StatefulWidget {
  const DrawerNavbar({super.key});

  @override
  _DrawerNavbarState createState() => _DrawerNavbarState();
}

class _DrawerNavbarState extends State<DrawerNavbar> {
  int _currentIndex = 0;
  bool _isExpanded = true;

  final List<Widget> _children = [
    const MapScreen(),
    const Center(child: Text("Inventory Screen")),
    const Center(child: Text("Farm Insights Screen")),
    const Center(child: Text("settings Screen")),
    const Center(child: Text("notificaioos Screen")),
    const Center(child: Text("Farm.AI Screen")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          AnimatedContainer(

            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: _isExpanded ? 235 : 70,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 0.4), // Border added

              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),

            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                logoheader(),
                const Divider(),
                _buildProfileHeader(),
                const Divider(),
                _buildDrawerItems(),
                const Divider(),
                _buildSettingsItems(),


              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              switchInCurve: Curves.easeInOutCubic,
              child: _children[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerItem(
            index: 0,
            icon: Image.asset(
              'images/dashboard.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Farm Dashboard',
          ),
          _buildDrawerItem(
            index: 1,
            icon: Image.asset(
              'images/inventory.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Inventory',
          ),
          _buildDrawerItem(
            index: 2,
            icon: Image.asset(
              'images/stats.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Farm Insights',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItems() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerItem(
            index: 3,
            icon: Image.asset(
              'images/settings.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Account Settings',
          ),
          _buildDrawerItem(
            index: 4,
            icon: Image.asset(
              'images/notification.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Notifications',
          ),
          _buildDrawerItem(
            index: 5,
            icon: Image.asset(
              'images/chat.png', // Path to your custom icon
              width: 35,
              height: 35,
            ),
            label: 'Farm.Ai',
          ),
        ],

      ),
    );
  }


  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 1), // Border added
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('images/dummy.png'),
                ),

              ),
              const SizedBox(width: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement logout functionality
                },
                icon: const Icon(Icons.logout,color: Colors.white,size: 20,),
                label:  Text('Logout',style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w700
                ),),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Zain Ali',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ess@mail.com',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget logoheader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Image.asset(
            'images/logo1.png',
            width: 250,
          ),
        ],
      ),
    );
  }
  Widget _buildDrawerItem({
    required int index,
    required Widget icon, // Changed from IconData to Widget
    required String label,
  }) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment:
          _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            icon, // Now you can pass an Image.asset or Icon here
            if (_isExpanded) ...[
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.quicksand(
                      fontSize: isSelected ? 16 : 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (isSelected)
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0, end: label.length * 9.0),
                      builder: (context, width, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: 2,
                          width: width,
                          color: Colors.teal.shade500,
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
