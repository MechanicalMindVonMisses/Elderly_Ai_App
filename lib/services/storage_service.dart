import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'dart:math';

class StorageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  // Cache
  List<dynamic> _meals = [];
  List<dynamic> _meds = [];
  List<dynamic> _history = []; // [{date: '2023-10-20', water: 5, meds: [], meals: []}]
  int _waterCount = 0;
  int _waterGoal = 8;
  
  bool get isInitialized => _initialized;
  List<dynamic> get meals => _meals;
  List<dynamic> get meds => _meds;
  List<dynamic> get history => _history;
  int get waterCount => _waterCount;
  int get waterGoal => _waterGoal;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load History
    String? histJson = _prefs.getString('history');
    if (histJson != null) {
      _history = jsonDecode(histJson);
    }
    
    // Load Chat History
    await _loadChatHistory();

    // Load Data
    _loadMeds(); // Load meds first so we can archive them if needed
    _loadMeals(); // Load meals 
    _waterCount = _prefs.getInt('water_count') ?? 0;
    _waterGoal = _prefs.getInt('water_goal') ?? 8;
    
    // Check Day Change
    await _checkDailyReset();
    
    // FAKE DATA GENERATOR (For User Request)
    if (_history.isEmpty) {
      _generateFakeHistory();
    } else {
      _fixMissingFatData(); // Migration for existing "stale" data
    }
    
    _initialized = true;
    notifyListeners();
  }
  
  void _generateFakeHistory() {
    final now = DateTime.now();
    _history = [];
    
    // 7 Days of Data
    for (int i = 1; i <= 7; i++) {
       final date = now.subtract(Duration(days: i));
       final dateStr = date.toIso8601String().split('T')[0];
       
       // Random Data
       final water = 5 + Random().nextInt(5); // 5-10 glasses
       
       // Meals with Nutrition
       final meals = [
         {'name': 'Kahvaltı', 'content': '2 Yumurta, Peynir', 'time': '09:00', 
          'nutrition': {'cal': 350, 'prot': 20, 'carb': 5, 'fat': 25}},
         {'name': 'Öğle Yemeği', 'content': 'Kuru Fasulye, Pilav', 'time': '13:00',
          'nutrition': {'cal': 600, 'prot': 25, 'carb': 80, 'fat': 15}},
         {'name': 'Akşam Yemeği', 'content': 'Izgara Köfte, Salata', 'time': '19:00',
          'nutrition': {'cal': 450, 'prot': 35, 'carb': 10, 'fat': 30}},
       ];
       
       // Meds
       final meds = [
         {'name': 'Tansiyon İlacı', 'time': '09:00', 'taken': true},
         {'name': 'Vitamin', 'time': '13:00', 'taken': true},
       ];
       
       _history.add({
         'date': dateStr,
         'water': water,
         'meds': meds,
         'meals': meals,
       });
    }
    _prefs.setString('history', jsonEncode(_history));
  }
  
  Future<void> _checkDailyReset() async {
    String? lastDate = _prefs.getString('last_date');
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastDate != null && lastDate != today) {
       debugPrint("Top of the Morning! Resetting daily stats. Last: $lastDate, Today: $today");
       
       // Archive Yesterday
       _history.insert(0, {
         'date': lastDate,
         'water': _waterCount,
         'meds': _meds.where((m) => m['taken'] == true).toList(),
         'meals': _meals.where((m) => m['completed'] == true).toList(),
       });
       
       // Keep only last 7 days
       if (_history.length > 7) {
         _history = _history.sublist(0, 7);
       }
       await _prefs.setString('history', jsonEncode(_history));
       
       // Reset
       _waterCount = 0;
       await _prefs.setInt('water_count', 0);
       
       for (var m in _meals) {
         m['completed'] = false;
         m['content'] = '';
       }
       saveMeals(); // Saves reset meals
       
       for (var m in _meds) {
         m['taken'] = false;
       }
       await _prefs.setString('meds', jsonEncode(_meds));
    }
    
    // Update Date
    await _prefs.setString('last_date', today);
  }

  // --- MEALS ---
  void _loadMeals() {
    String? json = _prefs.getString('meals');
    if (json != null) {
      _meals = jsonDecode(json);
      
      // Migration: Fix "Ara Öğün 1" name for existing users
      bool changed = false;
      for (var m in _meals) {
        if (m['name'] == 'Ara Öğün 1') {
           m['name'] = 'Ara Öğün';
           changed = true;
        }
      }
      if (changed) saveMeals();
    } else {
      // Defaults
      _meals = [
        {'id': '101', 'name': 'Kahvaltı', 'time': '09:00', 'completed': false, 'content': ''},
        {'id': '102', 'name': 'Ara Öğün', 'time': '11:00', 'completed': false, 'content': ''},
        {'id': '103', 'name': 'Öğle Yemeği', 'time': '13:00', 'completed': false, 'content': ''},
        {'id': '104', 'name': 'Akşam Yemeği', 'time': '19:00', 'completed': false, 'content': ''},
      ];
      saveMeals();
    }
    
    // Schedule Alarms for incomplete meals (Only for Today)
    for (var meal in _meals) {
      if ((meal['completed'] ?? false) == false) {
        NotificationService().scheduleMealNotification(
          meal['id'], 
          meal['name'], 
          meal['time']
        );
      }
    }
  }

  void _fixMissingFatData() {
    bool changed = false;
    for (var day in _history) {
       List<dynamic> dayMeals = day['meals'] ?? [];
       for (var m in dayMeals) {
          if (m['nutrition'] != null) {
             Map<String, dynamic> nut = m['nutrition'];
             if (!nut.containsKey('fat')) {
                int cal = (nut['cal'] as num).toInt();
                int prot = (nut['prot'] as num).toInt();
                int carb = (nut['carb'] as num).toInt();
                
                // Estimate Fat based on Calories
                // Fat = (Cal - (Prot*4 + Carb*4)) / 9
                double calcFat = (cal - (prot * 4 + carb * 4)) / 9;
                if (calcFat < 1.0) calcFat = 1.0; 
                
                nut['fat'] = double.parse(calcFat.toStringAsFixed(1));
                changed = true;
             }
          }
       }
    }
    if (changed) {
       _prefs.setString('history', jsonEncode(_history));
    }
  }

  
  Future<void> saveMeals() async {
    await _prefs.setString('meals', jsonEncode(_meals));
    notifyListeners();
  }
  
  void updateMeal(String id, {bool? completed, String? content, String? time, String? nutrition_notes}) {
    int idx = _meals.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      if (completed != null) {
         _meals[idx]['completed'] = completed;
         if (completed) {
            // Silence Alarm on completion
            NotificationService().cancelNotification(id);
         } else {
            // Reschedule if un-checked
            NotificationService().scheduleMealNotification(id, _meals[idx]['name'], _meals[idx]['time']);
         }
      }
      if (content != null) _meals[idx]['content'] = content;
      if (nutrition_notes != null) {
         _meals[idx]['nutrition_notes'] = nutrition_notes;
         final parsed = _parseNutrition(nutrition_notes);
         _meals[idx].addAll(parsed);
      }
      if (time != null) {
         _meals[idx]['time'] = time;
         // Reschedule if not completed
         if (!(_meals[idx]['completed'] ?? false)) {
            NotificationService().scheduleMealNotification(id, _meals[idx]['name'], time);
         }
      }
      
      saveMeals();
    }
  }

  Map<String, dynamic> _parseNutrition(String text) {
    Map<String, dynamic> result = {};
    try {
      // Clean text
      String clean = text.toLowerCase().replaceAll('\n', ' ');
      
      // regex for Calories (e.g. 500 kcal, 500 kalori)
      final calMatch = RegExp(r'(\d+)\s*(kcal|kalori)').firstMatch(clean);
      if (calMatch != null) result['cal'] = int.tryParse(calMatch.group(1)!) ?? 0;
      
      // regex for Protein (e.g. 20g Prot, 20 g protein)
      final protMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*g?\s*(prot|protein)').firstMatch(clean);
      if (protMatch != null) result['prot'] = double.tryParse(protMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
      
      // regex for Fat (e.g. 10g Yag, 10 g yağ)
      final fatMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*g?\s*(yag|yağ)').firstMatch(clean);
      if (fatMatch != null) result['fat'] = double.tryParse(fatMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
      
      // regex for Carb (e.g. 50g Karb, 50 g karbonhidrat)
      final carbMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*g?\s*(karb|carb|karbonhidrat)').firstMatch(clean);
      if (carbMatch != null) result['carb'] = double.tryParse(carbMatch.group(1)!.replaceAll(',', '.')) ?? 0.0;
      
    } catch (e) {
      debugPrint("Nutrition Parse Error: $e");
    }
    return result;
  }

  // --- MEDS ---
  void _loadMeds() {
    String? json = _prefs.getString('meds');
    if (json != null) {
      _meds = jsonDecode(json);
      _sortMeds(); // Ensure sorted immediately
    }
  }

  void _sortMeds() {
    _meds.sort((a, b) {
      return (a['time'] as String).compareTo(b['time'] as String);
    });
  }

  Future<void> addMed(String name, String time) async {
    // Fix: Use microseconds + random to ensure uniqueness even in tight loops
    final String id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
    _meds.add({
      'id': id,
      'name': name,
      'time': time,
      'taken': false
    });
    
    _sortMeds(); // Sort after adding
    
    await _prefs.setString('meds', jsonEncode(_meds));
    
    // Grouped Notification Update
    await _updateNotificationForTime(time);
    
    notifyListeners();
  }

  Future<void> toggleMed(String id, bool val) async {
    debugPrint("Toggling Med ID: $id to $val");
    int idx = _meds.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      _meds[idx]['taken'] = val;
      await _prefs.setString('meds', jsonEncode(_meds));
      debugPrint("Updated Med: ${_meds[idx]['name']} is now ${val ? 'TAKEN' : 'NOT TAKEN'}");
      
      // Check if ALL meds for this specific time are now taken
      String time = _meds[idx]['time'];
      final medsAtTime = _meds.where((m) => m['time'] == time).toList();
      bool allTaken = medsAtTime.every((m) => m['taken'] == true);
      
      debugPrint("Checking Time: $time. Meds count: ${medsAtTime.length}. All Taken? $allTaken");
      
      if (allTaken) {
        debugPrint("!!! All meds for $time taken. Cancelling alarm. !!!");
        await NotificationService().cancelMyNotification(time);
      }
      
      notifyListeners();
    } else {
      debugPrint("Error: Med ID $id not found!");
    }
  }
  
   Future<void> deleteMed(String id) async {
    // Find med to get its time before deleting
    final int idx = _meds.indexWhere((m) => m['id'] == id);
    if (idx == -1) return;
    String time = _meds[idx]['time'];

    _meds.removeAt(idx);
    await _prefs.setString('meds', jsonEncode(_meds));
    
    // Grouped Notification Update
    await _updateNotificationForTime(time);
    
    notifyListeners();
  }
  
  Future<void> _updateNotificationForTime(String time) async {
    // Find all meds for this time
    List<String> medNames = _meds
        .where((m) => m['time'] == time)
        .map((m) => m['name'] as String)
        .toList();
    
    if (medNames.isEmpty) {
      // Cancel if empty
       await NotificationService().cancelMyNotification(time);
    } else {
      // Schedule group
      await NotificationService().scheduleMedicationGroup(time, medNames);
    }
  }

  // --- WATER ---
  Future<void> addWater(int amount) async {
    _waterCount += amount;
    if (_waterCount < 0) _waterCount = 0;
    
    await _prefs.setInt('water_count', _waterCount);
    notifyListeners();
  }

  Future<void> setWaterGoal(int goal) async {
    _waterGoal = goal;
    await _prefs.setInt('water_goal', goal);
    notifyListeners();
  }
  
  Future<void> resetDaily() async {
    _waterCount = 0;
    for (var m in _meals) {
      m['completed'] = false;
      m['content'] = '';
    }
    for (var m in _meds) {
      m['taken'] = false;
    }
    
    await _prefs.setInt('water_count', 0);
    await saveMeals();
    await _prefs.setString('meds', jsonEncode(_meds));
    notifyListeners();
  }
  // --- CHAT HISTORY ---
  List<Map<String, String>> _chatHistory = [];
  List<Map<String, String>> get chatHistory => _chatHistory;

  Future<void> _loadChatHistory() async {
    final String? jsonString = _prefs.getString('chat_history');
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _chatHistory = decoded.map((e) => Map<String, String>.from(e)).toList();
      } catch (e) {
        debugPrint("Chat history load error: $e");
      }
    }
  }

  Future<void> addChatMessage(String role, String text) async {
    _chatHistory.add({"role": role, "text": text});
    if (_chatHistory.length > 50) {
      _chatHistory.removeAt(0); // Keep last 50
    }
    await _prefs.setString('chat_history', jsonEncode(_chatHistory));
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    _chatHistory.clear();
    await _prefs.remove('chat_history');
    notifyListeners();
  }
}
