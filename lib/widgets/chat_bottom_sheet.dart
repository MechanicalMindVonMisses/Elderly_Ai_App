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
  
  String _statusText = "Hazır";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
    _initStt(); // Initialize STT early to check languages
  }

  Future<void> _initStt() async {
    bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
    );
    
    if (available) {
       var systemLocales = await _speech.locales();
       var trLocale;
       try {
         trLocale = systemLocales.firstWhere(
           (locale) => locale.localeId.toLowerCase().contains("tr"),
         );
       } catch (e) {
         // Not found
       }
       
       if (mounted) {
         setState(() {
           if (trLocale != null) {
              _statusText = "Dil: ${trLocale.localeId} (Algılandı)";
           } else {
              _statusText = "Dil: TR Bulunamadı! English kullanılacak.";
           }
         });
       }
    } else {
       if (mounted) setState(() => _statusText = "Ses tanıması kullanılamıyor");
    }
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setSpeechRate(0.5); // Normal speaking rate
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // ... _speak, dispose, _sendMessage unchanged ...

  void _toggleListening() async {
    if (!_isListening) {
      // Re-initialize check not strictly needed if _initStt called, but safe
      bool available = _speech.isAvailable;
      if (!available) {
         await _initStt();
         available = _speech.isAvailable;
      }
      
      if (available) {
        // Redo lookup to be sure
        var systemLocales = await _speech.locales();
        var selectedLocaleId = "tr_TR"; 
        
        try {
          var trLocale = systemLocales.firstWhere(
            (locale) => locale.localeId.toLowerCase().contains("tr"),
          );
          selectedLocaleId = trLocale.localeId;
        } catch (e) {
           debugPrint("Fallback to default locale");
        }

        setState(() {
          _isListening = true;
          _statusText = "Dinleniyor... ($selectedLocaleId)";
        });

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
      setState(() {
        _isListening = false;
        _statusText = "Durduruldu";
      });
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build code ...
    // Update Input Area to show status text
    // (I will replace the Container child logic to include the Text under the row or inside it)
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
                 // ... ListView logic ...
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
            
          // Status Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_statusText, style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    onSubmitted: (val) => _sendMessage(val),
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
