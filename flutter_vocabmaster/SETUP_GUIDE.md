# 🚀 VocabMaster Flutter - Kurulum Rehberi

React web uygulamasını Flutter mobil uygulamasına dönüştürdük! İşte adım adım kurulum rehberi:

## 📋 Ön Gereksinimler

### 1. Flutter SDK Kurulumu

#### macOS için:
```bash
# Homebrew ile
brew install --cask flutter

# Manuel kurulum
# https://docs.flutter.dev/get-started/install/macos adresinden indirin
```

#### Windows için:
```bash
# Chocolatey ile
choco install flutter

# Manuel kurulum
# https://docs.flutter.dev/get-started/install/windows adresinden indirin
```

#### Linux için:
```bash
# Snap ile
sudo snap install flutter --classic

# Manuel kurulum
# https://docs.flutter.dev/get-started/install/linux adresinden indirin
```

### 2. Flutter Doktor Kontrolü
```bash
flutter doctor
```

Bu komut eksik bileşenleri gösterecek. Aşağıdaki adımları takip edin:

#### Android Studio Kurulumu (Android için)
1. Android Studio'yu indirin: https://developer.android.com/studio
2. Android SDK'yı yükleyin
3. Android emulator oluşturun

#### Xcode Kurulumu (iOS için - sadece macOS)
1. App Store'dan Xcode'u indirin
2. Xcode command line tools yükleyin:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```
3. iOS Simulator açın:
```bash
open -a Simulator
```

### 3. VS Code / Android Studio Ayarları

#### VS Code için:
```bash
# Flutter ve Dart extension'larını yükleyin
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
```

## 🎯 Projeyi Çalıştırma

### 1. Proje Klasörüne Gidin
```bash
cd flutter_vocabmaster
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Cihaz/Emulator Kontrol Edin
```bash
flutter devices
```

Çıktı örneği:
```
3 connected devices:

iPhone 14 Pro (mobile) • A1B2C3D4-E5F6-7G8H-9I0J-K1L2M3N4O5P6 • ios • com.apple.CoreSimulator.SimRuntime.iOS-16-0 (simulator)
sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33) (emulator)
Chrome (web) • chrome • web-javascript • Google Chrome 120.0.0.0
```

### 4. Uygulamayı Çalıştırın

#### iOS Simulator:
```bash
flutter run -d ios
```

#### Android Emulator:
```bash
flutter run -d android
```

#### Chrome (Web - Test için):
```bash
flutter run -d chrome
```

#### Fiziksel Cihaz:
```bash
# USB ile bağlı cihazınızı seçin
flutter run
```

## 🐛 Hata Çözümleri

### Problem 1: "No devices found"
```bash
# iOS Simulator açın
open -a Simulator

# veya Android Emulator başlatın
flutter emulators --launch <emulator_id>
```

### Problem 2: "Waiting for another flutter command to release the startup lock"
```bash
# Lock dosyasını silin
rm -rf ~/.flutter/bin/cache/lockfile
```

### Problem 3: "CocoaPods not installed" (iOS için)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

### Problem 4: "Gradle build failed" (Android için)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Problem 5: "flutter pub get" hatası
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

## 📦 Paket Kurulumları

Eğer pubspec.yaml'da değişiklik yaptıysanız:

```bash
# Bağımlılıkları güncelleyin
flutter pub get

# Eğer iOS için pod güncelleme gerekiyorsa
cd ios
pod install
cd ..
```

## 🎨 Hot Reload Kullanımı

Uygulama çalışırken:
- **`r`** tuşuna basın → Hot reload (hızlı)
- **`R`** tuşuna basın → Hot restart (tam yeniden başlat)
- **`q`** tuşuna basın → Çıkış

## 📱 APK/IPA Oluşturma

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK konumu: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play için):
```bash
flutter build appbundle --release
```

### iOS IPA (macOS gerekli):
```bash
flutter build ios --release

# Xcode ile açıp Archive edin
open ios/Runner.xcworkspace
```

## 🔧 Geliştirme Araçları

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Widget Inspector
VS Code'da:
1. Debug modunda çalıştırın
2. `Ctrl+Shift+P` → "Flutter: Open DevTools"

### Performance Profiler
```bash
flutter run --profile
```

## 📊 Kullanılan Paketler

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2    # iOS style icons
  fl_chart: ^0.65.0          # Grafikler için
  http: ^1.1.0               # API calls (ileride)
  shared_preferences: ^2.2.2  # Local storage
```

## 🎯 Sonraki Adımlar

1. ✅ Uygulamayı çalıştırın
2. ✅ HomePage, StatsPage, RepeatPage, DictionaryPage'i test edin
3. ⏳ WordsPage, SentencesPage, ProfilePage implementasyonlarını ekleyin
4. ⏳ Backend entegrasyonu (Supabase/Firebase)
5. ⏳ Authentication ekleyin
6. ⏳ Push notifications
7. ⏳ App Store / Google Play'e yükleyin

## 📞 Yardım

### Resmi Kaynaklar:
- Flutter Docs: https://docs.flutter.dev
- Flutter Cookbook: https://docs.flutter.dev/cookbook
- Dart Docs: https://dart.dev/guides

### Topluluk:
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter
- Flutter Discord: https://discord.gg/flutter
- Reddit: https://reddit.com/r/FlutterDev

## ✅ Kontrol Listesi

- [ ] Flutter SDK kuruldu
- [ ] Android Studio/Xcode kuruldu
- [ ] `flutter doctor` başarılı
- [ ] Emulator/Simulator çalışıyor
- [ ] `flutter pub get` çalıştırıldı
- [ ] Uygulama başarıyla çalıştı
- [ ] Hot reload test edildi
- [ ] AnimatedBackground animasyonları çalışıyor
- [ ] Glass effect görünüyor
- [ ] Tüm sayfalar arası navigasyon çalışıyor

---

**Başarılar! 🎉**

React web uygulamanız artık Flutter mobil uygulaması olarak çalışıyor! Cursor veya başka bir IDE'de açıp geliştirmeye devam edebilirsiniz.
