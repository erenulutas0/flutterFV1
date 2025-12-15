# Flutter Frontend'i React'e Uyarlama Rehberi

Bu rehber, Flutter uygulamanızı React frontend'inizle aynı görünüme getirmek için yapmanız gerekenleri açıklar.

## Önemli Tasarım Özellikleri

### 1. Gradient Arka Planlar
React'te: `bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50`
Flutter'da: `Container` içinde `LinearGradient` kullanın

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEFF6FF), // blue-50
        Color(0xFFF5F3FF), // indigo-50
        Color(0xFFFAF5FF), // purple-50
      ],
    ),
  ),
)
```

### 2. Card Tasarımı (Backdrop Blur)
React'te: `bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm`
Flutter'da: `BackdropFilter` ve opacity kullanın

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFE5E7EB)),
    ),
    child: Card(...),
  ),
)
```

**Not:** `dart:ui` import edin: `import 'dart:ui';`

### 3. Renk Paleti
- **Indigo-600**: `Color(0xFF4F46E5)`
- **Purple-600**: `Color(0xFF9333EA)`
- **Indigo-900**: `Color(0xFF1E3A8A)`
- **Gray-800**: `Color(0xFF1F2937)`
- **Gray-900**: `Color(0xFF0F172A)`

### 4. Button Gradient
React'te: `bg-gradient-to-r from-indigo-600 to-purple-600`
Flutter'da:

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      child: Padding(...),
    ),
  ),
)
```

### 5. Typography
- Başlıklar: Indigo-900 (light) / Indigo-100 (dark)
- Body text: Gray-600 (light) / Gray-400 (dark)
- Font ağırlıkları: Bold (700), Medium (500), Normal (400)

## Yapılacaklar

1. ✅ `lib/theme/app_theme.dart` - Tema dosyası oluşturuldu
2. ⏳ `lib/main.dart` - Tema'yı uygula
3. ⏳ `lib/screens/home_screen.dart` - Gradient ve card tasarımını güncelle
4. ⏳ `lib/screens/words_screen.dart` - Layout ve card stillerini güncelle
5. ⏳ `lib/screens/sentences_screen.dart` - Arama ve filtreleme UI'ını geliştir
6. ⏳ `lib/screens/generate_screen.dart` - Tasarımı güncelle

## Örnek Backdrop Blur Card

```dart
import 'dart:ui';

Widget buildBlurCard(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xFF1F2937).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF374151)
                : Color(0xFFE5E7EB),
          ),
        ),
        child: child,
      ),
    ),
  );
}
```

## Hızlı İyileştirmeler

1. **Pubspec.yaml'a ekle:**
```yaml
dependencies:
  backdrop_filter: ^0.1.0  # Backdrop blur için
```

2. **Main.dart'ta tema uygula:**
```dart
import 'theme/app_theme.dart';

MaterialApp(
  theme: AppTheme.darkTheme,
  ...
)
```

3. **Card'ları güncelle:** Tüm `Card` widget'larını `buildBlurCard` ile sarın

4. **Renkleri güncelle:** Hard-coded renkler yerine `AppTheme` sınıfındaki renkleri kullanın

## Sonraki Adımlar

1. Her ekranı tek tek güncelleyin
2. Backdrop blur efektlerini ekleyin
3. Gradient butonları ekleyin
4. Typography stillerini düzeltin
5. Spacing ve padding değerlerini React'teki gibi ayarlayın




