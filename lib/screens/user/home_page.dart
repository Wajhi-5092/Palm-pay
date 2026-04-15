import 'package:flutter/material.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/wallet_card.dart';
import '../../widgets/home/bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Give the whole page a "Room" feel with a subtle gradient background
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
          // Important: remove top padding so the Header can touch the top
          top: false,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 2));
                },
                color: const Color.fromARGB(255, 0, 92, 178),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeHeader(),
                      Transform.translate(
                        offset: const Offset(0, -4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
                          child: WalletCard(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'More with PayPalm',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
      floatingActionButton: const CenterQRButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
