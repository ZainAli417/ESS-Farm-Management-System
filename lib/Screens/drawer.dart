import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import '../Constant/controller_weather.dart';
import 'Farm Insights.dart';
import 'Task Management.dart';
import 'dashboard.dart';

class DrawerNavbar extends StatefulWidget {
  const DrawerNavbar({super.key});
  @override
  _DrawerNavbarState createState() => _DrawerNavbarState();
}

class _DrawerNavbarState extends State<DrawerNavbar> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late VideoPlayerController _controller;
  final List<Widget> _children = [
    const MapScreen(),
    TaskScreen(),
    FarmInsights(),
    const Center(child: Text("Account Settings Screen")),
    const Center(child: Text("Notifications Screen")),
    const Center(child: Text("Farm.AI Screen")),
  ];
  // Height of nav bar items.
  final double _navBarHeight = 50;
  // Divider thickness between nav items.
  final double _dividerWidth = 1;
  final WeatherController weatherController = Get.put(WeatherController());
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(''))
      ..initialize().then((_) {
        setState(() {});
      });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        // Restart the animation from 0 each time a new item is tapped.
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  /// Builds a single navigation item.
  Widget _buildNavItemHorizontal({
    required int index,
    required IconData icon,
    required String label,
    required double width,
  }) {
    bool isSelected = _currentIndex == index;
    Color iconColor = Colors.blueGrey;
    Color textColor = Colors.black54;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        // Use minimal padding so that the border (when drawn) hugs the content.
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNavItemsHorizontal() {
    List<Map<String, dynamic>> navData = [
      {'icon': FontAwesomeIcons.home, 'label': 'Dashboard'},
      {'icon': FontAwesomeIcons.tasks, 'label': 'Task Management'},
      {'icon': FontAwesomeIcons.chartSimple, 'label': 'Farm Insights'},
      {'icon': FontAwesomeIcons.handshakeAlt, 'label': 'Contracts Farming'},
      {'icon': FontAwesomeIcons.facebookMessenger, 'label': 'Farm.AI'},
      {'icon': FontAwesomeIcons.truckMoving, 'label': 'Inventory Management'},
    ];

    // We'll compute the width of each nav item based on the icon, text, and some padding.
    List<double> itemWidths = [];
    const double sidePadding = 12; // Same padding on left and right
    const double iconSize = 40;
    const double spacing = 2;

    for (var item in navData) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: item['label'],
          style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double textWidth = textPainter.width;
      // Multiply sidePadding by 2 so that left and right paddings are equal.
      double itemWidth = iconSize + spacing + textWidth + sidePadding * 2;
      itemWidths.add(itemWidth);
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        int itemCount = navData.length;
        // Compute total width occupied by nav items (including dividers).
        double totalItemsWidth = itemWidths.fold(0.0, (prev, curr) => prev + curr) +
            (itemCount - 1) ;

        // Calculate the total available space and divide it by the number of gaps.
        double availableSpace = constraints.maxWidth - totalItemsWidth;
        // There are 'itemCount + 1' gaps: before the first item, between each item, and after the last item.
        int numberOfGaps = itemCount + 1;
        double gapWidth = (availableSpace / numberOfGaps) * 0.6; // Reduced gapWidth by half
        // Build each nav item positioned exactly in the Stack with even gaps.
        List<Widget> items = [];
        double currentX = gapWidth; // Start with the first gap on the left.
        for (int i = 0; i < itemCount; i++) {
          items.add(Positioned(
            left: currentX,
            top: 0,
            width: itemWidths[i],
            height: _navBarHeight,
            child: _buildNavItemHorizontal(
              index: i,
              icon: navData[i]['icon'],
              label: navData[i]['label'],
              width: itemWidths[i],
            ),
          ));
          currentX += itemWidths[i] + gapWidth; // Add item width and gap after item.
          // Add divider space after each item except the last.
          if (i < itemCount - 1) {
            items.add(Positioned(
              left: currentX,
              top: 8,
              width: _dividerWidth,
              height: _navBarHeight - 18,
              child: Container(color: Colors.grey[300]),
            ));
            currentX += _dividerWidth + gapWidth; // Add divider width and gap after divider.
          }
        }

        return SizedBox(
          height: _navBarHeight,
          child: Stack(
            children: [
              ...items,
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    double selectedLeft = gapWidth; // Start with the first gap.
                    for (int i = 0; i < _currentIndex; i++) {
                      selectedLeft += itemWidths[i] + gapWidth;
                      if (i < itemCount - 1) {
                        selectedLeft += _dividerWidth + gapWidth;
                      }
                    }
                    double selectedWidth = itemWidths[_currentIndex];

                    // --- New Border Calculation ---
                    const double borderTextSidePadding = 5; // Padding on each side of the text in the border
                    double textWidthForBorder = 0;

                    final TextPainter textPainterForBorder = TextPainter( // Re-calculate TextPainter for border width
                      text: TextSpan(
                        text: navData[_currentIndex]['label'], // Use label of current index
                        style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      textDirection: TextDirection.ltr,
                    )..layout();
                    textWidthForBorder = textPainterForBorder.width;

                    double borderContentWidth = iconSize + spacing + textWidthForBorder; // Icon + spacing + text width
                    double borderTotalWidth = borderContentWidth + borderTextSidePadding * 2; // Add padding on both sides of text

                    double borderLeftOffset = (selectedWidth - borderTotalWidth) / 2; // Calculate left offset to center border

                    Rect selectedRect = Rect.fromLTWH(
                      selectedLeft + borderLeftOffset, // Use calculated offset
                      2, // Slightly reduced top padding for better visual balance
                      borderTotalWidth, // Use calculated border width
                      _navBarHeight - 4, // Slightly reduced bottom padding for better visual balance
                    );
                    return CustomPaint(
                      painter: GradientBorderPainter(
                        progress: _animation.value,
                        rect: selectedRect,
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.blue],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeaderHorizontal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade400, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage('images/dummy.png'),
            ),
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
                  color: Colors.black87,
                ),
              ),
              Text(
                'ess@mail.com',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget logoheader() {
    return Image.asset('images/logo1.png', width: 200, fit: BoxFit.fill);
  }

  Widget weathercard() {
    return Obx(() {
      String condition = weatherController.weather.value.condition.toLowerCase();
      IconData iconData;
      Color iconColor = Colors.orange.shade700;
      if (condition.contains('sunny')) {
        iconData = FontAwesomeIcons.sun;
      } else if (condition.contains('cloud')) {
        iconData = FontAwesomeIcons.cloud;
      } else if (condition.contains('hot')) {
        iconData = FontAwesomeIcons.fire;
      } else if (condition.contains('rain') || condition.contains('shower')) {
        iconData = FontAwesomeIcons.cloudRain;
      } else {
        iconData = FontAwesomeIcons.cloudSun;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(iconData, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              '${weatherController.weather.value.temp.toStringAsFixed(1)}°C',
              style: GoogleFonts.quicksand(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                logoheader(),
                VerticalDivider(
                  width: 2,
                  thickness: 1.5,
                  color: Colors.grey[300],
                  indent: 5,
                  endIndent: 5,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildNavItemsHorizontal(),
                  ),
                ),
                VerticalDivider(
                  width: 2,
                  thickness: 1.5,
                  color: Colors.grey[300],
                  indent: 5,
                  endIndent: 5,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildProfileHeaderHorizontal(),
                ),
                VerticalDivider(
                  width: 2,
                  thickness: 1,
                  color: Colors.grey[300],
                  indent: 10,
                  endIndent: 10,
                ),
                IconButton(
                  onPressed: () {},
                  icon: FaIcon(
                    FontAwesomeIcons.signOutAlt,
                    size: 22,
                    color: Colors.grey.shade700,
                  ),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                child: _children[_currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter that draws a gradient border gradually along a rectangular path.
class GradientBorderPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Rect rect;
  final Gradient gradient;

  GradientBorderPainter({
    required this.progress,
    required this.rect,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a rounded rectangle path for the border.
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final Path fullPath = Path()..addRRect(rrect);

    // Calculate the total length of the border.
    double totalLength = 0.0;
    for (final metric in fullPath.computeMetrics()) {
      totalLength += metric.length;
    }
    // Determine how much of the border to draw.
    final double currentLength = totalLength * progress;

    // Extract the subpath.
    final Path drawPath = Path();
    double drawn = 0.0;
    for (final metric in fullPath.computeMetrics()) {
      final double metricLength = metric.length;
      if (drawn + metricLength < currentLength) {
        drawPath.addPath(metric.extractPath(0, metricLength), Offset.zero);
        drawn += metricLength;
      } else {
        final double remain = currentLength - drawn;
        if (remain > 0) {
          drawPath.addPath(metric.extractPath(0, remain), Offset.zero);
        }
        break;
      }
    }

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rect != rect;
  }
}
