package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.entity.UserSession;
import com.ingilizce.calismaapp.entity.UserSettings;
import com.ingilizce.calismaapp.repository.UserRepository;
import com.ingilizce.calismaapp.repository.UserSessionRepository;
import com.ingilizce.calismaapp.repository.UserSettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.UUID;

@Service
public class AuthService {

    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final Random random = new Random();

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserSessionRepository sessionRepository;

    @Autowired
    private UserSettingsRepository settingsRepository;

    /**
     * Discord tarzı benzersiz kullanıcı tag'ı oluştur: #12345
     */
    private String generateUniqueUserTag() {
        String tag;
        int attempts = 0;
        do {
            // 5 haneli rastgele sayı: 10000-99999
            int number = 10000 + random.nextInt(90000);
            tag = "#" + number;
            attempts++;
            if (attempts > 100) {
                // Çok fazla deneme, 6 haneli geç
                number = 100000 + random.nextInt(900000);
                tag = "#" + number;
            }
        } while (userRepository.existsByUserTag(tag));
        return tag;
    }

    /**
     * Yeni kullanıcı kaydı
     */
    @Transactional
    public Map<String, Object> register(String email, String displayName, String password, String deviceInfo) {
        Map<String, Object> response = new HashMap<>();

        // Email kontrolü
        if (userRepository.existsByEmail(email)) {
            response.put("success", false);
            response.put("error", "Bu email adresi zaten kullanılıyor");
            return response;
        }

        // Display name kontrolü (boş olamaz)
        if (displayName == null || displayName.trim().isEmpty()) {
            response.put("success", false);
            response.put("error", "İsim gerekli");
            return response;
        }

        // Benzersiz userTag oluştur
        String userTag = generateUniqueUserTag();

        // Kullanıcı oluştur
        User user = new User(email, displayName.trim(), passwordEncoder.encode(password), userTag);
        user.recordLogin();
        user = userRepository.save(user);

        // Varsayılan ayarları oluştur
        UserSettings settings = new UserSettings(user);
        settingsRepository.save(settings);

        // Oturum oluştur
        String sessionToken = generateSessionToken();
        UserSession session = createSession(user, sessionToken, deviceInfo);

        logger.info("New user registered: {} ({})", user.getFullDisplayTag(), email);

        response.put("success", true);
        response.put("user", buildUserResponse(user));
        response.put("sessionToken", sessionToken);
        response.put("expiresAt", session.getExpiresAt().toString());

        return response;
    }

    /**
     * Kullanıcı girişi (email veya userTag ile)
     */
    @Transactional
    public Map<String, Object> login(String emailOrTag, String password, String deviceInfo) {
        Map<String, Object> response = new HashMap<>();

        // Kullanıcıyı bul (email veya userTag ile)
        Optional<User> userOpt;
        if (emailOrTag.startsWith("#")) {
            // UserTag ile giriş
            userOpt = userRepository.findByUserTag(emailOrTag);
        } else {
            // Email ile giriş
            userOpt = userRepository.findByEmail(emailOrTag);
        }

        if (userOpt.isEmpty()) {
            response.put("success", false);
            response.put("error", "Kullanıcı bulunamadı");
            return response;
        }

        User user = userOpt.get();

        // Şifre kontrolü
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            response.put("success", false);
            response.put("error", "Hatalı şifre");
            return response;
        }

        // Hesap aktif mi?
        if (!user.getIsActive()) {
            response.put("success", false);
            response.put("error", "Hesabınız devre dışı bırakılmış");
            return response;
        }

        // Giriş kaydet
        user.recordLogin();
        userRepository.save(user);

        // Yeni oturum oluştur
        String sessionToken = generateSessionToken();
        UserSession session = createSession(user, sessionToken, deviceInfo);

        logger.info("User logged in: {}", user.getFullDisplayTag());

        response.put("success", true);
        response.put("user", buildUserResponse(user));
        response.put("sessionToken", sessionToken);
        response.put("expiresAt", session.getExpiresAt().toString());

