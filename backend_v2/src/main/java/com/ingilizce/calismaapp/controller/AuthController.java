package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(originPatterns = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * Kayıt ol
     * POST /api/auth/register
     */
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String displayName = request.get("displayName");
        String password = request.get("password");
        String deviceInfo = request.get("deviceInfo");

        // Validasyon
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", "Email gerekli"));
        }
        if (displayName == null || displayName.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", "İsim gerekli"));
        }
        if (password == null || password.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", "Şifre en az 6 karakter olmalı"));
        }

        Map<String, Object> response = authService.register(email, displayName, password, deviceInfo);

        if ((Boolean) response.get("success")) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Giriş yap (email veya #userTag ile)
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        String emailOrTag = request.get("emailOrTag");
        String password = request.get("password");
        String deviceInfo = request.get("deviceInfo");

        // Validasyon
        if (emailOrTag == null || emailOrTag.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", "Email veya kullanıcı ID gerekli"));
        }
        if (password == null || password.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", "Şifre gerekli"));
        }

        Map<String, Object> response = authService.login(emailOrTag, password, deviceInfo);

        if ((Boolean) response.get("success")) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(401).body(response);
        }
    }

    /**
     * Çıkış yap
     * POST /api/auth/logout
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, Object>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = extractToken(authHeader);

        if (token == null) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "error", "Token gerekli"));
        }

        Map<String, Object> response = authService.logout(token);
        return ResponseEntity.ok(response);
    }

    /**
     * Profil bilgilerini getir
     * GET /api/auth/me
     */
    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getProfile(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = extractToken(authHeader);

        if (token == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Token gerekli"));
        }

        Optional<User> userOpt = authService.validateToken(token);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(401)
                    .body(Map.of("success", false, "error", "Geçersiz veya süresi dolmuş token"));
        }

        User user = userOpt.get();
        return ResponseEntity.ok(Map.of(
                "success", true,
                "user", buildUserResponse(user)));
    }

    /**
     * Kullanıcı ara (userTag ile)
     * GET /api/auth/user/{userTag}
     */
    @GetMapping("/user/{userTag}")
    public ResponseEntity<Map<String, Object>> findUserByTag(
            @PathVariable String userTag,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        String token = extractToken(authHeader);
        if (token == null || authService.validateToken(token).isEmpty()) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Giriş yapmanız gerekiyor"));
        }

        Optional<User> userOpt = authService.findUserByTag(userTag);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("success", false, "error", "Kullanıcı bulunamadı"));
        }

        User user = userOpt.get();
        return ResponseEntity.ok(Map.of(
                "success", true,
                "user", Map.of(
                        "id", user.getId(),
                        "displayName", user.getDisplayName(),
                        "userTag", user.getUserTag(),
                        "fullDisplayTag", user.getFullDisplayTag(),
                        "avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : "",
                        "level", user.getLevel(),
                        "isOnline", user.getIsOnline())));
    }

    /**
     * Profil güncelle
     * PUT /api/auth/profile
     */
    @PutMapping("/profile")
    public ResponseEntity<Map<String, Object>> updateProfile(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody Map<String, Object> updates) {

        String token = extractToken(authHeader);

        if (token == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Token gerekli"));
        }

        Optional<User> userOpt = authService.validateToken(token);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Geçersiz token"));
        }

        Map<String, Object> response = authService.updateProfile(userOpt.get().getId(), updates);
        return ResponseEntity.ok(response);
    }

    /**
     * Şifre değiştir
     * PUT /api/auth/password
     */
    @PutMapping("/password")
    public ResponseEntity<Map<String, Object>> changePassword(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody Map<String, String> request) {

        String token = extractToken(authHeader);

        if (token == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Token gerekli"));
        }

        Optional<User> userOpt = authService.validateToken(token);

        if (userOpt.isEmpty()) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "Geçersiz token"));
        }

        String currentPassword = request.get("currentPassword");
        String newPassword = request.get("newPassword");

        if (newPassword == null || newPassword.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error", "Yeni şifre en az 6 karakter olmalı"));
        }

        Map<String, Object> response = authService.changePassword(userOpt.get().getId(), currentPassword, newPassword);

        if ((Boolean) response.get("success")) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Token doğruluğunu kontrol et
     * GET /api/auth/validate
     */
    @GetMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateToken(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = extractToken(authHeader);

        if (token == null) {
            return ResponseEntity.ok(Map.of("valid", false));
        }

        Optional<User> userOpt = authService.validateToken(token);
        return ResponseEntity.ok(Map.of("valid", userOpt.isPresent()));
    }

    // === Helper Methods ===

    private String extractToken(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        return authHeader; // Bearer olmadan da kabul et
    }

    private Map<String, Object> buildUserResponse(User user) {
        return Map.ofEntries(
                Map.entry("id", user.getId()),
                Map.entry("email", user.getEmail()),
                Map.entry("userTag", user.getUserTag()),
                Map.entry("displayName", user.getDisplayName()),
                Map.entry("fullDisplayTag", user.getFullDisplayTag()),
                Map.entry("avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : ""),
                Map.entry("bio", user.getBio() != null ? user.getBio() : ""),
                Map.entry("country", user.getCountry() != null ? user.getCountry() : ""),
                Map.entry("nativeLanguage", user.getNativeLanguage()),
                Map.entry("targetLanguage", user.getTargetLanguage()),
                Map.entry("proficiencyLevel", user.getProficiencyLevel().getDisplayName()),
                Map.entry("isPremium", user.getIsPremium()),
                Map.entry("isEmailVerified", user.getIsEmailVerified()),
                Map.entry("totalXp", user.getTotalXp()),
                Map.entry("level", user.getLevel()),
                Map.entry("currentStreak", user.getCurrentStreak()),
                Map.entry("longestStreak", user.getLongestStreak()),
                Map.entry("wordsLearned", user.getWordsLearned()),
                Map.entry("totalStudyTimeMinutes", user.getTotalStudyTimeMinutes()),
                Map.entry("createdAt", user.getCreatedAt() != null ? user.getCreatedAt().toString() : ""),
                Map.entry("lastLogin", user.getLastLogin() != null ? user.getLastLogin().toString() : ""));
    }
}
