import 'package:flutter/foundation.dart';
import 'dart:async'; // Completer için gerekli
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

/// Eşleşme durumu
enum MatchStatus {
  idle,
  searching,
  matched,
  inCall,
  error,
}

/// Eşleşme bilgisi
class MatchInfo {
  final String roomId;
  final String matchedUserId;
  final String role; // 'caller' or 'callee'

  MatchInfo({
    required this.roomId,
    required this.matchedUserId,
    required this.role,
  });
}

/// Socket.IO ile eşleşme servisi
class MatchmakingService extends ChangeNotifier {
  IO.Socket? _socket;
  MatchStatus _status = MatchStatus.idle;
  MatchInfo? _matchInfo;
  String? _userId;
  int _queueSize = 0;
  String? _errorMessage;
  
  // Socket.IO port (backend'de 9092 olarak tanımlı)
  static const int _socketPort = 9092;

  MatchStatus get status => _status;
  MatchInfo? get matchInfo => _matchInfo;
  int get queueSize => _queueSize;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;
  String? get userId => _userId;

  // Connection lock için
  Completer<void>? _connectionCompleter;

  /// Socket.IO'ya bağlan (Bağlantı kurulana kadar bekler)
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('MatchmakingService: Already connected');
      return;
    }

    // Eğer zaten bağlanmaya çalışıyorsa, o işlemi bekle
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      debugPrint('MatchmakingService: Already connecting, waiting...');
      return _connectionCompleter!.future;
    }

    _connectionCompleter = Completer<void>();

    try {
      final baseUrl = await AppConfig.baseUrl;
      final socketUrl = baseUrl.replaceFirst(RegExp(r':\d+'), ':$_socketPort');
      
      debugPrint('MatchmakingService: Connecting to $socketUrl');

      // Socket yoksa oluştur
      if (_socket == null) {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 99,
        'timeout': 20000, // 20 saniye socket timeout
      });

      _setupEventListeners(); // Listener'ları bir kez ekle
      } else {
         // Varsa sadece connect de
      }

      // Bağlantı başarılı olduğunda completer'ı tamamla
      _socket!.once('connect', (_) {
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
           _connectionCompleter!.complete();
        }
      });
      
      // Hata durumunda da tamamla (Hata fırlatmak yerine)
      _socket!.once('connect_error', (err) {
         debugPrint('MatchmakingService: Connect Error via once: $err');
         if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
           // _connectionCompleter!.completeError(err); // Hata fırlatma, logla
           _connectionCompleter!.complete(); 
         }
      });

      _socket!.connect();
      
      // Timeout koruması (15 saniye)
      return _connectionCompleter!.future.timeout(const Duration(seconds: 15), onTimeout: () {
         debugPrint('MatchmakingService: Connection timed out');
         _status = MatchStatus.error;
         _errorMessage = 'Bağlantı zaman aşımı. Sunucuya ulaşılamıyor.';
         notifyListeners();
      });

    } catch (e) {
      debugPrint('MatchmakingService: Connection exception: $e');
      _status = MatchStatus.error;
      _errorMessage = 'Bağlantı hatası: $e';
      notifyListeners();
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    }
  }

  // Listener kurulumunu ayrı tutuyoruz, connect içinde çağrılıyor ama socket null check var
  void _setupEventListeners() {
    if (_socket == null) return;
    
    // Eski listenerları temizle, duplicate olmasın
    _socket!.clearListeners();

    _socket!.onConnect((_) {
      debugPrint('MatchmakingService: Connected');
      _status = MatchStatus.idle;
      _errorMessage = null;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('MatchmakingService: Disconnected');
      _status = MatchStatus.idle;
      _matchInfo = null;
      notifyListeners();
    });

    _socket!.onConnectError((data) {
      debugPrint('MatchmakingService: Connect error: $data');
      // Her hatada UI'ı hemen bozmayalım, reconnect deneyecek
      // _status = MatchStatus.error; 
      // _errorMessage = 'Bağlantı hatası. Tekrar bağlanılıyor...';
      // notifyListeners();
    });

    // Kuyruk durumu
    _socket!.on('queue_status', (data) {
      debugPrint('MatchmakingService: Queue status: $data');
      _status = MatchStatus.searching;
      _queueSize = data['queueSize'] ?? 0;
      notifyListeners();
    });

    // Eşleşme bulundu
    _socket!.on('match_found', (data) {
      debugPrint('MatchmakingService: Match found: $data');
      _status = MatchStatus.matched;
      _matchInfo = MatchInfo(
        roomId: data['roomId'],
        matchedUserId: data['matchedUserId'],
        role: data['role'],
      );
      notifyListeners();
    });

    // Görüşme sonlandı
    _socket!.on('call_ended', (_) {
      debugPrint('MatchmakingService: Call ended');
      leftCall();
    });
    
    // WebRTC sinyalleri VideoCallPage tarafından dinlenecek
    // _socket!.on('webrtc_offer', ...); // Kaldırıldı
  }

  /// Eşleşme kuyruğuna katıl
  Future<void> joinQueue({String? userId}) async {
    // Bağlantı yoksa önce bağlanmayı dene
    if (_socket == null || !_socket!.connected) {
      debugPrint('MatchmakingService: Socket not connected, attempting to connect...');
      await connect();
      
      // Hala bağlı değilse iptal et
      if (_socket == null || !_socket!.connected) {
         debugPrint('MatchmakingService: Failed to connect, cannot join queue.');
         _status = MatchStatus.error;
         _errorMessage = 'Sunucuya bağlanılamadı.';
         notifyListeners();
         return;
      }
    }

    _userId = userId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _status = MatchStatus.searching;
    notifyListeners();

    _socket!.emit('join_queue', {'userId': _userId});
    debugPrint('MatchmakingService: Joined queue with userId: $_userId');
  }

  /// Kuyruktan ayrıl
  void leaveQueue() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_queue', _userId);
    }
    _status = MatchStatus.idle;
    notifyListeners();
  }

  /// Odaya katıl
  void joinRoom(String roomId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_room', {'roomId': roomId});
      _status = MatchStatus.inCall;
      notifyListeners();
    }
  }

  /// WebRTC offer gönder
  void sendOffer(String roomId, Map<String, dynamic> offer) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('webrtc_offer', {
        'roomId': roomId,
        'offer': offer,
      });
    }
  }

  /// WebRTC answer gönder
  void sendAnswer(String roomId, Map<String, dynamic> answer) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('webrtc_answer', {
        'roomId': roomId,
        'answer': answer,
      });
    }
  }

  /// ICE candidate gönder
  void sendIceCandidate(String roomId, Map<String, dynamic> candidate) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('webrtc_ice_candidate', {
        'roomId': roomId,
        'candidate': candidate,
      });
    }
  }

  /// Görüşmeyi sonlandır
  void endCall() {
    if (_socket != null && _socket!.connected && _matchInfo != null) {
      _socket!.emit('end_call', {'roomId': _matchInfo!.roomId});
    }
    _status = MatchStatus.idle;
    _matchInfo = null;
    notifyListeners();
  }

  /// Bağlantıyı kes
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _status = MatchStatus.idle;
    _matchInfo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // UI Helper methods
  void setInCall() {
    _status = MatchStatus.inCall;
    notifyListeners();
  }
  
  void leftCall() {
     _status = MatchStatus.idle;
     _matchInfo = null;
     // Socket'i kapatma, belki yeniden arama yapar
     notifyListeners();
  }

  /// Socket event listener ekle (WebRTC için)
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }
}
