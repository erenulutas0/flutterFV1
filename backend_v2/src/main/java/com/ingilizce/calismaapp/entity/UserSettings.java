package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalTime;

@Entity
@Table(name = "user_settings")
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    // === Bildirim Ayarları ===
    @Column(name = "push_notifications_enabled")
    private Boolean pushNotificationsEnabled = true;

    @Column(name = "email_notifications_enabled")
    private Boolean emailNotificationsEnabled = true;

    @Column(name = "sound_enabled")
    private Boolean soundEnabled = true;

    @Column(name = "vibration_enabled")
    private Boolean vibrationEnabled = true;

    @Column(name = "daily_reminder_enabled")
    private Boolean dailyReminderEnabled = true;

    @Column(name = "daily_reminder_time")
    private LocalTime dailyReminderTime = LocalTime.of(20, 0); // 20:00 default

    // === Görünüm Ayarları ===
    @Column(name = "dark_mode")
    private Boolean darkMode = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "font_size")
    private FontSize fontSize = FontSize.MEDIUM;

    @Enumerated(EnumType.STRING)
    @Column(name = "theme_color")
    private ThemeColor themeColor = ThemeColor.BLUE;

    // === Öğrenme Ayarları ===
    @Column(name = "auto_play_audio")
    private Boolean autoPlayAudio = true;

    @Column(name = "daily_goal_xp")
    private Integer dailyGoalXp = 50;

    @Column(name = "daily_goal_words")
    private Integer dailyGoalWords = 10;

    @Column(name = "daily_goal_minutes")
    private Integer dailyGoalMinutes = 15;

    // === Gizlilik Ayarları ===
    @Column(name = "profile_visibility")
    @Enumerated(EnumType.STRING)
    private ProfileVisibility profileVisibility = ProfileVisibility.PUBLIC;

    @Column(name = "show_online_status")
    private Boolean showOnlineStatus = true;

    @Column(name = "allow_friend_requests")
    private Boolean allowFriendRequests = true;

    // Constructors
    public UserSettings() {
    }

    public UserSettings(User user) {
        this.user = user;
    }

    // Enums
    public enum FontSize {
        SMALL("Küçük"),
        MEDIUM("Orta"),
        LARGE("Büyük");

        private final String displayName;

        FontSize(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    public enum ThemeColor {
        BLUE("Mavi"),
        PURPLE("Mor"),
        GREEN("Yeşil"),
        ORANGE("Turuncu"),
        PINK("Pembe");

        private final String displayName;

        ThemeColor(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    public enum ProfileVisibility {
        PUBLIC("Herkese Açık"),
        FRIENDS_ONLY("Sadece Arkadaşlar"),
        PRIVATE("Gizli");

        private final String displayName;

        ProfileVisibility(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Boolean getPushNotificationsEnabled() {
        return pushNotificationsEnabled;
    }

    public void setPushNotificationsEnabled(Boolean pushNotificationsEnabled) {
        this.pushNotificationsEnabled = pushNotificationsEnabled;
    }

    public Boolean getEmailNotificationsEnabled() {
        return emailNotificationsEnabled;
    }

    public void setEmailNotificationsEnabled(Boolean emailNotificationsEnabled) {
        this.emailNotificationsEnabled = emailNotificationsEnabled;
    }

    public Boolean getSoundEnabled() {
        return soundEnabled;
    }

    public void setSoundEnabled(Boolean soundEnabled) {
        this.soundEnabled = soundEnabled;
    }

    public Boolean getVibrationEnabled() {
        return vibrationEnabled;
    }

    public void setVibrationEnabled(Boolean vibrationEnabled) {
        this.vibrationEnabled = vibrationEnabled;
    }

    public Boolean getDailyReminderEnabled() {
        return dailyReminderEnabled;
    }

    public void setDailyReminderEnabled(Boolean dailyReminderEnabled) {
        this.dailyReminderEnabled = dailyReminderEnabled;
    }

    public LocalTime getDailyReminderTime() {
        return dailyReminderTime;
    }

    public void setDailyReminderTime(LocalTime dailyReminderTime) {
        this.dailyReminderTime = dailyReminderTime;
    }

    public Boolean getDarkMode() {
        return darkMode;
    }

    public void setDarkMode(Boolean darkMode) {
        this.darkMode = darkMode;
    }

    public FontSize getFontSize() {
        return fontSize;
    }

    public void setFontSize(FontSize fontSize) {
        this.fontSize = fontSize;
    }

    public ThemeColor getThemeColor() {
        return themeColor;
    }

    public void setThemeColor(ThemeColor themeColor) {
        this.themeColor = themeColor;
    }

    public Boolean getAutoPlayAudio() {
        return autoPlayAudio;
    }

    public void setAutoPlayAudio(Boolean autoPlayAudio) {
        this.autoPlayAudio = autoPlayAudio;
    }

    public Integer getDailyGoalXp() {
        return dailyGoalXp;
    }

    public void setDailyGoalXp(Integer dailyGoalXp) {
        this.dailyGoalXp = dailyGoalXp;
    }

    public Integer getDailyGoalWords() {
        return dailyGoalWords;
    }

    public void setDailyGoalWords(Integer dailyGoalWords) {
        this.dailyGoalWords = dailyGoalWords;
    }

    public Integer getDailyGoalMinutes() {
        return dailyGoalMinutes;
    }

    public void setDailyGoalMinutes(Integer dailyGoalMinutes) {
        this.dailyGoalMinutes = dailyGoalMinutes;
    }

    public ProfileVisibility getProfileVisibility() {
        return profileVisibility;
    }

    public void setProfileVisibility(ProfileVisibility profileVisibility) {
        this.profileVisibility = profileVisibility;
    }

    public Boolean getShowOnlineStatus() {
        return showOnlineStatus;
    }

    public void setShowOnlineStatus(Boolean showOnlineStatus) {
        this.showOnlineStatus = showOnlineStatus;
    }

    public Boolean getAllowFriendRequests() {
        return allowFriendRequests;
    }

    public void setAllowFriendRequests(Boolean allowFriendRequests) {
        this.allowFriendRequests = allowFriendRequests;
    }
}
