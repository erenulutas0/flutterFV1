# VocabMaster - Flutter Version

React/TypeScript web uygulamasından Flutter/Dart mobil uygulamasına çevirilmiş VocabMaster kelime öğrenme uygulaması.

## 🎯 Özellikler

- ✅ **Ana Sayfa (HomePage)** - Kullanıcı profili, XP ilerlemesi, günlük hedef, haftalık aktivite, hızlı erişim ve çevrimiçi kullanıcılar
- ✅ **İstatistikler (StatsPage)** - Haftalık ilerleme grafiği, kategori dağılımı ve başarılar
- ✅ **Tekrar (RepeatPage)** - Flashcard sistemi ile kelime tekrarı
- ✅ **Sözlük (DictionaryPage)** - Kelime arama ve çeviri
- ✅ **Animasyonlu Arka Plan** - 40 adet yağmur damlası animasyonu ve 6 adet orb efekti
- ✅ **Glass Effect** - Transparent backdrop blur efekti
- ✅ **Cyan-Blue Tema** - Modern gradient renkler

## 📦 Kurulum

### 1. Flutter SDK Yükleyin
```bash
# Flutter SDK'yı indirin: https://flutter.dev/docs/get-started/install
```

### 2. Projeyi Klonlayın
```bash
cd flutter_vocabmaster
```

### 3. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 4. Uygulamayı Çalıştırın
```bash
# iOS Simulator için
flutter run -d ios

# Android Emulator için
flutter run -d android

# Chrome için (test amaçlı)
flutter run -d chrome
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                    # Ana uygulama giriş noktası
├── screens/
│   ├── home_page.dart          # Ana sayfa
│   ├── stats_page.dart         # İstatistikler sayfası
│   ├── repeat_page.dart        # Tekrar (Flashcard) sayfası
│   └── dictionary_page.dart    # Sözlük sayfası
└── widgets/
    ├── animated_background.dart # Yağmur damlası animasyonu
    └── bottom_nav.dart          # Alt navigasyon barı
```

## 🎨 Tasarım Sistemi

### Renkler
- **Primary Cyan:** `#06b6d4`
- **Primary Blue:** `#3b82f6`
- **Light Cyan:** `#22d3ee`
- **Sky Blue:** `#0ea5e9`
- **Background:** Gradient from `#172554` → `#1e1b4b` → `#1e3a8a`

### Glass Effect
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
  ),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: ...
  ),
)
```

## 🔥 Kullanılan Paketler

- **fl_chart** - Grafik ve chart'lar için
- **http** - API çağrıları için (gelecekte eklenecek)
- **shared_preferences** - Yerel veri saklama

## 🚀 Gelecek Geliştirmeler

- [ ] WordsPage (Kelimeler sayfası) implementation
- [ ] SentencesPage (Cümleler sayfası) implementation
- [ ] SpeakingPage (Konuşma pratiği) implementation
- [ ] ProfilePage (Profil sayfası) implementation
- [ ] ReadingPage (Okuma egzersizi) implementation
- [ ] Backend entegrasyonu (Supabase veya Firebase)
- [ ] Ses kaydı ve konuşma analizi
- [ ] Sosyal özellikler (chat, arkadaş listesi)
- [ ] Bildirimler (push notifications)
- [ ] Offline mode

## 📝 React → Flutter Dönüşüm Notları

### Component → Widget
```typescript
// React
<Card className="p-6 bg-white/5">
  <Text>Hello</Text>
</Card>

// Flutter
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
  ),
  child: Text('Hello'),
)
```

### useState → StatefulWidget
```typescript
// React
const [count, setCount] = useState(0);

// Flutter
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int count = 0;
  
  void increment() {
    setState(() {
      count++;
    });
  }
}
```

### Tailwind CSS → Flutter Styling
```typescript
// React + Tailwind
className="p-6 rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600"

// Flutter
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: LinearGradient(
      colors: [Color(0xFF06b6d4), Color(0xFF3b82f6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
)
```

## 🐛 Bilinen Sorunlar

- BackdropFilter iOS'ta bazı cihazlarda performans sorununa yol açabilir
- fl_chart web desteği sınırlıdır

## 📱 Desteklenen Platformlar

- ✅ iOS 12.0+
- ✅ Android 5.0+ (API 21+)
- ⚠️ Web (deneysel)

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje eğitim amaçlıdır ve MIT lisansı altındadır.

## 👨‍💻 Geliştirici

React web versiyonundan Flutter mobil versiyonuna çevrilmiştir.

---

**Not:** Bu Flutter uygulaması, mevcut React/TypeScript web uygulamasının tam karşılığıdır. Tüm animasyonlar, glass effect'ler ve cyan-blue renk teması korunmuştur.
