import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../utils/app_theme.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yemek Takibi")),
      body: Consumer<StorageService>(
        builder: (context, storage, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: storage.meals.length,
            itemBuilder: (context, index) {
              final meal = storage.meals[index];
              return _buildMealCard(context, meal);
            },
          );
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    bool isCompleted = meal['completed'] ?? false;
    String content = meal['content'] ?? '';

    return Card(
      color: isCompleted 
          ? (Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50)
          : null, // Use default card theme
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.restaurant, color: Colors.orange),
        ),
        title: Text(meal['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        subtitle: isCompleted 
            ? Text("Yenilen: $content", style: TextStyle(fontSize: 18, 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)) 
            : Text("Saat: ${meal['time']}", style: TextStyle(fontSize: 18, color: Colors.grey)),
        
        // Checkbox to Silence Alarm / Mark Complete
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             IconButton(
               icon: Icon(Icons.edit_calendar, color: Colors.blueGrey),
               onPressed: () => _showFoodDialog(context, meal, isTimeEditOnly: true),
             ),
             Transform.scale(
              scale: 1.5,
              child: Checkbox(
                value: isCompleted,
                activeColor: Colors.green,
                shape: CircleBorder(),
                onChanged: (val) {
                   Provider.of<StorageService>(context, listen: false).updateMeal(
                     meal['id'], 
                     completed: val
                   );
                },
              ),
            ),
          ],
        ),
        onTap: () => _showFoodDialog(context, meal, isTimeEditOnly: false),
      ),
    );
  }



  void _showFoodDialog(BuildContext context, Map<String, dynamic> meal, {bool isTimeEditOnly = false}) {
    final textController = TextEditingController(text: meal['content']);
    final timeController = TextEditingController(text: meal['time']);
    
    // Nutrition info exists?
    String? nutritionInfo = meal['nutrition_notes'];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          return AlertDialog(
            title: Text(isTimeEditOnly ? "${meal['name']} Saatini Değiştir" : "${meal['name']} Düzenle"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isTimeEditOnly) ...[
                    Text("Ne yediniz?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: "Örn: Yumurta",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  Text("Saat", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    readOnly: true, 
                    decoration: InputDecoration(
                      hintText: "Saat Seçin",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialEntryMode: TimePickerEntryMode.input,
                        initialTime: TimeOfDay(
                          hour: int.parse(meal['time'].split(':')[0]), 
                          minute: int.parse(meal['time'].split(':')[1])
                        ),
                        helpText: "SAAT GİRİNİZ",
                        cancelText: "İPTAL",
                        confirmText: "TAMAM",
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
                  
                  if (!isTimeEditOnly && nutritionInfo != null && nutritionInfo!.isNotEmpty) ...[
                     const SizedBox(height: 20),
                     Container(
                       padding: EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.green.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.green.withOpacity(0.3))
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(children: [Icon(Icons.eco, size: 16, color: Colors.green), SizedBox(width: 8), Text("Besin Değerleri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                           Divider(height: 12),
                           Text(nutritionInfo!, style: TextStyle(fontSize: 13)),
                         ],
                       ),
                     ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
              
              if (isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton(
                  onPressed: () async {
                     setState(() => isLoading = true);
                     
                     if (isTimeEditOnly) {
                       // Just update time and Reschedule
                       Provider.of<StorageService>(context, listen: false).updateMeal(
                         meal['id'], 
                         time: timeController.text
                         // Do NOT change completed or content
                       );
                     } else {
                       // Log Food Logic
                       String currentText = textController.text.trim();
                       String newNutrition = nutritionInfo ?? "";
                       
                       // If text changed OR nutrition is missing, fetch new nutrition
                       if (currentText.isNotEmpty && (currentText != meal['content'] || (nutritionInfo == null || nutritionInfo!.isEmpty))) {
                          try {
                             final ai = Provider.of<AIService>(context, listen: false);
                             // Force nutrition lookup
                             String prompt = "$currentText kaç kalori ve besin değeri nedir?";
                             newNutrition = await ai.sendToLLM(prompt);
                          } catch (e) {
                            debugPrint("Nutrition fetch failed: $e");
                          }
                       }
                    
                       Provider.of<StorageService>(context, listen: false).updateMeal(
                         meal['id'], 
                         completed: true, 
                         content: currentText,
                         time: timeController.text,
                         nutrition_notes: newNutrition
                       );
                     }
                     
                     if (context.mounted) Navigator.pop(ctx);
                  },
                  child: Text("Kaydet"),
                )
            ],
          );
        }
      ),
    );
  }
}
