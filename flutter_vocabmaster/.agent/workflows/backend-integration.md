---
description: Backend entegrasyonu için görev planı - flutter_vocabmaster UI'ı ile backend bağlantısı
---

# Backend Entegrasyon Görev Planı

flutter_vocabmaster uygulamasını backend ile entegre etme planı. flutter_app'de çalışan özellikleri yeni UI'a taşıyoruz.

## ✅ Mevcut Durum
- Backend: Java Spring Boot (port 8080 + Socket.IO port 9092)
- flutter_app: Zengin servis katmanı (api_service, groq_service, piper_tts_service, vs.)
- flutter_vocabmaster: Temel entegrasyon tamamlandı ✅

## 📋 Görev Listesi

### Task 1: Temel Servis Altyapısı ✅ TAMAMLANDI
- [x] GroqService oluşturuldu (kelime anlamı, cümle üretme, okuma pasajı)
- [x] PiperTtsService oluşturuldu (AI bot sesli cevap)
- [x] ChatbotService oluşturuldu (backend controller bağlantısı)
- [x] MatchmakingService oluşturuldu (Socket.IO altyapısı)
- [x] ApiService genişletildi (kelime/cümle CRUD)
- [x] SentencePractice modeli kopyalandı
- [x] Gerekli paketler eklendi (socket_io_client, audioplayers, just_audio)

### Task 2: Sözlük (Dictionary) Entegrasyonu ✅ TAMAMLANDI
- [x] DictionaryPage Groq API ile entegre edildi
- [x] Kelime arama -> AI ile zengin anlam getirme
- [x] Çoklu anlam seçimi ve kaydetme
- [x] TTS ile kelime telaffuzu

### Task 3: Çevirme Pratiği (Translation Practice) ✅ TAMAMLANDI
- [x] TranslationPracticePage oluşturuldu
- [x] Kelime seçimi -> ChatbotService.generateSentences
- [x] Çeviri kontrolü -> ChatbotService.checkTranslation
- [x] EN->TR, TR->EN ve Karışık mod desteği
- [x] PracticePage'e yönlendirme eklendi

### Task 4: Eşleşme Sistemi (Matchmaking) ⏳ ALTYAPI HAZIR
- [x] Socket.IO bağlantı servisi (MatchmakingService)
- [x] WebRTC sinyal desteği (offer/answer/ice)
- [ ] Sesli sohbet UI (flutter_webrtc widget'ları)
- [ ] Eşleşme UI akışı (bekleme, eşleşme bulundu, görüşme)

### Task 5: AI Bot Sohbet (Yapay Zeka Botu) ✅ TAMAMLANDI
- [x] AIBotChatPage backend ChatbotService.chat ile entegre
- [x] Piper TTS ile sesli cevap
- [x] Gerçek AI yanıtları
- [x] TTS açma/kapama toggle

### Task 6: Sınav Hazırlığı (IELTS/TOEFL) ✅ TAMAMLANDI
- [x] ExamChatPage backend ile entegre
- [x] Speaking test questions (generateSpeakingTestQuestions)
- [x] Speaking test evaluation (evaluateSpeakingTest)
- [x] Part geçişleri (Part 1, 2, 3)
- [x] TTS desteği

### Task 7: Okuma Pratiği (Reading) ✅ TAMAMLANDI
- [x] ReadingPracticePage oluşturuldu
- [x] GroqService.generateReadingPassage entegrasyonu
- [x] Dinamik sorular ve cevap kontrolü
- [x] Açıklama ve kaynak gösterimi
- [x] PracticePage'e yönlendirme eklendi

---

## 📊 Özet

| Görev | Durum |
|-------|-------|
| Task 1: Servis Altyapısı | ✅ |
| Task 2: Sözlük | ✅ |
| Task 3: Çevirme Pratiği | ✅ |
| Task 4: Eşleşme | ⏳ (Altyapı hazır, UI bekliyor) |
| Task 5: AI Bot | ✅ |
| Task 6: Sınav Hazırlık | ✅ |
| Task 7: Okuma Pratiği | ✅ |

## Notlar
- 6/7 görev tamamlandı
- Eşleşme sistemi için WebRTC UI'ı ayrı bir task olarak planlanabilir
- Backend bağlantısı .env dosyasından okunuyor (API_PORT, REAL_DEVICE_IP, GROQ_API_KEY)
- Hata durumlarında graceful degradation uygulandı