        return response;
    }

    /**
     * Çıkış yap
     */
    @Transactional
    public Map<String, Object> logout(String sessionToken) {
        Map<String, Object> response = new HashMap<>();

        Optional<UserSession> sessionOpt = sessionRepository.findBySessionToken(sessionToken);

        if (sessionOpt.isPresent()) {
            UserSession session = sessionOpt.get();
            session.invalidate();
            sessionRepository.save(session);

            User user = session.getUser();
            user.recordLogout();
            userRepository.save(user);

            logger.info("User logged out: {}", user.getFullDisplayTag());
        }

        response.put("success", true);
        return response;
    }

    /**
     * Token doğrulama
     */
    public Optional<User> validateToken(String sessionToken) {
        Optional<UserSession> sessionOpt = sessionRepository.findBySessionToken(sessionToken);

        if (sessionOpt.isEmpty()) {
            return Optional.empty();
        }

        UserSession session = sessionOpt.get();

        // Geçerlilik kontrolü
        if (!session.getIsActive() || session.isExpired()) {
            return Optional.empty();
        }

        // Aktivite güncelle
        session.recordActivity();
        sessionRepository.save(session);

        User user = session.getUser();
        user.recordActivity();
        userRepository.save(user);

        return Optional.of(user);
    }

    /**
     * UserTag ile kullanıcı ara
     */
    public Optional<User> findUserByTag(String userTag) {
        if (!userTag.startsWith("#")) {
            userTag = "#" + userTag;
        }
        return userRepository.findByUserTag(userTag);
    }

    /**
     * Profil güncelleme
     */
    @Transactional
    public Map<String, Object> updateProfile(Long userId, Map<String, Object> updates) {
        Map<String, Object> response = new HashMap<>();

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            response.put("success", false);
            response.put("error", "Kullanıcı bulunamadı");
            return response;
        }

        User user = userOpt.get();

        // Güncellenebilir alanlar (displayName herkes istediğini kullanabilir)
        if (updates.containsKey("displayName")) {
            String newName = (String) updates.get("displayName");
            if (newName != null && !newName.trim().isEmpty()) {
                user.setDisplayName(newName.trim());
            }
        }
        if (updates.containsKey("bio")) {
            user.setBio((String) updates.get("bio"));
        }
        if (updates.containsKey("avatarUrl")) {
            user.setAvatarUrl((String) updates.get("avatarUrl"));
        }
        if (updates.containsKey("country")) {
            user.setCountry((String) updates.get("country"));
        }
        if (updates.containsKey("nativeLanguage")) {
            user.setNativeLanguage((String) updates.get("nativeLanguage"));
        }
        if (updates.containsKey("targetLanguage")) {
            user.setTargetLanguage((String) updates.get("targetLanguage"));
        }
        if (updates.containsKey("proficiencyLevel")) {
            String level = (String) updates.get("proficiencyLevel");
            try {
                user.setProficiencyLevel(User.ProficiencyLevel.valueOf(level.toUpperCase().replace("-", "_")));
            } catch (IllegalArgumentException e) {
                // Geçersiz seviye, sessizce yoksay
            }
        }

        userRepository.save(user);

        response.put("success", true);
        response.put("user", buildUserResponse(user));
        return response;
    }

    /**
     * Şifre değiştirme
     */
    @Transactional
    public Map<String, Object> changePassword(Long userId, String currentPassword, String newPassword) {
        Map<String, Object> response = new HashMap<>();

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            response.put("success", false);
            response.put("error", "Kullanıcı bulunamadı");
            return response;
        }

        User user = userOpt.get();

        // Mevcut şifre kontrolü
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            response.put("success", false);
            response.put("error", "Mevcut şifre hatalı");
            return response;
        }

        // Yeni şifre ayarla
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Tüm oturumları kapat (güvenlik)
        sessionRepository.invalidateAllUserSessions(user, LocalDateTime.now());

        response.put("success", true);
        response.put("message", "Şifre başarıyla güncellendi. Lütfen tekrar giriş yapın.");
        return response;
    }

    // === Helper Methods ===

    private String generateSessionToken() {
        return UUID.randomUUID().toString() + "-" + System.currentTimeMillis();
    }

    private UserSession createSession(User user, String sessionToken, String deviceInfo) {
        UserSession session = new UserSession(user, sessionToken);
        session.setRefreshToken(UUID.randomUUID().toString());
        session.setDeviceType(deviceInfo != null && deviceInfo.contains("Android") ? "MOBILE" : "WEB");
        session.setDeviceName(deviceInfo);
        return sessionRepository.save(session);
    }

    private Map<String, Object> buildUserResponse(User user) {
        Map<String, Object> userMap = new HashMap<>();
        userMap.put("id", user.getId());
        userMap.put("email", user.getEmail());
        userMap.put("userTag", user.getUserTag());
        userMap.put("displayName", user.getDisplayName());
        userMap.put("fullDisplayTag", user.getFullDisplayTag()); // "Eren#12345"
        userMap.put("avatarUrl", user.getAvatarUrl());
        userMap.put("bio", user.getBio());
        userMap.put("country", user.getCountry());
        userMap.put("nativeLanguage", user.getNativeLanguage());
        userMap.put("targetLanguage", user.getTargetLanguage());
        userMap.put("proficiencyLevel", user.getProficiencyLevel().getDisplayName());
        userMap.put("isPremium", user.getIsPremium());
        userMap.put("isEmailVerified", user.getIsEmailVerified());
        userMap.put("totalXp", user.getTotalXp());
        userMap.put("level", user.getLevel());
        userMap.put("currentStreak", user.getCurrentStreak());
        userMap.put("longestStreak", user.getLongestStreak());
        userMap.put("wordsLearned", user.getWordsLearned());
        userMap.put("totalStudyTimeMinutes", user.getTotalStudyTimeMinutes());
        userMap.put("createdAt", user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);
        userMap.put("lastLogin", user.getLastLogin() != null ? user.getLastLogin().toString() : null);
        return userMap;
    }
}
