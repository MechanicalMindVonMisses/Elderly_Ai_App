import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geçmiş Günlük"),
        centerTitle: true,
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          final history = storage.history;
          
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   const Text(
                     "Henüz kayıtlı geçmiş yok.\n(Her yeni günde buraya kayıt düşer)",
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.grey, fontSize: 16),
                   ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final day = history[index];
              final dateStr = day['date']; // YYYY-MM-DD
              final water = day['water'] ?? 0;
              final meds = day['meds'] as List<dynamic>;
              final meals = day['meals'] as List<dynamic>;
              
              // Parse Date
              DateTime date = DateTime.parse(dateStr);
              String formattedDate = DateFormat('d MMMM EEEE', 'tr_TR').format(date);
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.calendar_today, color: AppColors.primary),
                  ),
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "${meds.length} İlaç • ${meals.length} Öğün • $water Bardak Su",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  children: [
                    // --- MEDS Section ---
                    if (meds.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.medication, size: 20, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text("Alınan İlaçlar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      ...meds.map((m) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        title: Text(m['name']),
                        trailing: Text(m['time'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    ],

                    // --- MEALS Section ---
                    if (meals.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text("Yenen Yemekler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      ...meals.map((m) => ListTile(
                        dense: true,
                         leading: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        title: Text(m['name']),
                        subtitle: m['content'] != null && m['content'].isNotEmpty ? Text(m['content']) : null,
                        trailing: Text(m['time'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    ],
                    
                    // --- NUTRITION SUMMARY ---
                    if (meals.isNotEmpty) ...[
                      const Divider(),
                      _buildNutritionSummary(meals),
                    ],
                    
                    // --- WATER Section ---
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_drink, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Günlük Su Tüketimi: $water Bardak",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNutritionSummary(List<dynamic> meals) {
    int totalCal = 0;
    double totalProt = 0;
    double totalCarb = 0;
    double totalFat = 0; // Added Fat

    for (var m in meals) {
      if (m['nutrition'] != null) {
        totalCal += (m['nutrition']['cal'] as num).toInt();
        totalProt += (m['nutrition']['prot'] as num).toDouble();
        totalCarb += (m['nutrition']['carb'] as num).toDouble();
        totalFat += (m.containsKey('nutrition') && m['nutrition']['fat'] != null) 
            ? (m['nutrition']['fat'] as num).toDouble() 
            : 0.0;
      }
    }

    if (totalCal == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem("Kalori", "$totalCal kcal", Colors.orange),
          _buildMacroItem("Protein", "${totalProt.toStringAsFixed(0)}g", Colors.redAccent),
          _buildMacroItem("Karb.", "${totalCarb.toStringAsFixed(0)}g", Colors.blueAccent),
          _buildMacroItem("Yağ", "${totalFat.toStringAsFixed(0)}g", Colors.brown), // Added Fat Display
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
