import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AIService {
  // Remote Ubuntu Server IP
  static const String VLLM_URL = "http://72.60.108.101:8000/v1/chat/completions"; 
  static const String MODEL = "qwen2.5:7b-instruct";
  
  // --- EXPANDED LOCAL DATABASE (Verified) ---
  static const Map<String, Map<String, dynamic>> FOOD_DB = {
   // KAHVALTILIKLAR (Standart Porsiyonlar: Peynir 1 dilim, Zeytin 8 adet, Bal/Yağ 1 tatlı kaşığı)
    "yumurta": {"cal": 75, "prot": 6, "carb": 0.6, "fat": 5}, // 1 adet
    "haslanmis yumurta": {"cal": 75, "prot": 6.3, "carb": 0.6, "fat": 5.3}, // 1 adet
    "omlet": {"cal": 185, "prot": 12, "carb": 2, "fat": 14}, // 2 yumurtalı sade
    "menemen": {"cal": 220, "prot": 10, "carb": 12, "fat": 15}, // 1 orta porsiyon
    "ekmek": {"cal": 65, "prot": 2, "carb": 13, "fat": 0.5}, // 1 dilim (25g)
    "dilim ekmek": {"cal": 65, "prot": 2, "carb": 13, "fat": 0.5},
    "simit": {"cal": 320, "prot": 10, "carb": 55, "fat": 8}, // 1 tam adet
    "pogaca": {"cal": 280, "prot": 6, "carb": 30, "fat": 16}, // 1 adet
    "borek": {"cal": 350, "prot": 10, "carb": 35, "fat": 18}, // 1 porsiyon (dilim/kol böreği)
    "peynir": {"cal": 90, "prot": 6, "carb": 1, "fat": 7}, // 1 dilim (30g)
    "beyaz peynir": {"cal": 90, "prot": 6, "carb": 1, "fat": 7},
    "kasar": {"cal": 105, "prot": 8, "carb": 1, "fat": 8}, // 1 dilim (30g)
    "kasar peyniri": {"cal": 105, "prot": 8, "carb": 1, "fat": 8},
    "zeytin": {"cal": 45, "prot": 0.5, "carb": 1, "fat": 4.5}, // 1 porsiyon (8-10 adet)
    "siyah zeytin": {"cal": 45, "prot": 0.5, "carb": 1, "fat": 4.5},
    "yesil zeytin": {"cal": 40, "prot": 0.5, "carb": 1, "fat": 4},
    "bal": {"cal": 60, "prot": 0, "carb": 15, "fat": 0}, // 1 yemek kaşığı
    "tereyagi": {"cal": 105, "prot": 0, "carb": 0, "fat": 12}, // 1 yemek kaşığı (15g)
    "sucuk": {"cal": 220, "prot": 10, "carb": 1, "fat": 20}, // 1 porsiyon (50g - yaklaşık 6-8 dilim)
    "salam": {"cal": 120, "prot": 6, "carb": 1, "fat": 10}, // 1 porsiyon (4-5 dilim)

    // ÇORBALAR (1 Kase - 250 ml)
    "corba": {"cal": 150, "prot": 5, "carb": 15, "fat": 5},
    "mercimek": {"cal": 140, "prot": 8, "carb": 20, "fat": 4},
    "mercimek corbasi": {"cal": 140, "prot": 8, "carb": 20, "fat": 4},
    "ezogelin": {"cal": 135, "prot": 6, "carb": 18, "fat": 5},
    "tarhana": {"cal": 150, "prot": 5, "carb": 22, "fat": 5},
    "yayla corbasi": {"cal": 115, "prot": 4, "carb": 12, "fat": 6},
    "domates corbasi": {"cal": 90, "prot": 2, "carb": 14, "fat": 3},
    "sehriye corbasi": {"cal": 120, "prot": 3, "carb": 20, "fat": 3},
    "paca": {"cal": 280, "prot": 22, "carb": 3, "fat": 18},

    // ANA YEMEKLER (1 Standart Porsiyon - Yaklaşık 200-250g)
    "kuru fasulye": {"cal": 320, "prot": 16, "carb": 40, "fat": 10},
    "nohut": {"cal": 340, "prot": 16, "carb": 45, "fat": 11},
    "taze fasulye": {"cal": 130, "prot": 3, "carb": 12, "fat": 8},
    "karniyarik": {"cal": 280, "prot": 14, "carb": 12, "fat": 20},
    "imambayildi": {"cal": 220, "prot": 4, "carb": 18, "fat": 16},
    "manti": {"cal": 450, "prot": 16, "carb": 65, "fat": 18},
    "pilav": {"cal": 330, "prot": 4, "carb": 58, "fat": 9},
    "bulgur": {"cal": 240, "prot": 7, "carb": 42, "fat": 5},
    "bulgur pilavi": {"cal": 240, "prot": 7, "carb": 42, "fat": 5},
    "makarna": {"cal": 350, "prot": 11, "carb": 65, "fat": 5},
    "dolma": {"cal": 250, "prot": 10, "carb": 28, "fat": 12}, // 2 adet orta boy
    "biber dolmasi": {"cal": 250, "prot": 10, "carb": 28, "fat": 12},
    "sarma": {"cal": 180, "prot": 4, "carb": 25, "fat": 8}, // 5-6 adet yaprak sarma
    "yaprak sarma": {"cal": 180, "prot": 4, "carb": 25, "fat": 8},
    "kofte": {"cal": 280, "prot": 24, "carb": 8, "fat": 18}, // 1 porsiyon (5-6 adet/150g)
    "izgara kofte": {"cal": 280, "prot": 24, "carb": 8, "fat": 18},
    "turlu": {"cal": 180, "prot": 6, "carb": 18, "fat": 10},
    "mucver": {"cal": 220, "prot": 8, "carb": 18, "fat": 14}, // 2-3 adetlik porsiyon
    "ispanak": {"cal": 140, "prot": 5, "carb": 12, "fat": 8},
    "pirasa": {"cal": 150, "prot": 3, "carb": 18, "fat": 8},

    // KEBAP & PİDE (1 Standart Porsiyon)
    "lahmacun": {"cal": 220, "prot": 12, "carb": 28, "fat": 7}, // 1 adet
    "pide": {"cal": 550, "prot": 20, "carb": 70, "fat": 22}, // 1 porsiyon/adet
    "kiymali pide": {"cal": 600, "prot": 24, "carb": 70, "fat": 25},
    "kasarli pide": {"cal": 620, "prot": 25, "carb": 65, "fat": 28},
    "doner": {"cal": 450, "prot": 32, "carb": 25, "fat": 26}, // Porsiyon (Pilavüstü/Ekmeksiz)
    "et doner": {"cal": 480, "prot": 35, "carb": 20, "fat": 30},
    "tavuk doner": {"cal": 400, "prot": 30, "carb": 25, "fat": 20},
    "iskender": {"cal": 880, "prot": 38, "carb": 60, "fat": 50},
    "adana": {"cal": 420, "prot": 24, "carb": 5, "fat": 35}, // 1 şiş/porsiyon (lavaşsız)
    "urfa": {"cal": 410, "prot": 24, "carb": 5, "fat": 33},
    "durum": {"cal": 580, "prot": 28, "carb": 65, "fat": 24},
    "cig kofte": {"cal": 220, "prot": 6, "carb": 35, "fat": 6}, // 1 porsiyon (5 adet orta boy)

    // SEBZE & MEYVE (100g veya 1 orta boy adet baz alınarak düzenlendi)
    "elma": {"cal": 52, "prot": 0.3, "carb": 14, "fat": 0.2},
    "muz": {"cal": 89, "prot": 1.1, "carb": 23, "fat": 0.3},
    "armut": {"cal": 57, "prot": 0.4, "carb": 15, "fat": 0.1},
    "portakal": {"cal": 47, "prot": 0.9, "carb": 12, "fat": 0.1},
    "mandalina": {"cal": 53, "prot": 0.8, "carb": 13, "fat": 0.3},
    "karpuz": {"cal": 30, "prot": 0.6, "carb": 8, "fat": 0.2},
    "kavun": {"cal": 34, "prot": 0.8, "carb": 8, "fat": 0.2},
    "cilek": {"cal": 32, "prot": 0.7, "carb": 8, "fat": 0.3},
    "erik": {"cal": 46, "prot": 0.7, "carb": 11, "fat": 0.3},
    "salata": {"cal": 80, "prot": 2, "carb": 8, "fat": 5}, // Yağlı soslu standart porsiyon
    "coban salata": {"cal": 100, "prot": 2, "carb": 8, "fat": 7},
    "domates": {"cal": 18, "prot": 0.9, "carb": 4, "fat": 0.2},
    "salatalik": {"cal": 15, "prot": 0.7, "carb": 3.6, "fat": 0.1},
    "havuc": {"cal": 41, "prot": 0.9, "carb": 10, "fat": 0.2},
    "patlican": {"cal": 25, "prot": 1, "carb": 6, "fat": 0.2},

    // İÇECEKLER (1 bardak - 200-250ml)
    "ayran": {"cal": 76, "prot": 4, "carb": 5, "fat": 4},
    "cay": {"cal": 1, "prot": 0.1, "carb": 0.2, "fat": 0},
    "kahve": {"cal": 2, "prot": 0.3, "carb": 0, "fat": 0},
    "turk kahvesi": {"cal": 7, "prot": 0.5, "carb": 1, "fat": 0.1},
    "kola": {"cal": 150, "prot": 0, "carb": 37, "fat": 0}, // 1 kutu (330ml)
    "meyve suyu": {"cal": 120, "prot": 1, "carb": 28, "fat": 0},
    "su": {"cal": 0, "prot": 0, "carb": 0, "fat": 0},
  };

  Future<String> sendToLLM(String prompt, {List<Map<String, String>>? history}) async {
    // 1. CHECK LOCAL INTENTS
    
    // A. Nutrition Query
    if (prompt.toLowerCase().contains("kalori") || prompt.toLowerCase().contains("besin")) {
       return calculateLocalNutrition(prompt);
    }

    // C. Prayer Times Query
    if (prompt.toLowerCase().contains("namaz") || prompt.toLowerCase().contains("ezan") || prompt.toLowerCase().contains("vakit")) {
       String? times = await _getPrayerTimes(prompt);
       if (times != null) return times;
    }

    // D. Ramadan Query
    if (prompt.toLowerCase().contains("iftar") || prompt.toLowerCase().contains("sahur") || prompt.toLowerCase().contains("ramazan")) {
       String? ramadanInfo = await _checkRamadan(prompt);
       if (ramadanInfo != null) return ramadanInfo;
    }

    // 2. REMOTE SERVER (Fallback)
    try {
      String systemContext = 
          "Sen 'Can' isminde yardımsever bir Türk'sün.\n"
          "KURALLAR:\n"
          "1. **SADECE** Türkçe konuş. 'Regionel', 'Option' gibi kelimeler YASAK.\n"
          "2. **ASLA** ama ASLA liste yapma (1., 2., 3. KULLANMA). Paragraf yaz.\n"
          "3. Yemek sorulursa: Sadece 'Kuru Fasulye, Pilav, Mantı, Çay' gibi %100 bilinen şeyleri öner. 'Şakşavuru' gibi uydurma şeyler YASAK.\n"
          "4. Kısa cevap ver. En fazla 2 cümle.\n"
          "5. Samimi ol ama labali olma.\n\n"
          "ÖRNEK:\n"
          "Soru: Misafir var ne yapayım?\n"
          "Cevap: Misafir baş tacıdır, hiç macera arama. Güzel bir kuru fasulye pilav yap, yanına da turşu çıkar, herkes parmaklarını yer.\n";
      
      // B. Weather Query (Inject Context)
      if (prompt.toLowerCase().contains("hava") || prompt.toLowerCase().contains("sicaklik") || prompt.toLowerCase().contains("derece")) {
         String? weather = await _getWeather(prompt);
         if (weather != null) {
            systemContext += " ŞU ANKI HAVA DURUMU BİLGİSİ: $weather";
         }
      }

      // Prepare Messages with History
      List<Map<String, String>> messages = [
        {"role": "system", "content": systemContext}
      ];

      // Add History (Last 10)
      if (history != null && history.isNotEmpty) {
          int start = history.length > 10 ? history.length - 10 : 0;
          for (int i = start; i < history.length; i++) {
             // Convert 'ai' role to 'assistant' for Ollama
             String role = history[i]['role'] == 'user' ? 'user' : 'assistant';
             messages.add({"role": role, "content": history[i]['text'] ?? ""});
          }
      }

      // Add Current Prompt
      messages.add({"role": "user", "content": prompt});

      final response = await http.post(
        Uri.parse(VLLM_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ollama', 
        },
        body: jsonEncode({
          "model": MODEL,
          "messages": messages,
          "temperature": 0.2, // Low temp for maximum instruction adherence
          "max_tokens": 150
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      print("[AIService] Server Offline: $e");
      
      // Fallback: Local Intent Analysis
      final localIntent = analyzeIntent(prompt);
      if (localIntent['reply'] != null) {
        return localIntent['reply'] + "\n(İnternet yok, çevrimdışı mod)";
      }
    }
    return "Şu an sunucuya ulaşamıyorum.";
  }

  // --- SHARED LOCATION LOGIC ---
  Future<Map<String, dynamic>?> _getLocation(String prompt) async {
    String? city;
    List<String> cities = ["istanbul", "ankara", "izmir", "antalya", "bursa", "adana", "gaziantep", "konya", "samsun", "trabzon", "erzurum", "diyarbakir", "eskisehir", "mersin"];
    
    String lower = prompt.toLowerCase();
    for (var c in cities) {
      if (lower.contains(c)) {
        city = c;
        break;
      }
    }

    double lat = 41.00; 
    double lon = 28.97; // Default Istanbul
    String name = "İstanbul";
    bool locationFound = false;

    if (city == null) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
           permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 5)
            );
            lat = position.latitude;
            lon = position.longitude;
            name = "Konumunuz";
            locationFound = true;
        }
      } catch (e) {
         print("GPS Error: $e");
      }
    } else {
       // Geocode City Name
        try {
          final geoUrl = Uri.parse("https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=tr&format=json");
          final geoRes = await http.get(geoUrl).timeout(const Duration(seconds: 5));
          if (geoRes.statusCode == 200) {
             final geoData = jsonDecode(geoRes.body);
             if (geoData['results'] != null && (geoData['results'] as List).isNotEmpty) {
                lat = geoData['results'][0]['latitude'];
                lon = geoData['results'][0]['longitude'];
                name = geoData['results'][0]['name'];
                locationFound = true;
             }
          }
       } catch (e) { print("Geocode Error: $e"); }
    }
    
    // Always return a value (Default if not found)
    return {"lat": lat, "lon": lon, "name": name};
  }

  // --- LOCAL WEATHER ---
  Future<String?> _getWeather(String prompt) async {
    final loc = await _getLocation(prompt);
    if (loc == null) return null;
    
    try {
      final weatherUrl = Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=${loc['lat']}&longitude=${loc['lon']}&current_weather=true");
      final wRes = await http.get(weatherUrl).timeout(const Duration(seconds: 5));
      
      if (wRes.statusCode == 200) {
         final wData = jsonDecode(wRes.body);
         final current = wData['current_weather'];
         final temp = current['temperature'];
         
         String displayName = loc['name'] ?? "Bölgeniz";
         return "🌤️ $displayName için hava sıcaklığı şu an $temp°C.";
      }
    } catch (e) {
      print("Weather API Error: $e");
    }
    return null;
  }

  // --- PRAYER TIMES ---
  Future<String?> _getPrayerTimes(String prompt) async {
    final loc = await _getLocation(prompt);
    if (loc == null) return null;
    
    try {
      // Method 13 = Diyanet
      final date = DateTime.now();
      final dateStr = date.toIso8601String().split('T')[0];
      final url = Uri.parse("https://api.aladhan.com/v1/timings/$dateStr?latitude=${loc['lat']}&longitude=${loc['lon']}&method=13");
      
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
         final data = jsonDecode(res.body);
         final timings = data['data']['timings']; // Map of "Fajr": "05:30"
         
         // 1. Check if user is asking for a specific time countdown
         // "aksam namazina ne kadar var", "kaldı", "kaç saat"
         String lower = prompt.toLowerCase();
         String? targetPrayer;
         String? targetTime;
         String targetName = "";

         if (lower.contains("aksam") || lower.contains("akşam")) {
            targetPrayer = "Maghrib"; targetName = "Akşam";
         } else if (lower.contains("ogle") || lower.contains("öğle")) {
            targetPrayer = "Dhuhr"; targetName = "Öğle";
         } else if (lower.contains("ikindi")) {
            targetPrayer = "Asr"; targetName = "İkindi";
         } else if (lower.contains("yatsi") || lower.contains("yatsı")) {
            targetPrayer = "Isha"; targetName = "Yatsı";
         } else if (lower.contains("sabah") || lower.contains("imsak")) {
            targetPrayer = "Fajr"; targetName = "Sabah";
         } else if (lower.contains("gunes") || lower.contains("güneş")) {
            targetPrayer = "Sunrise"; targetName = "Güneş";
         }

         if (targetPrayer != null && (lower.contains("ne kadar") || lower.contains("kaldi") || lower.contains("kaldı") || lower.contains("var"))) {
             // Calculate Countdown
             targetTime = timings[targetPrayer]; // "18:20"
             if (targetTime != null) {
                 final now = DateTime.now();
                 final parts = targetTime.split(':');
                 final targetDt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
                 
                 final diff = targetDt.difference(now);
                 
                 if (diff.isNegative) {
                    return "⏰ Bugünkü $targetName namazı saati geçti ($targetTime).";
                 } else {
                    final hours = diff.inHours;
                    final minutes = diff.inMinutes % 60;
                    if (hours > 0) {
                        return "⏳ ${loc['name']} için $targetName namazına $hours saat $minutes dakika var.";
                    } else {
                        return "⏳ ${loc['name']} için $targetName namazına $minutes dakika var.";
                    }
                 }
             }
         }

         // Default List logic
         return "🕌 ${loc['name']} Namaz Vakitleri:\n"
                "Sabah: ${timings['Fajr']}\n"
                "Öğle: ${timings['Dhuhr']}\n"
                "İkindi: ${timings['Asr']}\n"
                "Akşam: ${timings['Maghrib']}\n"
                "Yatsı: ${timings['Isha']}";
      }
    } catch (e) {
      print("Prayer API Error: $e");
    }
    return null;
  }

  // --- RAMADAN LOGIC ---
  Future<String?> _checkRamadan(String prompt) async {
     final loc = await _getLocation(prompt);
     if (loc == null) return null;
     
     try {
       // 1. Get Hijri Date
       final date = DateTime.now();
       final url = Uri.parse("https://api.aladhan.com/v1/gToH/${date.day}-${date.month}-${date.year}");
       final res = await http.get(url).timeout(const Duration(seconds: 5));
       
       if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final hijri = data['data']['hijri'];
          final int month = hijri['month']['number']; // 9 is Ramadan
          final String monthName = hijri['month']['en']; // e.g. Ramadan
          
          if (month == 9) {
             // IT IS RAMADAN! Show Iftar/Sahur
             final timingsUrl = Uri.parse("https://api.aladhan.com/v1/timings/${date.toIso8601String().split('T')[0]}?latitude=${loc['lat']}&longitude=${loc['lon']}&method=13");
             final tRes = await http.get(timingsUrl).timeout(const Duration(seconds: 5));
             if (tRes.statusCode == 200) {
                 final tData = jsonDecode(tRes.body);
                 final timings = tData['data']['timings'];
                 
                 return "🌙 Hayırlı Ramazanlar!\n"
                        "📍 ${loc['name']} için:\n"
                        "Sahur (İmsak): ${timings['Fajr']}\n"
                        "İftar (Akşam): ${timings['Maghrib']}";
             }
          } else {
             // NOT RAMADAN - Show Countdown
             int monthsLeft = 9 - month;
             if (monthsLeft < 0) monthsLeft += 12; 
             
             return "Şu an Hicri takvime göre $monthName ayındayız.\n"
                    "Mübarek Ramazan ayına yaklaşık $monthsLeft ay kaldı.";
          }
       }
     } catch (e) {
       print("Ramadan API Error: $e");
     }
     return null;
  }

  // ADDING NEW ENTRIES TO DB (Since I can't edit the const map directly in this tool call easily without replacing 100 lines, 
  // I will rely on the matching logic finding 'kaşar' for 'kaşarlı tost' if I don't add it, but it's better to be explicit.
  // Actually, I can't modify the static const Map above in the same call easily if I am targeting this function at the bottom.
  // I will treat 'tost' as a special case inside finding logic or just assume standard matching if 'tost' was added. 
  // Wait, I should add 'tost' to the DB first? 
  // The user asked to "fix the logic". I will assume standard matching.
  // BUT the user input "tost" WILL fail if 'tost' isn't in DB.
  // I will add a local override map inside this function for missing items to save space vs editing the huge map.
  
  // Made public for unit testing
  String calculateLocalNutrition(String prompt) {
     String lower = prompt.toLowerCase();
     // Remove verbs (yedim, içtim) but KEEP conjunctions (ve, ile) so we can split later
     lower = lower.replaceAll(RegExp(r'(yedim|yedik|yiyor|ictim|içtim|kac|kaç|kalori|besin|degeri|nedir|tane|adet|porsiyon|tabak|kase|bardak|dilim|kasik|kaşık)'), "").trim();
     lower = _convertTextNumbers(lower);
     
     // Specific quick fix for 'tost' if missing in main DB
     Map<String, Map<String, dynamic>> localExtras = {
       "tost": {"cal": 300, "prot": 12, "carb": 30, "fat": 15},
       "karisik tost": {"cal": 350, "prot": 15, "carb": 30, "fat": 18},
       "sucuklu tost": {"cal": 350, "prot": 15, "carb": 30, "fat": 18},
     };

     // Split by conjunctions
     List<String> parts = lower.split(RegExp(r'(, | ve | ile | \+ | artı | bir de | yanina | üstüne )'));
     
     double totalCal = 0;
     double totalProt = 0;
     double totalFat = 0;
     double totalCarb = 0;
     List<String> foundItems = [];

     for (String part in parts) {
        String cleanPart = part.replaceAll(RegExp(r'(kac|kami|kalori|besin|degeri|nedir|tane|adet|porsiyon|tabak|kase|bardak|dilim|kasik|kaşık)'), "").trim();
        if (cleanPart.isEmpty) continue;

        double amount = 1.0;
        final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(cleanPart);
        if (match != null) {
           amount = double.tryParse(match.group(1)!) ?? 1.0;
           cleanPart = cleanPart.replaceAll(match.group(0)!, "").trim();
        }
        
        // Find Key
        String? foodKey;
        // Check local extras first
        if (localExtras.containsKey(cleanPart)) foodKey = cleanPart;
        else {
           // Check main DB
           if (FOOD_DB.containsKey(cleanPart)) foodKey = cleanPart;
           else {
               int maxLen = 0;
               for (var key in FOOD_DB.keys) {
                  if ((cleanPart.contains(key) || key.contains(cleanPart)) && key.length > maxLen) {
                      if (cleanPart.length < 3 || cleanPart.contains(key)) {
                          foodKey = key;
                          maxLen = key.length;
                      }
                  }
               }
               // Fallback check extras partial
               for (var key in localExtras.keys) {
                  if (cleanPart.contains(key) && key.length > maxLen) {
                       foodKey = key;
                       maxLen = key.length;
                  }
               }
           }
        }

        if (foodKey != null) {
           final data = FOOD_DB.containsKey(foodKey) ? FOOD_DB[foodKey]! : localExtras[foodKey]!;
           
           double iCal = (data['cal'] as num) * amount;
           double iProt = (data['prot'] as num) * amount;
           double iCarb = (data['carb'] as num) * amount;
           double iFat = ((data.containsKey('fat') ? data['fat'] : 0) as num).toDouble() * amount;
           
           totalCal += iCal;
           totalProt += iProt;
           totalCarb += iCarb;
           totalFat += iFat;
           
           foundItems.add("${amount == 1.0 ? '' : '$amount x '}${foodKey.substring(0,1).toUpperCase()}${foodKey.substring(1)}");
        }
     }
     
     if (foundItems.isNotEmpty) {
        return "✅ Kayıt Alındı: ${foundItems.join(', ')}\n\n"
               "🔥 Toplam: ${totalCal.round()} kcal\n"
               "💪 ${totalProt.toStringAsFixed(1)}g Prot\n"
               "🥓 ${totalFat.toStringAsFixed(1)}g Yağ\n"
               "🍞 ${totalCarb.toStringAsFixed(1)}g Karb";
     }
     
     return "Üzgünüm, yazdıklarınızın içinde veritabanımda olan bir yemek bulamadım. Daha basit yazar mısın? (Örn: 1 yumurta ve 1 dilim ekmek)";
  }
  
  String _convertTextNumbers(String text) {
    Map<String, double> map = {
      "bir": 1.0, "tek": 1.0, "iki": 2.0, "cift": 2.0,
      "uc": 3.0, "üç": 3.0, "dort": 4.0, "dört": 4.0,
      "bes": 5.0, "beş": 5.0, "alti": 6.0, "altı": 6.0,
      "yedi": 7.0, "sekiz": 8.0, "dokuz": 9.0, "on": 10.0,
      "yarim": 0.5, "yarım": 0.5,
    };
    
    String temp = text;
    if (temp.contains("bucuk") || temp.contains("buçuk")) {
        temp = temp.replaceAll("bucuk", ".5").replaceAll("buçuk", ".5");
    }

    map.forEach((key, val) {
       if (temp.contains(key)) { 
          temp = temp.replaceAll(key, val.toString().replaceAll(".0", ""));
       }
    });
    return temp;
  }

  Map<String, dynamic> analyzeIntent(String input) {
    String lower = input.toLowerCase();
    
    if (lower.contains("su ic") || lower.contains("bardak")) {
      lower = _convertTextNumbers(lower);
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(lower);
      int amount = match != null ? int.parse(match.group(1)!) : 1;
      return {"action": "ADD_WATER", "amount": amount, "reply": "Tamam, $amount bardak su ekledim."};
    }

    if (lower.contains("yedim") || lower.contains("ictim")) {
       return {"action": "LOG_FOOD_INTENT", "raw": input, "reply": "Ne yediğinizi not alıyorum..."};
    }
    
    if ((lower.contains("ilac") || lower.contains("hap")) && 
        (lower.contains("ekle") || lower.contains("yaz") || lower.contains("hatirlat"))) {
       return {"action": "ADD_MED_INTENT", "raw": input, "reply": "İlaç hatırlatıcı ekleniyor..."};
    }

    if (lower.contains("ilac") || lower.contains("hap")) {
       return {"action": "MED_INTENT", "raw": input, "reply": "İlaç saatinizi kontrol ediyorum."};
    }

    return {"action": "CHAT", "raw": input, "reply": null};
  }
}
