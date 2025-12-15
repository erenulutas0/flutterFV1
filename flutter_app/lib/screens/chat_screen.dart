import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInConversation = false; // NEW: Conversation mode
  String _selectedVoice = 'female'; // 'female' or 'male'
  String _recognizedText = '';
  List<dynamic> _availableVoices = [];
  bool _speechInitialized = false;
  bool _ttsInitialized = false;
  Timer? _sendTimer; // Timer for auto-sending message after pause

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm Owen, your English conversation tutor. Let's practice English together! How are you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initializeSpeech() async {
    print('Initializing speech recognition...');
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
          
          // Auto-restart listening when speech recognition stops
          // (but only if we're still in conversation mode and not speaking)
          if ((status == 'done' || status == 'notListening') && 
              _isInConversation && !_isSpeaking && !_isLoading) {
            print('Speech stopped, restarting in conversation mode...');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _isInConversation && !_isListening && !_isSpeaking && !_isLoading) {
                _startListening();
              }
            });
          }
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        // Try to restart listening on error
        if (_isInConversation && mounted && !_isSpeaking && !_isLoading) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _isInConversation && !_isListening && !_isSpeaking && !_isLoading) {
              _startListening();
            }
          });
        }
      },
    );
    
    print('Speech recognition available: $available');
    if (available) {
      setState(() {
        _speechInitialized = true;
      });
    } else {
      print('Speech recognition NOT available!');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this browser. Try Chrome.'),
            backgroundColor: AppTheme.accentRed,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _initializeTts() async {
    // Set language first - use US English for best pronunciation
    await _flutterTts.setLanguage('en-US');
    
    // CRITICAL: Await speak completion - this ensures full text is read
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Faster speech = more fluent, less robotic
    await _flutterTts.setSpeechRate(1.0); // Normal speed for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0); // Normal pitch
    
    // Set completion handler - restart listening in conversation mode
    _flutterTts.setCompletionHandler(() async {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        // Auto-restart listening if in conversation mode
        if (_isInConversation && mounted && !_isListening) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && _isInConversation) {
            await _startListening();
          }
        }
      }
    });

    _flutterTts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    // Get available voices
    var voices = await _flutterTts.getVoices;
    if (voices != null) {
      setState(() {
        _availableVoices = List<Map<String, dynamic>>.from(voices);
        _ttsInitialized = true;
        _setVoice();
      });
    } else {
      setState(() {
        _ttsInitialized = true;
      });
    }
  }

  void _setVoice() {
    if (_availableVoices.isEmpty) {
      print('No voices available');
      return;
    }
    
    // Print all available voices for debugging
    print('Available voices:');
    for (var voice in _availableVoices) {
      print('  - ${voice['name']} (${voice['locale']})');
    }
    
    // PRIORITY 1: Google voices (best quality for web)
    // These have the most natural English pronunciation
    List<String> googleVoices = [
      'google us english', 'google uk english',
    ];
    
    // PRIORITY 2: Premium native English voices
    List<String> bestFemaleVoices = [
      'samantha', 'karen', 'moira', 'tessa', 'fiona',
      'google uk english female', 'google us english female',
    ];
    List<String> bestMaleVoices = [
      'daniel', 'oliver', 'alex', 'fred',
      'google uk english male', 'google us english male',
    ];
    
    // PRIORITY 0: Google voices (BEST quality for web - native English)
    List<dynamic> googleVoicesList = _availableVoices.where((voice) {
      String name = (voice['name'] ?? '').toLowerCase();
      return name.contains('google') && name.contains('english');
    }).toList();
    
    if (googleVoicesList.isNotEmpty) {
      // Find matching gender
      var matchingGender = googleVoicesList.where((voice) {
        String name = (voice['name'] ?? '').toLowerCase();
        return name.contains(_selectedVoice);
      }).toList();
      
      var selectedVoice = matchingGender.isNotEmpty ? matchingGender[0] : googleVoicesList[0];
      print('Selected GOOGLE TTS voice: ${selectedVoice['name']} (${selectedVoice['locale']})');
      _flutterTts.setVoice({
        'name': selectedVoice['name'], 
        'locale': selectedVoice['locale']
      });
      return;
    }
    
    // PRIORITY 1: Best quality native English voices
    List<dynamic> bestVoices = _availableVoices.where((voice) {
      String name = (voice['name'] ?? '').toLowerCase();
      String locale = (voice['locale'] ?? '').toLowerCase();
      
      // Must be English
      if (!locale.contains('en') && !locale.contains('us') && !locale.contains('uk')) {
        return false;
      }
      
      if (_selectedVoice == 'female') {
        return bestFemaleVoices.any((best) => name.contains(best));
      } else {
        return bestMaleVoices.any((best) => name.contains(best));
      }
    }).toList();
    
    // If best voices found, use them
    if (bestVoices.isNotEmpty) {
      var selectedVoice = bestVoices[0];
      print('Selected BEST TTS voice: ${selectedVoice['name']} (${selectedVoice['locale']})');
      _flutterTts.setVoice({
        'name': selectedVoice['name'], 
        'locale': selectedVoice['locale']
      });
      return;
    }
    
    // Second priority: Any premium quality voice
    List<String> premiumFemaleVoices = ['samantha', 'karen', 'susan', 'zira', 'hazel'];
    List<String> premiumMaleVoices = ['alex', 'david', 'mark', 'richard', 'james'];
    
    List<dynamic> preferredVoices = _availableVoices.where((voice) {
      String name = (voice['name'] ?? '').toLowerCase();
      String locale = (voice['locale'] ?? '').toLowerCase();
      
      if (!locale.contains('en')) return false;
      
      if (_selectedVoice == 'female') {
        return premiumFemaleVoices.any((premium) => name.contains(premium));
      } else {
        return premiumMaleVoices.any((premium) => name.contains(premium));
      }
    }).toList();

    // Third priority: Any English voice matching gender
    if (preferredVoices.isEmpty) {
      preferredVoices = _availableVoices.where((voice) {
        String name = (voice['name'] ?? '').toLowerCase();
        String locale = (voice['locale'] ?? '').toLowerCase();
        
        if (!locale.contains('en')) return false;
        
        if (_selectedVoice == 'female') {
          return name.contains('female') || name.contains('woman') || name.contains('girl');
        } else {
          return name.contains('male') || name.contains('man') || name.contains('boy');
        }
      }).toList();
    }
    
    // Fourth priority: Any English voice
    if (preferredVoices.isEmpty) {
      preferredVoices = _availableVoices.where((voice) {
        String locale = (voice['locale'] ?? '').toLowerCase();
        return locale.contains('en') || locale.contains('us') || locale.contains('uk');
      }).toList();
    }

    if (preferredVoices.isNotEmpty) {
      var selectedVoice = preferredVoices[0];
      print('Selected TTS voice: ${selectedVoice['name']} (${selectedVoice['locale']})');
      _flutterTts.setVoice({
        'name': selectedVoice['name'], 
        'locale': selectedVoice['locale']
      });
    } else if (_availableVoices.isNotEmpty) {
      // Last resort: use any available voice
      print('Using fallback voice: ${_availableVoices[0]['name']}');
      _flutterTts.setVoice({
        'name': _availableVoices[0]['name'], 
        'locale': _availableVoices[0]['locale']
      });
    }
  }

  // START CONVERSATION - enters continuous conversation mode
  Future<void> _startConversation() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice chat'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    if (!_speechInitialized) {
      await _initializeSpeech();
    }

    setState(() {
      _isInConversation = true;
    });
    
    // Start listening
    await _startListening();
  }
  
  // END CONVERSATION - exits conversation mode
  Future<void> _endConversation() async {
    await _speech.stop();
    await _flutterTts.stop();
    setState(() {
      _isInConversation = false;
      _isListening = false;
      _isSpeaking = false;
      _recognizedText = '';
    });
  }

  Future<void> _startListening() async {
    if (!_isInConversation) {
      print('Not in conversation mode, skipping listen');
      return;
    }
    
    if (!_speechInitialized) {
      print('Speech not initialized, initializing now...');
      await _initializeSpeech();
    }
    
    print('Starting to listen...');
    
    setState(() {
      _recognizedText = '';
      _isListening = true;
    });

    // CONTINUOUS CONVERSATION MODE
    // Auto-send when user stops speaking (using timer-based detection)
    try {
      await _speech.listen(
        onResult: (result) {
          print('Speech result: "${result.recognizedWords}" (final: ${result.finalResult})');
          
          if (mounted && result.recognizedWords.trim().isNotEmpty) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _messageController.text = result.recognizedWords;
            });
            
            // Cancel previous timer
            _sendTimer?.cancel();
            
            // Start new timer - if no new speech for 2 seconds, send the message
            _sendTimer = Timer(const Duration(seconds: 2), () {
              print('Timer fired! Sending message: ${_messageController.text}');
              if (mounted && _isInConversation && !_isLoading && _messageController.text.trim().isNotEmpty) {
                _handleFinalResult(_messageController.text.trim());
              }
            });
          }
          
          // Also handle finalResult if it comes
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            print('Final result received, sending message...');
            _sendTimer?.cancel();
            _handleFinalResult(result.recognizedWords.trim());
          }
        },
        listenFor: const Duration(minutes: 5), // Long listening time
        pauseFor: const Duration(seconds: 5), // Longer pause tolerance
        localeId: 'en-US',
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }
  
  void _handleFinalResult(String message) async {
    if (!_isInConversation || _isLoading || message.isEmpty) {
      print('Skipping handleFinalResult: inConversation=$_isInConversation, isLoading=$_isLoading, message=$message');
      return;
    }
    
    print('Handling final result: $message');
    
    _sendTimer?.cancel();
    await _speech.stop();
    
    setState(() {
      _isListening = false;
      _recognizedText = '';
    });
    
    _messageController.clear();
    await _sendMessageFromVoice(message);
    
    // Listening will restart after TTS completes (in completion handler)
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speak(String text) async {
    if (!_ttsInitialized) {
      await _initializeTts();
    }

    // Stop any ongoing speech before starting new one
    await _flutterTts.stop();

    setState(() {
      _isSpeaking = true;
    });

    // Clean text but DON'T chunk - speak full text at once
    // awaitSpeakCompletion(true) ensures we wait for full completion
    String cleanedText = text.trim();
    
    print('Speaking: $cleanedText');
    
    // Speak the full text - awaitSpeakCompletion will wait until done
    await _flutterTts.speak(cleanedText);
    
    // Mark as done (completion handler also does this)
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _sendMessageFromVoice(String message) async {
    if (message.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();
    
    await _processMessage(message);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Stop listening if active
    if (_isListening) {
      await _stopListening();
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();
    
    await _processMessage(message);
  }

  Future<void> _processMessage(String message) async {

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8082/api/chatbot/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botResponse = data['response'] ?? 'Sorry, I could not generate a response.';
        
        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        
        // Automatically speak the bot's response
        await _speak(botResponse);
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }

    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.purpleGradient,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat_bubble, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Owen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'English Tutor',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.darkSurface,
        actions: [
          // Voice selection dropdown
          PopupMenuButton<String>(
            icon: Icon(
              _selectedVoice == 'female' ? Icons.face : Icons.face_outlined,
              color: AppTheme.textPrimary,
            ),
            onSelected: (value) {
              setState(() {
                _selectedVoice = value;
                _setVoice();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'female',
                child: Row(
                  children: [
                    Icon(Icons.face, color: AppTheme.textPrimary),
                    SizedBox(width: 8),
                    Text('Female Voice'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'male',
                child: Row(
                  children: [
                    Icon(Icons.face_outlined, color: AppTheme.textPrimary),
                    SizedBox(width: 8),
                    Text('Male Voice'),
                  ],
                ),
              ),
            ],
          ),
          // Stop speaking button (when speaking)
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: AppTheme.accentRed),
              onPressed: _stopSpeaking,
              tooltip: 'Stop speaking',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.darkGradient,
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    // Loading indicator
                    return _buildLoadingMessage();
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            // CONVERSATION MODE INDICATOR
            if (_isInConversation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isListening 
                      ? AppTheme.primaryPurple.withOpacity(0.15)
                      : (_isSpeaking 
                          ? Colors.green.withOpacity(0.15)
                          : AppTheme.darkSurfaceVariant),
                  border: Border(
                    top: BorderSide(
                      color: _isListening 
                          ? AppTheme.primaryPurple.withOpacity(0.3)
                          : (_isSpeaking 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.transparent),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Status icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isListening 
                            ? AppTheme.primaryPurple 
                            : (_isSpeaking ? Colors.green : AppTheme.darkSurfaceVariant),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _isListening 
                            ? Icons.mic 
                            : (_isSpeaking ? Icons.volume_up : Icons.hourglass_empty),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening 
                                ? 'Listening...'
                                : (_isSpeaking 
                                    ? 'Owen is speaking...'
                                    : (_isLoading ? 'Thinking...' : 'Waiting...')),
                            style: TextStyle(
                              color: _isListening 
                                  ? AppTheme.primaryPurple 
                                  : (_isSpeaking ? Colors.green : AppTheme.textSecondary),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isListening 
                                ? (_recognizedText.isEmpty ? 'Say something...' : _recognizedText)
                                : 'Conversation active',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Input area with START/END CONVERSATION
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isInConversation
                      ? // IN CONVERSATION MODE - Show End button
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _endConversation,
                                icon: const Icon(Icons.stop_circle, color: Colors.white),
                                label: const Text(
                                  'End Conversation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentRed,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : // NOT IN CONVERSATION - Show Start button and text input
                        Row(
                    children: [
                      // START CONVERSATION BUTTON
                      GestureDetector(
                        onTap: _startConversation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.purpleGradient,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Type or tap Start to speak...',
                            hintStyle: const TextStyle(color: AppTheme.textTertiary),
                            filled: true,
                            fillColor: AppTheme.darkSurfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.purpleGradient,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ), // End of text input Row
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.purpleGradient,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.primaryPurple
                        : AppTheme.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                // Play button for bot messages
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up : Icons.volume_down,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        if (_isSpeaking) {
                          _stopSpeaking();
                        } else {
                          _speak(message.text);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.purpleGradient,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Owen is typing...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
