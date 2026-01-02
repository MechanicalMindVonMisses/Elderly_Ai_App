import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İlaç Takibi")),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          if (storage.meds.isEmpty) {
            return Center(child: Text("Henüz ilaç eklenmemiş.\nEklemek için + butonuna basın.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: storage.meds.length,
            itemBuilder: (context, index) {
              final med = storage.meds[index];
              final bool isTaken = med['taken'] ?? false;
              
              return Card(
                color: isTaken 
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                    : null, // Use default card theme
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  title: Text(med['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, decoration: isTaken ? TextDecoration.lineThrough : null)),
                  subtitle: Text(med['time'], style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                  value: isTaken,
                  activeColor: AppColors.success,
                  onChanged: (val) {
                    storage.toggleMed(med['id'], val ?? false);
                  },
                  secondary: IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => storage.deleteMed(med['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: Text("İlaç Ekle"),
        icon: Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final timeController = TextEditingController(text: "09:00");
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Yeni İlaç"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Med Name Input
            Align(
              alignment: Alignment.centerLeft,
              child: Text("İlaç İsimleri", style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController, 
              maxLines: 3, // Allow multiple lines
              decoration: InputDecoration(
                hintText: "Örn:\nAspirin\nTansiyon Hapı\nVitamin",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: const EdgeInsets.all(20),
              )
            ),
            
            const SizedBox(height: 20),
            
            // Time Input
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Saat", style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: timeController, 
              readOnly: true, // Prevent direct typing, use picker
              decoration: InputDecoration(
                hintText: "Örn: 09:00",
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: const EdgeInsets.all(20),
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                 TimeOfDay? picked = await showTimePicker(
                   context: context,
                   initialEntryMode: TimePickerEntryMode.input,
                   initialTime: TimeOfDay(
                     hour: int.parse(timeController.text.split(':')[0]), 
                     minute: int.parse(timeController.text.split(':')[1])
                   ),
                   // Localization
                   helpText: "SAAT GİRİNİZ",
                   cancelText: "İPTAL",
                   confirmText: "TAMAM",
                   hourLabelText: "Saat",
                   minuteLabelText: "Dakika",
                   errorInvalidText: "Geçersiz saat",
                   builder: (BuildContext context, Widget? child) {
                     return MediaQuery(
                       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                       child: child!,
                     );
                   },
                 );
                 if (picked != null) {
                   final String formatted = 
                       '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                   timeController.text = formatted;
                 }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                 final lines = nameController.text.split('\n');
                 final storage = Provider.of<StorageService>(context, listen: false);
                 for (var line in lines) {
                   if (line.trim().isNotEmpty) {
                     storage.addMed(line.trim(), timeController.text);
                   }
                 }
                Navigator.pop(ctx);
              }
            },
            child: Text("Kaydet"),
          )
        ],
      ),
    );
  }
}
