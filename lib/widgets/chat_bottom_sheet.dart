import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class ChatBottomSheet extends StatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setSpeechRate(0.5); // Normal speaking rate
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {bool isVoiceInput = false}) async {
    if (text.trim().isEmpty) return;
    
    final storage = Provider.of<StorageService>(context, listen: false);

    storage.addChatMessage("user", text);
    
    setState(() {
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Get AI Response
    final aiService = Provider.of<AIService>(context, listen: false);
    
    // Check intent first (local logic)
    final intent = aiService.analyzeIntent(text);
    String responseText;
    
    if (intent['reply'] != null) {
      responseText = intent['reply'];
      
      // Execute ACTION
      final storage = Provider.of<StorageService>(context, listen: false);
      
      if (intent['action'] == "ADD_WATER") {
          storage.addWater(intent['amount']);
      }
      else if (intent['action'] == "LOG_FOOD_INTENT") {
        // Parse Meal Action
        // "Kahvaltıda 7 yumurta yedim" -> Meal: Kahvaltı, Content: 7 yumurta
        
        String lower = text.toLowerCase();
        String mealId = "";
        String mealName = "";
        
        if (RegExp(r'kahvalt', caseSensitive: false).hasMatch(lower)) {
           mealId = "101"; mealName = "Kahvaltı";
        } else if (RegExp(r'(ogle|oglen|öğle|ogle)', caseSensitive: false).hasMatch(lower)) {
           mealId = "103"; mealName = "Öğle Yemeği";
        } else if (RegExp(r'(aksam|akşam)', caseSensitive: false).hasMatch(lower)) {
           mealId = "104"; mealName = "Akşam Yemeği";
        } else if (RegExp(r'(ara|ara ogun|ara öğün)', caseSensitive: false).hasMatch(lower)) {
           mealId = "102"; mealName = "Ara Öğün";
        }
        
        if (mealId.isNotEmpty) {
           // Extract Content: Remove keywords
           // Updated Regex to robustly remove meal names even with typos
           String content = text.replaceAll(RegExp(r'\b(kahvalt[a-z]*|ogle[a-z]*|öğle[a-z]*|aksam[a-z]*|akşam[a-z]*|ara\s*o[a-z]*|ogun|öğün|yemeği|yemegi|yedim|içtim|ictim|yiyorum|iciyorum)\b', caseSensitive: false), "")
                                .replaceAll(RegExp(r'\s+'), " ")
                                .trim();
                                
           if (content.isEmpty) content = "Yendi";
           
           // 2. ASK AI FOR NUTRITION INFO (Voice Feedback)
           // "Kahvaltıda 7 yumurta yedim" -> Logged.
           // Now ask: "7 yumurta kaç kalori ve besin değeri nedir?"
           
           String prompt = "$content kaç kalori ve besin değerleri nedir?";
           String nutritionInfo = await aiService.sendToLLM(prompt, history: storage.chatHistory);
           
           // Update Storage with Content AND Nutrition
           storage.updateMeal(mealId, completed: true, content: content, nutrition_notes: nutritionInfo);
           
           // Combine responses
           responseText = "$mealName için kayıt alındı: $content. ✅\n\n$nutritionInfo";
           
        } else {
           responseText = "Hangi öğün olduğunu anlayamadım. Lütfen 'Kahvaltıda yumurta yedim' gibi söyleyin.";
        }
      }
      else if (intent['action'] == "ADD_MED_INTENT") {
           // Parse "Saat 02:00 için prozac ilacımı ekle"
           // Simple regex for format: "Saat HH:MM ... [medName] ... ekle"
           try {
             final timeRegex = RegExp(r'(\d{1,2})[:.](\d{2})');
             final timeMatch = timeRegex.firstMatch(text);
             
             if (timeMatch != null) {
                final hour = int.parse(timeMatch.group(1)!);
                final minute = int.parse(timeMatch.group(2)!);
                final time = TimeOfDay(hour: hour, minute: minute);
                
                // Extract Name: Remove time and keywords (handles both Turkish and English chars)
                // Keywords: saat, icin/için, ilacimi/ilacımı, ilaci/ilacı, ilac/ilaç, ekle, yaz
                String name = text.replaceAll(timeRegex, "")
                                  .replaceAll(RegExp(r'\b(saat|icin|için|ilacimi|ilacımı|ilaci|ilacı|ilac|ilaç|ekle|yaz|hatirlat|hatırlat)\b', caseSensitive: false), "")
                                  .replaceAll(RegExp(r'\s+'), " ") // Collapse multiple spaces
                                  .trim();
                
                // Capitalize first letter
                if (name.isNotEmpty) {
                  name = "${name[0].toUpperCase()}${name.substring(1)}";
                }
                
                if (name.isEmpty) name = "İlaç";
                
                // Convert TimeOfDay to String HH:MM
                final timeStr = "${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}";
                storage.addMed(name, timeStr);
                
                responseText = "$name ilacı saat $timeStr için eklendi. ✅";
             } else {
                responseText = "Saati anlayamadım. Lütfen 'Saat 09:00 Tansiyon ilacı' şeklinde söyleyin.";
             }
           } catch (e) {
             responseText = "Bir hata oluştu: $e";
           }
      }
      // Save AI Response
      storage.addChatMessage("ai", responseText);
    } else {
      // Fallback to LLM
      responseText = await aiService.sendToLLM(text, history: storage.chatHistory);
      storage.addChatMessage("ai", responseText);
    }

    // Speak the response ONLY if voice input was used
    if (isVoiceInput) {
      await _speak(responseText);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
      );
      
      if (available) {
        // Look for Turkish Locale
        var systemLocales = await _speech.locales();
        var selectedLocaleId = "tr_TR"; // Default fallback
        
        try {
          var trLocale = systemLocales.firstWhere(
            (locale) => locale.localeId.toLowerCase().contains("tr"),
          );
          selectedLocaleId = trLocale.localeId;
          debugPrint("STT Selected Locale: $selectedLocaleId");
        } catch (e) {
          debugPrint("STT Turkish locale not found, using default: $e");
        }

        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            if (result.finalResult) {
               setState(() => _isListening = false);
               _sendMessage(result.recognizedWords, isVoiceInput: true);
            }
          },
          localeId: selectedLocaleId, 
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 80% of screen height
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sohbet Asistanı", style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: Icon(Icons.close), onPressed: () {
                    _flutterTts.stop();
                    Navigator.pop(context);
                }),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: Consumer<StorageService>(
              builder: (context, storage, child) {
                final messages = storage.chatHistory;
                
                if (messages.isEmpty) {
                   return Center(child: Text("Henüz mesaj yok.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                          ),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Bir şeyler yazın...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Mic Button
                FloatingActionButton(
                  mini: true,
                  onPressed: _toggleListening,
                  backgroundColor: _isListening ? Colors.red : Colors.blueGrey,
                  child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                ),
                
                const SizedBox(width: 8),
                
                // Send Button
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _sendMessage(_textController.text),
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
