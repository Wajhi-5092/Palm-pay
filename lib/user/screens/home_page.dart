import 'package:flutter/material.dart';
import 'package:paypalm/user/widgets/home/home_header.dart';
import 'package:paypalm/user/widgets/home/wallet_card.dart';
import 'package:paypalm/user/widgets/home/bottom_nav.dart';
import 'package:paypalm/user/widgets/home/more_features_grid.dart';
import 'package:paypalm/user/widgets/home/palm_enrollment_status_banner.dart';
import 'package:paypalm/user/screens/palm_scan_screen.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // Bright light from top
              Color.fromARGB(255, 245, 246, 248), // Slightly darker floor
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 2));
                },
                color: const Color.fromARGB(255, 0, 92, 178),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: HomeHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
                          child: WalletCard(),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                    const SliverToBoxAdapter(
                      child: PalmEnrollmentStatusBanner(),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final ok = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PalmScanScreen(isRegistration: false),
                                  ),
                                );
                                if (!context.mounted) return;
                                if (ok == true) {
                                  CustomSnackbar.show(
                                    context: context,
                                    message: 'Palm verified successfully.',
                                    type: SnackbarType.success,
                                  );
                                }
                              },
                              child: Text(
                                'More with PayPalm',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Could navigate to a see-all features page
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 92, 178),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const MoreFeaturesGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}
