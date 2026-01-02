import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/chat_bottom_sheet.dart'; // Import Chat Widget

// (I will inline strings for now to save a file step if I missed constants.dart)
// Actually I created app_theme.dart which had strings. Good.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.homeTitle, style: Theme.of(context).textTheme.displaySmall),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 32, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card (Date/Time ideally)
            _buildStatusCard(context),
            const SizedBox(height: 20),
            
            // Grid Menu
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(context, 'İlaçlar', Icons.medication, Colors.redAccent, '/meds'),
                  _buildMenuCard(context, 'Yemek', Icons.restaurant, Colors.orangeAccent, '/food'),
                  _buildMenuCard(context, 'Su', Icons.water_drop, Colors.blueAccent, '/water'),
                  _buildMenuCard(context, 'Günlük', Icons.history_edu, Colors.purpleAccent, '/history'), // Changed Profil to History
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allow full height
            backgroundColor: Colors.transparent,
            builder: (context) => const ChatBottomSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.mic, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bugün Harikasın!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("İlaçların ve öğünlerin kontrol altında.", style: TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
