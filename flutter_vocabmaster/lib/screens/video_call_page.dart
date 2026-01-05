
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoCallPage extends StatefulWidget {
  final IO.Socket socket;
  final String roomId;
  final String matchedUserId;
  final String? role; // 'caller' or 'callee'
  final String currentUserId;

  const VideoCallPage({
    super.key,
    required this.socket,
    required this.roomId,
    required this.matchedUserId,
    required this.currentUserId,
    this.role,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isRemoteVideoReady = false;
  String _connectionState = 'Başlatılıyor...';
  
  // Debug Logs
  bool _showLogs = true; // Varsayılan açık olsun ki kullanıcı görsün
  final List<String> _logs = [];

  // WebRTC Variables
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isLocalRendererInitialized = false;
  
  // Candidate Queue
  final List<RTCIceCandidate> _candidateQueue = [];
  bool _isRemoteDescriptionSet = false;

  void _log(String message) {
    debugPrint(message);
    if (!mounted) return;
    // UI güncellemesini çok sık yapmamak için microtask veya postFrameCallback kullanılabilir
    // Ancak basitlik için doğrudan setState, ama liste boyutu küçük:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _logs.insert(0, "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $message");
          if (_logs.length > 10) _logs.removeLast();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WakelockPlus.enable();
    }
    _log("Initilizing... Role: ${widget.role}");
    _initializeWebRTC();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _initializeWebRTC() async {
    try {
      _log("Requesting permissions...");
      await _requestPermissions();
      
      try {
        _log("Initializing renderers...");
        await _localRenderer.initialize();
        await _remoteRenderer.initialize();
        if (mounted) setState(() => _isLocalRendererInitialized = true);
      } catch (e) {
        _log("Renderer Error: $e");
      }

      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          // OpenRelay TURN
          {'urls': 'turn:openrelay.metered.ca:80', 'username': 'openrelayproject', 'credential': 'openrelayproject'},
          {'urls': 'turn:openrelay.metered.ca:443', 'username': 'openrelayproject', 'credential': 'openrelayproject'},
          {'urls': 'turn:openrelay.metered.ca:443?transport=tcp', 'username': 'openrelayproject', 'credential': 'openrelayproject'},
        ],
        'sdpSemantics': 'unified-plan',
        'iceTransportPolicy': 'all', 
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      };
      
      final Map<String, dynamic> offerOptions = {
        'mandatory': {},
        'optional': [
           {'DtlsSrtpKeyAgreement': true},
        ],
      };

      _log("Creating PeerConnection...");
      _peerConnection = await createPeerConnection(configuration, offerOptions);

      final Map<String, dynamic> constraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 24},
        },
      };

      try {
        _log("Getting User Media...");
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
        if (mounted) setState(() => _localRenderer.srcObject = _localStream);
      } catch (e) {
        _log("Media Stream Error: $e");
      }

      _peerConnection!.onTrack = (event) {
        if (event.streams.isEmpty) return;
        _log("WebRTC: onTrack stream id: ${event.streams[0].id}");
        if (mounted) {
           setState(() {
             _remoteStream = event.streams[0];
             _remoteRenderer.srcObject = _remoteStream;
             _isRemoteVideoReady = true;
           });
        }
      };
      
      _peerConnection!.onAddStream = (MediaStream stream) {
        _log("WebRTC: onAddStream id: ${stream.id}");
        if (mounted) {
           setState(() {
             _remoteStream = stream;
             _remoteRenderer.srcObject = _remoteStream;
             _isRemoteVideoReady = true;
           });
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          // _log("Sending ICE Candidate"); // Çok kirletmesin diye kapalı
          widget.socket.emit('webrtc_ice_candidate', {
             'roomId': widget.roomId,
             'candidate': candidate.candidate,
             'sdpMLineIndex': candidate.sdpMLineIndex,
             'sdpMid': candidate.sdpMid,
          });
        }
      };
      
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        _log("WebRTC State: $state");
        if (mounted) {
           setState(() {
              if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) _connectionState = 'Bağlandı';
              else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) _connectionState = 'Bağlantı Hatası';
              else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) _connectionState = 'Sonlandı';
              else _connectionState = 'Durum: ${state.toString().split('.').last}';
           });
        }
      };
      
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        _log("ICE State: $state");
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
           if (mounted) setState(() => _connectionState = 'Bağlantı Kuruldu (ICE)');
        }
      };

      _setupSocketListeners();
      
      // Odaya katıl
      _log("Joining Room: ${widget.roomId}");
      widget.socket.emit('join_room', {'roomId': widget.roomId});

      final role = widget.role ?? 'caller';
      if (role == 'caller') {
        _log("I am Caller. Waiting 1s...");
        await Future.delayed(const Duration(seconds: 1));
        await _createOffer();
      } else {
        _log("I am Callee. Waiting for offer...");
        _connectionState = "Teklif Bekleniyor...";
      }

    } catch (e) {
      _log("Init Error: $e");
      if (mounted) setState(() => _connectionState = 'Kritik Hata: $e');
    }
  }

  void _setupSocketListeners() {
    widget.socket.on('webrtc_offer', (data) async {
       if (data['from'] == widget.currentUserId) return;
       _log("Offer Received from ${data['from']}");
       
       if (widget.role != 'caller') { 
           try {
             var offer = data['offer'];
             await _peerConnection!.setRemoteDescription(
               RTCSessionDescription(offer['sdp'], offer['type'])
             );
             _log("Remote Description Set (Offer)");
             _isRemoteDescriptionSet = true;
             _processCandidateQueue();
             await _createAnswer();
           } catch (e) {
             _log("Offer Error: $e");
           }
       } else {
         _log("Ignored Offer (I am Caller)");
       }
    });

    widget.socket.on('webrtc_answer', (data) async {
       if (data['from'] == widget.currentUserId) return;
       _log("Answer Received from ${data['from']}");

       if (widget.role == 'caller') {
           try {
             var answer = data['answer'];
             await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(answer['sdp'], answer['type'])
             );
             _log("Remote Description Set (Answer)");
             _isRemoteDescriptionSet = true;
             _processCandidateQueue();
           } catch (e) {
             _log("Answer Error: $e");
           }
       } else {
         _log("Ignored Answer (I am Callee)");
       }
    });

    widget.socket.on('webrtc_ice_candidate', (data) async {
       if (data['candidate'] != null) {
         if (data['from'] == widget.currentUserId) return; // Kendi candidate'imizi loglama
         
         // Defansif Kodlama: Null gelirse varsayılan değer ata
         String sdpMid = data['sdpMid'] ?? "";
         int sdpMLineIndex = data['sdpMLineIndex'] ?? 0;
         
         // _log("Candidate recv from ${data['from']}"); // Çok log olmasın
         var candidate = RTCIceCandidate(
              data['candidate'], 
              sdpMid, 
              sdpMLineIndex
         );
         
         if (_isRemoteDescriptionSet) {
            try {
              await _peerConnection!.addCandidate(candidate);
            } catch (e) {
              _log("Add Cand Error: $e");
            }
         } else {
            _candidateQueue.add(candidate);
            _log("Queued Candidate (Total: ${_candidateQueue.length})");
         }
       }
    });
    
    widget.socket.on('call_ended', (_) {
        _log("Call Ended signal received");
        _endCall(remote: true);
    });
  }
  
  void _processCandidateQueue() async {
    _log("Processing ${_candidateQueue.length} queued candidates");
    if (!mounted) return;
    for (var candidate in _candidateQueue) {
       await _peerConnection!.addCandidate(candidate);
    }
    _candidateQueue.clear();
  }

  Future<void> _createOffer() async {
    try {
      _log("Creating Offer...");
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });
      await _peerConnection!.setLocalDescription(offer);
      _log("Local Description Set (Offer)");
      
      widget.socket.emit('webrtc_offer', {
        'roomId': widget.roomId,
        'offer': {'sdp': offer.sdp, 'type': offer.type},
      });
      _log("Offer Sent");
    } catch (e) {
      _log("Create Offer Error: $e");
    }
  }

  Future<void> _createAnswer() async {
    try {
      _log("Creating Answer...");
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveVideo': 1,
        'offerToReceiveAudio': 1,
      });
      await _peerConnection!.setLocalDescription(answer);
      _log("Local Description Set (Answer)");
      
      widget.socket.emit('webrtc_answer', {
        'roomId': widget.roomId,
        'answer': {'sdp': answer.sdp, 'type': answer.type},
      });
      _log("Answer Sent");
    } catch (e) {
      _log("Create Answer Error: $e");
    }
  }

  void _toggleMic() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
      _localStream?.getAudioTracks().forEach((track) => track.enabled = _isAudioEnabled);
    });
  }

  void _toggleCam() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
      _localStream?.getVideoTracks().forEach((track) => track.enabled = _isVideoEnabled);
    });
  }

  void _endCall({bool remote = false}) {
     if (!remote) {
        widget.socket.emit('end_call', {'roomId': widget.roomId});
     }
     
     _peerConnection?.close();
     _localStream?.dispose();
     _localRenderer.dispose();
     _remoteRenderer.dispose();
     
     if (!kIsWeb) WakelockPlus.disable();
     
     widget.socket.off('webrtc_offer');
     widget.socket.off('webrtc_answer');
     widget.socket.off('webrtc_ice_candidate');
     widget.socket.off('call_ended');
     
     if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    if (!kIsWeb) WakelockPlus.disable();
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    
    widget.socket.off('webrtc_offer');
    widget.socket.off('webrtc_answer');
    widget.socket.off('webrtc_ice_candidate');
    widget.socket.off('call_ended');
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
              child: _isRemoteVideoReady && _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer, 
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ) 
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(_connectionState, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
          ),
          
          Positioned(
            right: 20,
            top: 50,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                 border: Border.all(color: Colors.white, width: 2),
                 borderRadius: BorderRadius.circular(10),
                 color: Colors.black54,
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isLocalRendererInitialized 
                     ? RTCVideoView(
                         _localRenderer, 
                         mirror: true, 
                         objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                       )
                     : const Center(child: Icon(Icons.videocam_off, color: Colors.white)),
              ),
            ),
          ),
          
          if (_showLogs)
          Positioned(
            left: 20,
            top: 220, // Altında local video var
            right: 20,
            bottom: 120, // Kontroller için boşluk
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("Debug Logs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       IconButton( icon: const Icon(Icons.close, color: Colors.white, size: 16), onPressed: () => setState(() => _showLogs = false)),
                     ]
                   ),
                   Expanded(
                     child: ListView.builder(
                       itemCount: _logs.length,
                       itemBuilder: (context, index) => Text(
                         _logs[index], 
                         style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Courier')
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          Positioned(
             bottom: 40,
             left: 0,
             right: 0,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 FloatingActionButton(
                   heroTag: 'logs',
                   mini: true,
                   backgroundColor: Colors.grey,
                   onPressed: () => setState(() => _showLogs = !_showLogs),
                   child: const Icon(Icons.bug_report, color: Colors.white),
                 ),
                 FloatingActionButton(
                   heroTag: 'mic',
                   backgroundColor: _isAudioEnabled ? Colors.white : Colors.red,
                   onPressed: _toggleMic,
                   child: Icon(_isAudioEnabled ? Icons.mic : Icons.mic_off, color: Colors.black),
                 ),
                 FloatingActionButton(
                   heroTag: 'end',
                   backgroundColor: Colors.red,
                   onPressed: () => _endCall(),
                   child: const Icon(Icons.call_end, color: Colors.white),
                 ),
                 FloatingActionButton(
                   heroTag: 'cam',
                   backgroundColor: _isVideoEnabled ? Colors.white : Colors.red,
                   onPressed: _toggleCam,
                   child: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off, color: Colors.black),
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }
}
