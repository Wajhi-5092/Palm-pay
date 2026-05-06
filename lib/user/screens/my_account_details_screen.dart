import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:paypalm/user/widgets/transaction/transaction_list.dart';

class MyAccountDetailsScreen extends StatelessWidget {
  const MyAccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8F9FA);
    const Color primaryBlue = Color.fromARGB(255, 0, 92, 178);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'My Account',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Transaction History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryTab(context, primaryBlue),
            const TransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, Color themeColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(themeColor),
          const SizedBox(height: 32),
          const Text(
            'Linked Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Linked Bank/ Debit/ Credit Cards',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildDashedLinkButton(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Color themeColor) {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isSmall = width < 350;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: const Color.fromARGB(255, 2, 41, 125),
                      size: isSmall ? 26 : 32,
                    ),
                    SizedBox(height: width * 0.03),
                    Text(
                      'PayPalm Mobile Account',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 2, 41, 125),
                        fontSize: isSmall ? 11 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: width * 0.03),
                    Row(
                      children: [
                        // 🔥 Prevent overflow
                        Expanded(
                          child: Text(
                            'Rs. 10,090.86',
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: isSmall ? 22 : 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        SizedBox(width: width * 0.03),

                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                const Color.fromARGB(255, 2, 41, 125),
                            elevation: 0,
                            side: const BorderSide(
                              color: Color.fromARGB(255, 2, 41, 125),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 10 : 16,
                              vertical: isSmall ? 8 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Add Cash',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 11 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: width * 0.02),
                  ],
                );
              },
            ),
          ],
        ));
  }

  Widget _buildDashedLinkButton() {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _DashedContainer(child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmall = width < 350;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: isSmall ? 34 : 40,
                color: Colors.black,
              ),

              SizedBox(height: width * 0.04),

              // 🔥 FIX: constrain + allow wrap properly
              SizedBox(
                width: width,
                child: Text(
                  'Link Any Bank\nAccount or\nCard',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      )),
    );
  }
}

class _DashedContainer extends StatelessWidget {
  final Widget child;
  const _DashedContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    const double dashSpace = 6;
    const double radius = 16;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rRect);

    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
            pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
