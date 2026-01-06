package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_user_email", columnList = "email"),
        @Index(name = "idx_user_tag", columnList = "user_tag")
})
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // === Kimlik Bilgileri ===
    @Column(unique = true, nullable = false, length = 100)
    private String email;

    // Discord tarzı benzersiz kullanıcı etiketi: #12345
    @Column(name = "user_tag", unique = true, nullable = false, length = 10)
    private String userTag;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    // === Profil Bilgileri ===
    // Display name unique OLMAZ, herkes istediği ismi kullanabilir
    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "bio", length = 500)
    private String bio;

    @Column(name = "country", length = 50)
    private String country;

    @Column(name = "timezone", length = 50)
    private String timezone = "Europe/Istanbul";

    // === Dil Ayarları ===
    @Column(name = "native_language", length = 20)
    private String nativeLanguage = "Turkish";

    @Column(name = "target_language", length = 20)
    private String targetLanguage = "English";

    @Enumerated(EnumType.STRING)
    @Column(name = "proficiency_level")
    private ProficiencyLevel proficiencyLevel = ProficiencyLevel.BEGINNER;

    // === Hesap Durumu ===
    @Column(name = "is_email_verified")
    private Boolean isEmailVerified = false;

    @Column(name = "is_premium")
    private Boolean isPremium = false;

    @Column(name = "premium_expires_at")
    private LocalDateTime premiumExpiresAt;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "is_online")
    private Boolean isOnline = false;

    // === Zaman Damgaları ===
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "last_login")
    private LocalDateTime lastLogin;

    @Column(name = "last_logout")
    private LocalDateTime lastLogout;

    @Column(name = "last_activity_at")
    private LocalDateTime lastActivityAt;

    // === İstatistikler (Hızlı Erişim) ===
    @Column(name = "total_xp")
    private Integer totalXp = 0;

    @Column(name = "level")
    private Integer level = 1;

    @Column(name = "current_streak")
    private Integer currentStreak = 0;

    @Column(name = "longest_streak")
    private Integer longestStreak = 0;

    @Column(name = "total_study_time_minutes")
    private Integer totalStudyTimeMinutes = 0;

    @Column(name = "words_learned")
    private Integer wordsLearned = 0;

    // === İlişkiler ===
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Set<UserFriend> friends = new HashSet<>();

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private UserSettings settings;

    // === Constructors ===
    public User() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public User(String email, String displayName, String passwordHash, String userTag) {
        this();
        this.email = email;
        this.displayName = displayName;
        this.passwordHash = passwordHash;
        this.userTag = userTag;
    }

    // === Lifecycle Callbacks ===
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // === Business Methods ===

    /**
     * Discord tarzı tam kullanıcı adı: DisplayName#12345
     */
    public String getFullDisplayTag() {
        return displayName + userTag;
    }

    public void recordLogin() {
        this.lastLogin = LocalDateTime.now();
        this.isOnline = true;
        this.lastActivityAt = LocalDateTime.now();
    }

    public void recordLogout() {
        this.lastLogout = LocalDateTime.now();
        this.isOnline = false;
    }

    public void recordActivity() {
        this.lastActivityAt = LocalDateTime.now();
    }

    public boolean addXp(int xp) {
        int oldLevel = this.level;
        this.totalXp += xp;
        this.level = calculateLevel(this.totalXp);
        return this.level > oldLevel;
    }

    private int calculateLevel(int xp) {
        if (xp < 100)
            return 1;
        if (xp < 250)
            return 2;
        if (xp < 500)
            return 3;
        if (xp < 1000)
            return 4;
        if (xp < 2000)
            return 5;
        if (xp < 3500)
            return 6;
        if (xp < 5500)
            return 7;
        if (xp < 8000)
            return 8;
        if (xp < 11000)
            return 9;
        if (xp < 15000)
            return 10;
        return 10 + ((xp - 15000) / 5000);
    }

    public int getXpForNextLevel() {
        int[] thresholds = { 0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000 };
        if (level < thresholds.length) {
            return thresholds[level];
        }
        return 15000 + ((level - 10) * 5000);
    }

    public double getLevelProgress() {
        int currentLevelXp = level <= 10
                ? new int[] { 0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000 }[level - 1]
                : 15000 + ((level - 11) * 5000);
        int nextLevelXp = getXpForNextLevel();
        if (nextLevelXp == currentLevelXp)
            return 0;
        return (double) (totalXp - currentLevelXp) / (nextLevelXp - currentLevelXp);
    }

    // === Enums ===
    public enum ProficiencyLevel {
        BEGINNER("Beginner", 1),
        ELEMENTARY("Elementary", 2),
        INTERMEDIATE("Intermediate", 3),
        UPPER_INTERMEDIATE("Upper-Intermediate", 4),
        ADVANCED("Advanced", 5),
        NATIVE("Native", 6);

        private final String displayName;
        private final int order;

        ProficiencyLevel(String displayName, int order) {
            this.displayName = displayName;
            this.order = order;
        }

        public String getDisplayName() {
            return displayName;
        }

        public int getOrder() {
            return order;
        }
    }

    // === Getters and Setters ===
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getUserTag() {
        return userTag;
    }

    public void setUserTag(String userTag) {
        this.userTag = userTag;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getBio() {
        return bio;
    }

    public void setBio(String bio) {
        this.bio = bio;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }

    public String getNativeLanguage() {
        return nativeLanguage;
    }

    public void setNativeLanguage(String nativeLanguage) {
        this.nativeLanguage = nativeLanguage;
    }

    public String getTargetLanguage() {
        return targetLanguage;
    }

    public void setTargetLanguage(String targetLanguage) {
        this.targetLanguage = targetLanguage;
    }

    public ProficiencyLevel getProficiencyLevel() {
        return proficiencyLevel;
    }

    public void setProficiencyLevel(ProficiencyLevel proficiencyLevel) {
        this.proficiencyLevel = proficiencyLevel;
    }

    public Boolean getIsEmailVerified() {
        return isEmailVerified;
    }

    public void setIsEmailVerified(Boolean isEmailVerified) {
        this.isEmailVerified = isEmailVerified;
    }

    public Boolean getIsPremium() {
        return isPremium;
    }

    public void setIsPremium(Boolean isPremium) {
        this.isPremium = isPremium;
    }

    public LocalDateTime getPremiumExpiresAt() {
        return premiumExpiresAt;
    }

    public void setPremiumExpiresAt(LocalDateTime premiumExpiresAt) {
        this.premiumExpiresAt = premiumExpiresAt;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public Boolean getIsOnline() {
        return isOnline;
    }

    public void setIsOnline(Boolean isOnline) {
        this.isOnline = isOnline;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public LocalDateTime getLastLogin() {
        return lastLogin;
    }

    public void setLastLogin(LocalDateTime lastLogin) {
        this.lastLogin = lastLogin;
    }

    public LocalDateTime getLastLogout() {
        return lastLogout;
    }

    public void setLastLogout(LocalDateTime lastLogout) {
        this.lastLogout = lastLogout;
    }

    public LocalDateTime getLastActivityAt() {
        return lastActivityAt;
    }

    public void setLastActivityAt(LocalDateTime lastActivityAt) {
        this.lastActivityAt = lastActivityAt;
    }

    public Integer getTotalXp() {
        return totalXp;
    }

    public void setTotalXp(Integer totalXp) {
        this.totalXp = totalXp;
    }

    public Integer getLevel() {
        return level;
    }

    public void setLevel(Integer level) {
        this.level = level;
    }

    public Integer getCurrentStreak() {
        return currentStreak;
    }

    public void setCurrentStreak(Integer currentStreak) {
        this.currentStreak = currentStreak;
    }

    public Integer getLongestStreak() {
        return longestStreak;
    }

    public void setLongestStreak(Integer longestStreak) {
        this.longestStreak = longestStreak;
    }

    public Integer getTotalStudyTimeMinutes() {
        return totalStudyTimeMinutes;
    }

    public void setTotalStudyTimeMinutes(Integer totalStudyTimeMinutes) {
        this.totalStudyTimeMinutes = totalStudyTimeMinutes;
    }

    public Integer getWordsLearned() {
        return wordsLearned;
    }

    public void setWordsLearned(Integer wordsLearned) {
        this.wordsLearned = wordsLearned;
    }

    public Set<UserFriend> getFriends() {
        return friends;
    }

    public void setFriends(Set<UserFriend> friends) {
        this.friends = friends;
    }

    public UserSettings getSettings() {
        return settings;
    }

    public void setSettings(UserSettings settings) {
        this.settings = settings;
    }
}
