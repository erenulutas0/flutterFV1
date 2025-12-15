# English Learning App - Flutter Versiyonu

Bu proje, İngilizce öğrenme uygulamasının Flutter ile geliştirilmiş versiyonudur.

## Özellikler

- 📅 **Tarihsel Takip**: Takvim üzerinden öğrenilen kelimeleri görüntüleme
- 📚 **Kelime Yönetimi**: Kelime ekleme, silme ve düzenleme
- 📝 **Cümle Yönetimi**: Her kelime için örnek cümleler ekleme
- 📊 **İstatistikler**: Öğrenme istatistiklerini görüntüleme
- 🎨 **Modern UI**: Material Design 3 ile modern ve kullanıcı dostu arayüz
- 🔄 **State Management**: Provider ile state yönetimi

## Gereksinimler

- Flutter SDK (3.0.0 veya üzeri)
- Dart SDK (3.0.0 veya üzeri)
- Backend API (Java Spring Boot) çalışıyor olmalı (localhost:8082)

## Kurulum

1. Projeyi klonlayın:
```bash
cd flutter_app
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Backend API'nin çalıştığından emin olun (localhost:8082)

4. Uygulamayı çalıştırın:
```bash
flutter run
```

## Yapı

```
flutter_app/
├── lib/
│   ├── main.dart                 # Uygulama giriş noktası
│   ├── models/                   # Veri modelleri
│   │   ├── word.dart
│   │   ├── sentence_practice.dart
│   │   └── word_review.dart
│   ├── services/                 # API servisleri
│   │   └── api_service.dart
│   ├── providers/                # State yönetimi
│   │   ├── word_provider.dart
│   │   └── sentence_provider.dart
│   └── screens/                  # Ekranlar
│       ├── home_screen.dart
│       ├── words_screen.dart
│       ├── sentences_screen.dart
│       └── generate_screen.dart
└── pubspec.yaml                  # Bağımlılıklar
```

## Kullanım

### Ana Sayfa
Uygulamanın ana sayfasından tüm özelliklere erişebilirsiniz:
- Kelimeler sayfasına gitme
- Cümleler sayfasına gitme
- Cümle üretme sayfasına gitme

### Kelimeler Sayfası
- Takvimden bir tarih seçerek o gün öğrenilen kelimeleri görüntüleyin
- Yeni kelime ekleyin (İngilizce kelime, Türkçe anlamı, zorluk seviyesi)
- Kelimeleri silin
- Kelimelere örnek cümleler ekleyin

### Cümleler Sayfası
- Tüm cümleleri görüntüleyin
- Zorluk seviyesine göre filtreleyin (Kolay, Orta, Zor)
- Yeni cümle ekleyin
- Cümleleri silin
- İstatistikleri görüntüleyin

### Cümle Üretme Sayfası
- Manuel olarak cümle ekleyin
- Kelimelerinizi görüntüleyin
- (Yakında) AI destekli cümle üretimi

## API Bağlantısı

Uygulama, backend API ile iletişim kurmak için `http://localhost:8082/api` adresini kullanır.

Eğer backend farklı bir adreste çalışıyorsa, `lib/services/api_service.dart` dosyasındaki `baseUrl` değerini değiştirin:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:8082/api';
```

## Bağımlılıklar

- `http`: HTTP istekleri için
- `provider`: State yönetimi için
- `intl`: Tarih formatlama için
- `table_calendar`: Takvim görünümü için

## Lisans

Bu proje özel kullanım içindir.

