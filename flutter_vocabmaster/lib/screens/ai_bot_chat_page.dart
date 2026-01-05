import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import '../widgets/animated_background.dart';
import '../services/chatbot_service.dart';
import '../services/piper_tts_service.dart';

class AIBotChatPage extends StatefulWidget {
  const AIBotChatPage({Key? key}) : super(key: key);

  @override
  State<AIBotChatPage> createState() => _AIBotChatPageState();
}

class _AIBotChatPageState extends State<AIBotChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  final PiperTtsService _ttsService = PiperTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isTyping = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;
  bool _ttsAvailable = false;
  
  // Floating particles animation
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _checkTtsAvailability();
    
    // Add initial bot message
    _addBotMessage(
      'Merhaba! Ben yapay zeka asistanınım 👋 Seninle İngilizce pratik yapmak için buradayım. Nasılsın bugün?',
    );
  }

  Future<void> _checkTtsAvailability() async {
    final available = await _ttsService.isAvailable();
    if (mounted) {
      setState(() => _ttsAvailable = available);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _particleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {bool speak = false}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: true,
        time: _getCurrentTime(),
      ));
    });
    _scrollToBottom();
    
    // TTS ile seslendir
    if (speak && _ttsEnabled && _ttsAvailable) {
      _speakText(text);
    }
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) return;
    
    setState(() => _isSpeaking = true);
    
    try {
      final audioData = await _ttsService.synthesize(text);
      if (audioData != null && mounted) {
        // Uint8List'i AudioSource'a çevir
        final dataSource = MyCustomSource(audioData);
        await _audioPlayer.setAudioSource(dataSource);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isBot: false,
        time: _getCurrentTime(),
      ));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();
    
    try {
      // Backend'den gerçek AI yanıtı al
      final response = await _chatbotService.chat(userMessage);
      
      if (mounted) {
        setState(() => _isTyping = false);
        _addBotMessage(response, speak: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _addBotMessage('Üzgünüm, bir hata oluştu: ${e.toString()}');
      }
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(isDark: true),
          
          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(),
                
                // Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], index);
                    },
                  ),
                ),
                
                // Input Area
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          
          // Bot Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0ea5e9).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Bot Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22c55e),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _ttsAvailable ? 'Online - Sesli cevap aktif' : 'Online - Ready to chat',
                      style: const TextStyle(
                        color: Color(0xFF0ea5e9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sound Toggle
          IconButton(
            onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
            icon: Icon(
              _ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: _ttsEnabled ? const Color(0xFF0ea5e9) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (message.isBot)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Bot',
                    style: TextStyle(
                      color: Color(0xFF0ea5e9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Speak button for bot messages
                  if (_ttsAvailable) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _speakText(message.text),
                      child: Icon(
                        _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up,
                        color: const Color(0xFF0ea5e9),
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: message.isBot
                  ? const LinearGradient(
                      colors: [Color(0xFF1e3a5f), Color(0xFF1e3a8a)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isBot ? 4 : 20),
                bottomRight: Radius.circular(message.isBot ? 20 : 4),
              ),
              border: message.isBot
                  ? Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.2))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: (message.isBot ? const Color(0xFF1e3a8a) : const Color(0xFF0ea5e9))
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a8a).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0ea5e9).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF0ea5e9).withOpacity(0.6 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a).withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Mic Button (placeholder for future voice input)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesli giriş yakında eklenecek!')),
                    );
                  },
                  icon: const Icon(Icons.mic, color: Colors.white70, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              
              // Text Input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type your message in English...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Send Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0ea5e9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bottom Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _ttsAvailable 
                    ? 'Sesli cevap için hoparlör açık' 
                    : 'Practice your English with AI Bot',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0ea5e9), Color(0xFF06b6d4)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final String time;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.time,
  });
}

// Custom audio source for just_audio
class MyCustomSource extends StreamAudioSource {
  final Uint8List _buffer;
  
  MyCustomSource(this._buffer);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}

// Particles Painter for floating animation
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  
  ParticlesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0ea5e9).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (0.1 + (i * 0.05) + animationValue * 0.1)) % size.width;
      final y = (size.height * (0.1 + (i * 0.04) + animationValue * 0.2)) % size.height;
      final radius = 1.0 + (i % 3);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
