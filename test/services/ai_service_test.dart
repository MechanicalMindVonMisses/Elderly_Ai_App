
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_assistant/services/ai_service.dart';

void main() {
  late AIService aiService;

  setUp(() {
    aiService = AIService();
  });

  group('AIService Nutrition Logic Tests', () {
    // -------------------------------------------------------------------------
    // HAPPY PATH
    // -------------------------------------------------------------------------
    test('Calculates simple single item correctly', () {
      // "yumurta" -> 70 cal
      final result = aiService.calculateLocalNutrition("1 yumurta yedim");
      expect(result, contains("✅ Kayıt Alındı: Yumurta"));
      expect(result, contains("🔥 Toplam: 70 kcal"));
    });

    test('Calculates multiple items correctly (summation)', () {
      // "yumurta" (70) + "tost" (300) = 370
      final result = aiService.calculateLocalNutrition("1 yumurta ve 1 tost");
      
      expect(result, contains("Yumurta"));
      expect(result, contains("Tost"));
      expect(result, contains("🔥 Toplam: 370 kcal"));
    });

    test('Handles text numbers correctly', () {
      // "iki" (2) * "yumurta" (70) = 140
      final result = aiService.calculateLocalNutrition("iki yumurta");
      expect(result, contains("2.0 x Yumurta"));
      expect(result, contains("🔥 Toplam: 140 kcal"));
    });

    test('Handles decimal/half quantities', () {
      // "yarım" (0.5) * "ekmek" (70) = 35
      final result = aiService.calculateLocalNutrition("yarım ekmek");
      expect(result, contains("0.5 x Ekmek"));
      expect(result, contains("🔥 Toplam: 35 kcal"));
    });

    // -------------------------------------------------------------------------
    // EDGE CASES
    // -------------------------------------------------------------------------
    test('Handles unknown items gracefully', () {
      final result = aiService.calculateLocalNutrition("3 tane uzaylı");
      expect(result, contains("Üzgünüm"));
      expect(result, contains("veritabanımda olan bir yemek bulamadım"));
    });

    test('Handles mixed known and unknown items', () {
      // "yumurta" (known) + "taş" (unknown)
      // Should still calculate yumurta and ideally ignore or handle partial failure
      // Current logic strictly parses parts. If one part is garbage, it ignores it.
      final result = aiService.calculateLocalNutrition("1 yumurta ve 3 taş");
      
      // Should find yumurta
      expect(result, contains("Yumurta"));
      expect(result, contains("🔥 Toplam: 70 kcal")); 
      // Should match the successful partial report
    });

    test('Handles complex conjunctions', () {
      // "ve", "bir de", "ile"
      final result = aiService.calculateLocalNutrition("1 yumurta ile 1 tost bir de 1 çay");
      // 70 + 300 + 0 = 370
      expect(result, contains("🔥 Toplam: 370 kcal"));
    });

    test('Handles implicit quantity (no number specified)', () {
      // "yumurta" defaults to 1
      final result = aiService.calculateLocalNutrition("yumurta yedim");
      expect(result, contains("🔥 Toplam: 70 kcal"));
    });

    // -------------------------------------------------------------------------
    // FAILURE / SECURITY / ROBUSTNESS
    // -------------------------------------------------------------------------
    test('Handles empty string', () {
      final result = aiService.calculateLocalNutrition("");
      expect(result, contains("Üzgünüm")); // Should return the "not found" message
    });

    test('Handles massive quantities (overflow check logic)', () {
      // 1000 yumurta -> 70,000 kcal. 
      // Dart doubles handle this easily, but UI display might need checking.
      final result = aiService.calculateLocalNutrition("1000 yumurta");
      expect(result, contains("70000 kcal"));
    });

    test('Handles input with suffixes (Basic Fuzzy Match)', () {
      // "yumurtalar" -> should match "yumurta"
      final result = aiService.calculateLocalNutrition("3 yumurtalar");
      expect(result, contains("Yumurta"));
    });

    test('Case insensitivity check', () {
      final result = aiService.calculateLocalNutrition("1 TOST ve 2 YUMURTA");
      expect(result, contains("🔥 Toplam: 440 kcal")); // 300 + 140
    });
  });
}
