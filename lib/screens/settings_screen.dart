import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ayarlar")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildsectionHeader(context, "Görünüm"),
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return SwitchListTile(
                title: Text("Büyük Yazı", style: Theme.of(context).textTheme.titleLarge),
                value: theme.isLargeFont,
                onChanged: (val) => theme.toggleFont(val),
              );
            }
          ),
          Consumer<ThemeProvider>(
            builder: (context, theme, child) {
              return SwitchListTile(
                 title: Text("Karanlık Mod", style: Theme.of(context).textTheme.titleLarge),
                 value: theme.isDarkMode,
                 onChanged: (val) => theme.toggleTheme(val),
              );
            }
          ),
          
          _buildsectionHeader(context, "Hedefler"),
          Consumer<StorageService>(
            builder: (context, storage, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Günlük Su Hedefi", style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 32),
                            onPressed: () {
                              if (storage.waterGoal > 1) {
                                storage.setWaterGoal(storage.waterGoal - 1);
                              }
                            },
                          ),
                          Text("${storage.waterGoal}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 32),
                            onPressed: () => storage.setWaterGoal(storage.waterGoal + 1),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          ),
          
          _buildsectionHeader(context, "Acil Durum"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Acil Kişi:", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   TextField(
                     decoration: InputDecoration(hintText: "Oğlum Ali (0555...)"),
                   )
                ],
              ),
            ),
          ),
          
          _buildsectionHeader(context, "Veri ve Gizlilik"),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text("Sohbet Geçmişini Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: Text("Bu işlem geri alınamaz."),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Geçmiş Silinsin mi?"),
                    content: Text("Bu işlem sohbet geçmişini tamamen silecek ve geri alınamaz."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal")),
                      TextButton(
                        onPressed: () {
                          Provider.of<StorageService>(context, listen: false).clearChatHistory();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Geçmiş silindi.")));
                        },
                        child: Text("Sil", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          _buildsectionHeader(context, "Bildirim Testi"),
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Column(
              children: [
                FutureBuilder<Map<String, bool>>(
                  future: _checkPermissions(),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? {'notif': false, 'alarm': false};
                    return Column(
                      children: [
                        _buildPermRow("Bildirim İzni", data['notif']!),
                        _buildPermRow("Alarm İzni", data['alarm']!),
                      ],
                    );
                  }
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: Text("Uygulama Ayarlarını Aç"),
                ),
              ],
            ),
          ),

          ElevatedButton.icon(
             icon: Icon(Icons.notifications_active),
             label: Text("Test Bildirimi Gönder"),
             onPressed: () async {
                await NotificationService().showTestNotification();
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.amber, 
               foregroundColor: Colors.black,
             ),
          ),
          
          ElevatedButton.icon(
             icon: Icon(Icons.restaurant),
             label: Text("Test Yemek Alarmı (5sn)"),
             onPressed: () async {
               // Schedule for 5 seconds later
               final now = DateTime.now().add(const Duration(seconds: 5));
               final timeStr = "${now.hour}:${now.minute.toString().padLeft(2,'0')}"; // This might schedule for tomorrow if seconds matter, but logic uses HM.
               // Actually logic uses exact HM match. If 12:00:05, and we pass 12:00, it might be weird.
               // Let's force it to be "Now + 1 minute" to be safe for "Next Minute" tick if HH:MM.
               // Better: Create a dedicated "test" method or just use current time + 1 min.
               
               // Quick Hack: Just call the service with a separate "Test" ID.
               // But wait, the service calculates date from string HH:MM.
               // So if currently 12:00:55, and we pass 12:01, it sets for today 12:01.
               
               final nextMin = DateTime.now().add(const Duration(minutes: 1));
               final testTimeStr = "${nextMin.hour}:${nextMin.minute.toString().padLeft(2,'0')}";
               
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alarm $testTimeStr için kuruldu. Bekleyin...")));
               
               await NotificationService().scheduleMealNotification(
                 'test_meal', 
                 'TEST YEMEĞİ', 
                 testTimeStr
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.orange, 
               foregroundColor: Colors.white,
             ),
          ),
          
          ElevatedButton.icon(
             icon: Icon(Icons.medication),
             label: Text("Test İlaç Alarmı (5sn)"),
             onPressed: () async {
               // Schedule for 5 seconds later
               final nextMin = DateTime.now().add(const Duration(minutes: 1));
               final testTimeStr = "${nextMin.hour}:${nextMin.minute.toString().padLeft(2,'0')}";
               
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İlaç Alarmı $testTimeStr için kuruldu. Bekleyin...")));
               
               await NotificationService().scheduleMedicationGroup(
                 testTimeStr, 
                 ['Test İlacı A', 'Test İlacı B']
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.teal, 
               foregroundColor: Colors.white,
             ),
          ),


          
          const SizedBox(height: 40),
          Center(child: Text("Sürüm: 2.0.0 (Flutter)", style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
  }
  
  Widget _buildsectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
  
  Future<Map<String, bool>> _checkPermissions() async {
    return {
      'notif': await Permission.notification.isGranted,
      'alarm': await Permission.scheduleExactAlarm.isGranted,
    };
  }

  Widget _buildPermRow(String title, bool granted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Icon(granted ? Icons.check_circle : Icons.error, color: granted ? Colors.green : Colors.red),
      ],
    );
  }
}
