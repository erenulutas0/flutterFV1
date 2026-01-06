import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/word.dart';
import '../models/sentence_practice.dart';
import 'local_database_service.dart';
import 'api_service.dart';

/// Offline/Online durumu yönetir ve senkronizasyon işlemlerini gerçekleştirir
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _isCheckingConnectivity = false; // Paralel kontrolleri engelle
  DateTime? _lastConnectivityCheck; // Son kontrol zamanı
  static const Duration _connectivityCacheDuration = Duration(seconds: 30); // 30 saniye cache
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast();

  /// Online durumu stream
  Stream<bool> get onlineStatus => _onlineStatusController.stream;
  
  /// Anlık online durumu
  bool get isOnline => _isOnline;

  /// Servisi başlat
  Future<void> initialize() async {
    // İlk durum kontrolü
    await _checkConnectivity(force: true);

    // Bağlantı değişikliklerini dinle
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      final hasNetwork = !result.contains(ConnectivityResult.none);
      
      // Ağ durumu değiştiyse kontrol et
      if (hasNetwork != _isOnline || !hasNetwork) {
        _isOnline = hasNetwork;
        _onlineStatusController.add(_isOnline);
        
        // Offline'dan online'a geçtiyse senkronize et
        if (!wasOnline && _isOnline) {
          print('📶 Bağlantı geri geldi, senkronizasyon başlatılıyor...');
          await syncWithServer();
        }
      }
    });
  }

  /// Bağlantı durumunu kontrol et (cache'li)
  Future<bool> _checkConnectivity({bool force = false}) async {
    // Eğer zaten kontrol yapılıyorsa bekle
    if (_isCheckingConnectivity) {
      return _isOnline;
    }
    
    // Cache süresi dolmadıysa mevcut durumu döndür
    if (!force && _lastConnectivityCheck != null) {
      final elapsed = DateTime.now().difference(_lastConnectivityCheck!);
      if (elapsed < _connectivityCacheDuration) {
        return _isOnline;
      }
    }
    
    _isCheckingConnectivity = true;
    
    try {
      final result = await _connectivity.checkConnectivity();
      final hasNetwork = !result.contains(ConnectivityResult.none);
      
      if (!hasNetwork) {
        _isOnline = false;
        _lastConnectivityCheck = DateTime.now();
        _onlineStatusController.add(_isOnline);
        _isCheckingConnectivity = false;
        return false;
      }
      
      // Gerçek internet erişimi kontrolü (sadece ağ varsa)
      try {
        final baseUrl = await AppConfig.apiBaseUrl;
        final response = await http.get(
          Uri.parse('$baseUrl/words'),
        ).timeout(const Duration(seconds: 5));
        
        _isOnline = response.statusCode == 200;
      } catch (e) {
        // API erişilemeyen durumda offline gibi davran ama sessizce
        _isOnline = false;
      }
      
      _lastConnectivityCheck = DateTime.now();
      _onlineStatusController.add(_isOnline);
      _isCheckingConnectivity = false;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      _lastConnectivityCheck = DateTime.now();
      _onlineStatusController.add(_isOnline);
      _isCheckingConnectivity = false;
      return false;
    }
  }

  /// Servisi durdur
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineStatusController.close();
  }

  // ==================== WORDS ====================

  /// Tüm kelimeleri getir (online ise sync, offline ise local)
  Future<List<Word>> getAllWords() async {
    await _checkConnectivity();
    
    print('📦 OfflineSyncService.getAllWords: isOnline = $_isOnline');
    
    if (_isOnline) {
      try {
        // Online: API'den al ve local'e kaydet
        print('📦 OfflineSyncService.getAllWords: Fetching from API...');
        final words = await _apiService.getAllWords();
        print('📦 OfflineSyncService.getAllWords: API returned ${words.length} words');
        
        if (words.isNotEmpty) {
          await _localDb.saveAllWords(words);
        }
        return words;
      } catch (e) {
        print('🔴 API hatası, local veriler kullanılıyor: $e');
        final localWords = await _localDb.getAllWords();
        print('📦 OfflineSyncService.getAllWords: Local DB returned ${localWords.length} words');
        return localWords;
      }
    } else {
      // Offline: Local veritabanından al
      print('📴 Offline mod: Local kelimeler yükleniyor');
      final localWords = await _localDb.getAllWords();
      print('📦 OfflineSyncService.getAllWords: Local DB returned ${localWords.length} words');
      return localWords;
    }
  }

  /// Kelime oluştur
  Future<Word?> createWord({
    required String english,
    required String turkish,
    required DateTime addedDate,
    String difficulty = 'easy',
  }) async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        // Online: API'ye gönder ve local'e kaydet
        final word = await _apiService.createWord(
          english: english,
          turkish: turkish,
          addedDate: addedDate,
          difficulty: difficulty,
        );
        await _localDb.saveWord(word);
        await _localDb.addXp(10); // XP ekle
        return word;
      } catch (e) {
        print('🔴 API hatası, offline kayıt yapılıyor: $e');
        // Fallback: Offline kaydet
        final localId = await _localDb.createWordOffline(
          english: english,
          turkish: turkish,
          addedDate: addedDate,
          difficulty: difficulty,
        );
        return Word(
          id: localId,
          englishWord: english,
          turkishMeaning: turkish,
          learnedDate: addedDate,
          difficulty: difficulty,
          sentences: [],
        );
      }
    } else {
      // Offline: Local veritabanına kaydet
      print('📴 Offline mod: Kelime lokal kaydediliyor');
      final localId = await _localDb.createWordOffline(
        english: english,
        turkish: turkish,
        addedDate: addedDate,
        difficulty: difficulty,
      );
      return Word(
        id: localId,
        englishWord: english,
        turkishMeaning: turkish,
        learnedDate: addedDate,
        difficulty: difficulty,
        sentences: [],
      );
    }
  }

  /// Kelime sil
  Future<bool> deleteWord(int wordId) async {
    await _checkConnectivity();

    if (_isOnline && wordId > 0) {
      try {
        await _apiService.deleteWord(wordId);
        await _localDb.deleteWord(wordId);
        return true;
      } catch (e) {
        print('🔴 API hatası, offline silme yapılıyor: $e');
        await _localDb.deleteWord(wordId);
        await _localDb.addToSyncQueue('delete', 'words', wordId.toString(), {});
        return true;
      }
    } else {
      // Offline
      await _localDb.deleteWord(wordId);
      await _localDb.addToSyncQueue('delete', 'words', wordId.toString(), {});
      return true;
    }
  }

  /// Kelimeye cümle ekle
  Future<Word?> addSentenceToWord({
    required int wordId,
    required String sentence,
    required String translation,
    String difficulty = 'easy',
  }) async {
    await _checkConnectivity();
    
    if (_isOnline && wordId > 0) {
      try {
        // Online: API'ye gönder
        final word = await _apiService.addSentenceToWord(
          wordId: wordId,
          sentence: sentence,
          translation: translation,
          difficulty: difficulty,
        );
        await _localDb.saveWord(word);
        await _localDb.addXp(5); // XP ekle
        return word;
      } catch (e) {
        print('🔴 API hatası, offline kayıt yapılıyor: $e');
        await _localDb.addSentenceToWordOffline(
          wordId: wordId,
          sentence: sentence,
          translation: translation,
          difficulty: difficulty,
        );
        return null;
      }
    } else {
      // Offline: Local veritabanına kaydet
      print('📴 Offline mod: Cümle lokal kaydediliyor');
      await _localDb.addSentenceToWordOffline(
        wordId: wordId,
        sentence: sentence,
        translation: translation,
        difficulty: difficulty,
      );
      return null;
    }
  }

  /// Kelimeden cümle sil
  Future<bool> deleteSentenceFromWord({
    required int wordId,
    required int sentenceId,
  }) async {
    await _checkConnectivity();
    
    if (_isOnline && wordId > 0 && sentenceId > 0) {
      try {
        // Online: API'den sil
        await _apiService.deleteSentenceFromWord(wordId, sentenceId);
        // Local'den de sil
        await _localDb.deleteSentenceFromWord(wordId, sentenceId);
        return true;
      } catch (e) {
        print('🔴 API hatası, offline silme yapılıyor: $e');
        await _localDb.deleteSentenceFromWord(wordId, sentenceId);
        await _localDb.addToSyncQueue('delete', 'sentences', sentenceId.toString(), {'wordId': wordId});
        return true;
      }
    } else {
      // Offline: Local veritabanından sil ve sync queue'ya ekle
      print('📴 Offline mod: Cümle lokal siliniyor');
      await _localDb.deleteSentenceFromWord(wordId, sentenceId);
      await _localDb.addToSyncQueue('delete', 'sentences', sentenceId.toString(), {'wordId': wordId});
      return true;
    }
  }

  // ==================== PRACTICE SENTENCES ====================

  /// Tüm practice sentences getir
  Future<List<SentencePractice>> getAllSentences() async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final sentences = await _apiService.getAllSentences();
        if (sentences.isNotEmpty) {
          await _localDb.saveAllPracticeSentences(sentences);
        }
        return sentences;
      } catch (e) {
        print('🔴 API hatası, local veriler kullanılıyor: $e');
        return await _localDb.getAllPracticeSentences();
      }
    } else {
      print('📴 Offline mod: Local cümleler yükleniyor');
      return await _localDb.getAllPracticeSentences();
    }
  }

  /// Practice sentence oluştur
  Future<SentencePractice?> createSentence({
    required String englishSentence,
    required String turkishTranslation,
    required String difficulty,
  }) async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final sentence = await _apiService.createSentence(
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty,
        );
        await _localDb.savePracticeSentence(sentence);
        await _localDb.addXp(5); // XP ekle
        return sentence;
      } catch (e) {
        print('🔴 API hatası, offline kayıt yapılıyor: $e');
        final id = await _localDb.createPracticeSentenceOffline(
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty,
        );
        return SentencePractice(
          id: id,
          englishSentence: englishSentence,
          turkishTranslation: turkishTranslation,
          difficulty: difficulty.toUpperCase(),
          createdDate: DateTime.now(),
          source: 'practice',
        );
      }
    } else {
      print('📴 Offline mod: Cümle lokal kaydediliyor');
      final id = await _localDb.createPracticeSentenceOffline(
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty,
      );
      return SentencePractice(
        id: id,
        englishSentence: englishSentence,
        turkishTranslation: turkishTranslation,
        difficulty: difficulty.toUpperCase(),
        createdDate: DateTime.now(),
        source: 'practice',
      );
    }
  }

  /// Practice sentence sil
  Future<void> deletePracticeSentence(String id) async {
    await _checkConnectivity();

    // Sadece server ID'leri için API çağrısı yap (temp/local değilse)
    bool isServerId = !id.startsWith('temp_') && !id.startsWith('local_');

    if (_isOnline) {
      if (isServerId) {
        try {
          // 'practice_' prefix'ini kaldır
          final apiId = id.replaceFirst('practice_', '');
          await _apiService.deleteSentence(apiId);
        } catch (e) {
          print('🔴 API hatası, offline silme kuyruğa ekleniyor: $e');
          await _localDb.addToSyncQueue('delete', 'practice_sentences', id, {});
        }
      }
      // Local DB'den her durumda sil
      await _localDb.deletePracticeSentence(id);
    } else {
      await _localDb.deletePracticeSentence(id);
      if (isServerId) {
        await _localDb.addToSyncQueue('delete', 'practice_sentences', id, {});
      }
    }
  }

  // ==================== DATES ====================

  /// Benzersiz tarihleri getir
  Future<List<String>> getAllDistinctDates() async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        return await _apiService.getAllDistinctDates();
      } catch (e) {
        return await _localDb.getAllDistinctDates();
      }
    } else {
      return await _localDb.getAllDistinctDates();
    }
  }

  /// Tarihe göre kelimeleri getir
  Future<List<Word>> getWordsByDate(DateTime date) async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        final words = await _apiService.getWordsByDate(date);
        return words;
      } catch (e) {
        return await _localDb.getWordsByDate(date);
      }
    } else {
      return await _localDb.getWordsByDate(date);
    }
  }

  // ==================== XP ====================

  /// Toplam XP getir (local + pending)
  Future<int> getTotalXp() async {
    return await _localDb.getTotalXp();
  }

  /// Pending XP getir
  Future<int> getPendingXp() async {
    return await _localDb.getPendingXp();
  }

  // ==================== SYNC ====================

  /// Sunucu ile senkronize et
  Future<bool> syncWithServer() async {
    if (_isSyncing) {
      print('⏳ Senkronizasyon zaten devam ediyor...');
      return false;
    }

    if (!_isOnline) {
      print('📴 Offline - senkronizasyon atlanıyor');
      return false;
    }

    _isSyncing = true;
    print('🔄 Senkronizasyon başlatıldı...');

    try {
      // 1. Bekleyen işlemleri gönder
      final pendingItems = await _localDb.getPendingSyncItems();
      print('📝 ${pendingItems.length} bekleyen işlem bulundu');

      for (var item in pendingItems) {
        try {
          await _processSyncItem(item);
          await _localDb.markSyncItemCompleted(item['id'] as int);
        } catch (e) {
          print('🔴 Sync item hatası: $e');
          // Hatalı item'ları atla, sonra tekrar dene
        }
      }

      // 2. Sunucudan güncel verileri al
      final serverWords = await _apiService.getAllWords();
      if (serverWords.isNotEmpty) {
        await _localDb.saveAllWords(serverWords);
      }

      final serverSentences = await _apiService.getAllSentences();
      if (serverSentences.isNotEmpty) {
        await _localDb.saveAllPracticeSentences(serverSentences);
      }

      // 3. XP'yi senkronize et (server XP + pending XP)
      // Not: Gerçek uygulamada server'dan XP almak gerekir
      // Şimdilik local XP'yi koruyoruz
      await _localDb.markXpSynced();

      print('✅ Senkronizasyon tamamlandı');
      _isSyncing = false;
      return true;
    } catch (e) {
      print('🔴 Senkronizasyon hatası: $e');
      _isSyncing = false;
      return false;
    }
  }

  /// Tek bir sync item'ı işle
  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final tableName = item['tableName'] as String;
    var itemId = item['itemId'] as String; // Var because we might use it as int
    final dataStr = item['data'] as String;
    
    Map<String, dynamic> data = {};
    try {
      if (dataStr.isNotEmpty) {
        data = jsonDecode(dataStr);
      }
    } catch (e) {
      print('JSON decode warning: $e');
    }

    if (tableName == 'words') {
      if (action == 'create') {
        final localId = int.tryParse(itemId) ?? 0;
        final localWords = await _localDb.getAllWords();
        final localWord = localWords.firstWhere(
          (w) => w.id == localId,
          orElse: () => Word(id: 0, englishWord: '', turkishMeaning: '', learnedDate: DateTime.now(), difficulty: 'easy', sentences: []),
        );

        if (localWord.id != 0 && localWord.englishWord.isNotEmpty) {
          final serverWord = await _apiService.createWord(
            english: localWord.englishWord,
            turkish: localWord.turkishMeaning,
            addedDate: localWord.learnedDate,
            difficulty: localWord.difficulty,
          );
          
          await _localDb.updateLocalIdToServerId('words', localId, serverWord.id);
        }
      } else if (action == 'delete') {
         final id = int.tryParse(itemId) ?? 0;
         if (id > 0) {
            await _apiService.deleteWord(id);
         }
      }
    } else if (tableName == 'sentences') {
      if (action == 'create') {
        final localId = int.tryParse(itemId) ?? 0;
        // DB'den güncel veriyi al (wordId güncellenmiş olabilir)
        // Sentences tablosunda id veya localId ile bul
        final db = await _localDb.database;
        final results = await db.query('sentences', where: 'localId = ?', whereArgs: [localId]);
        
        if (results.isNotEmpty) {
          final sFunc = results.first;
          final wordId = sFunc['wordId'] as int? ?? 0;
          final sentence = sFunc['sentence'] as String;
          final translation = sFunc['translation'] as String;
          final difficulty = sFunc['difficulty'] as String;
          
          if (wordId > 0) {
             final serverWord = await _apiService.addSentenceToWord(
               wordId: wordId,
               sentence: sentence,
               translation: translation,
               difficulty: difficulty,
             );
             
             // Server'dan dönen kelimenin içinden cümleyi bulup ID'sini almamız lazım
             // Ama addSentenceToWord Word dönüyor.
             // En son eklenen cümle mi?
             // Basitleştirme: Server ID'si olmadan updateLocalIdToServerId çağıramayız doğru düzgün.
             // API addSentenceToWord yeni cümleyi döndürseydi iyiydi.
             // Word dönüyor. Word'ün cümlelerinde bizim cümleyi bulacağız.
             if (serverWord != null && serverWord.sentences.isNotEmpty) {
               // Eşleşen cümleyi bul
               final serverSentenceList = serverWord.sentences.where(
                 (s) => s.sentence == sentence && s.translation == translation
               ).toList();
               
               if (serverSentenceList.isNotEmpty) {
                 // En sonuncuyu al (varsayım)
                 final serverSentence = serverSentenceList.last;
                 await _localDb.updateLocalIdToServerId('sentences', localId, serverSentence.id);
               }
             }
          }
        }
      } else if (action == 'delete') {
         int sentenceId = int.tryParse(itemId) ?? 0;
         int wordId = data['wordId'] is int ? data['wordId'] : int.tryParse(data['wordId'].toString()) ?? 0;
         
         // wordId negatifse (offline oluşturulmuşsa), words tablosundan güncel ID'yi bul
         if (wordId < 0) {
           final db = await _localDb.database;
           final results = await db.query('words', columns: ['id'], where: 'localId = ?', whereArgs: [wordId]);
           if (results.isNotEmpty) {
             wordId = results.first['id'] as int;
           }
         }
         
         // Eğer wordId ve sentenceId pozitif ise sil
         if (wordId > 0 && sentenceId > 0) {
           await _apiService.deleteSentenceFromWord(wordId, sentenceId);
         }
      }
    } else if (tableName == 'practice_sentences') {
      if (action == 'create') {
        final localSentences = await _localDb.getAllPracticeSentences();
        final localSentence = localSentences.firstWhere(
          (s) => s.id == itemId,
          orElse: () => SentencePractice(id: '', englishSentence: '', turkishTranslation: '', difficulty: 'EASY', createdDate: DateTime.now(), source: 'practice'),
        );

        if (localSentence.id.isNotEmpty && localSentence.englishSentence.isNotEmpty) {
          final serverSentence = await _apiService.createSentence(
            englishSentence: localSentence.englishSentence,
            turkishTranslation: localSentence.turkishTranslation,
            difficulty: localSentence.difficulty,
          );
          
          // Delete local temporary ID and save server sentence
          await _localDb.deletePracticeSentence(itemId);
          await _localDb.savePracticeSentence(serverSentence);
        }
      } else if (action == 'delete') {
         // Local veya temp ID değilse sil
         if (!itemId.startsWith('local_') && !itemId.startsWith('temp_')) {
             final apiId = itemId.replaceFirst('practice_', '');
             await _apiService.deleteSentence(apiId);
         }
      }
    }
  }

  /// İlk veri yüklemesi (uygulama başlangıcında)
  Future<void> initialDataLoad() async {
    await _checkConnectivity();
    
    if (_isOnline) {
      try {
        // Online: Sunucudan al ve local'e kaydet
        final words = await _apiService.getAllWords();
        if (words.isNotEmpty) {
          await _localDb.saveAllWords(words);
        }

        final sentences = await _apiService.getAllSentences();
        if (sentences.isNotEmpty) {
          await _localDb.saveAllPracticeSentences(sentences);
        }

        print('✅ İlk veri yüklemesi tamamlandı: ${words.length} kelime, ${sentences.length} cümle');
      } catch (e) {
        print('🔴 İlk veri yüklemesi hatası: $e');
      }
    }
  }
}
