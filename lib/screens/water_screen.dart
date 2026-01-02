import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  // We use local state to track if celebration was dismissed for this session
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Su Takibi")),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          bool isGoalMet = storage.waterGoal > 0 && storage.waterCount >= storage.waterGoal;
          // Show overlay if goal met AND not manually dismissed yet
          bool showOverlay = isGoalMet && !_dismissed;
          
          // If goal is NOT met (e.g. user removed a cup), reset dismissal so it can show again next time
          if (!isGoalMet && _dismissed) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) setState(() => _dismissed = false);
             });
          }

          return Stack(
            children: [
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, size: 120, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text("${storage.waterCount} / ${storage.waterGoal} Bardak", style: Theme.of(context).textTheme.displayLarge),
                    Text("Günlük Hedef: ${storage.waterGoal}", style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 50),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBtn(context, -1, Icons.remove),
                        const SizedBox(width: 30),
                        _buildBtn(context, 1, Icons.add),
                      ],
                    )
                  ],
                ),
              ),
              
              // Celebration Overlay
              if (showOverlay)
                CelebrationOverlay(onDismiss: () {
                  setState(() {
                    _dismissed = true;
                  });
                }),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildBtn(BuildContext context, int amount, IconData icon) {
    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        heroTag: "btn_w_$amount",
        onPressed: () => Provider.of<StorageService>(context, listen: false).addWater(amount),
        backgroundColor: AppColors.primary,
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }
}

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const CelebrationOverlay({super.key, required this.onDismiss});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎉", style: TextStyle(fontSize: 80)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(blurRadius: 20, color: AppColors.primary.withOpacity(0.5))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "AFERİN!", 
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)
                      ),
                      Text(
                        "Hedef Tamam!", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: widget.onDismiss, 
                  child: Text("Tamam"),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15))
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
