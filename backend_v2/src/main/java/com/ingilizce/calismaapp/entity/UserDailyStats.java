package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_daily_stats", indexes = {
        @Index(name = "idx_daily_stats_user_date", columnList = "user_id, stat_date")
})
public class UserDailyStats {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "stat_date", nullable = false)
    private LocalDate statDate;

    // === Günlük İstatistikler ===
    @Column(name = "xp_earned")
    private Integer xpEarned = 0;

    @Column(name = "words_learned")
    private Integer wordsLearned = 0;

    @Column(name = "words_reviewed")
    private Integer wordsReviewed = 0;

    @Column(name = "sentences_practiced")
    private Integer sentencesPracticed = 0;

    @Column(name = "reading_passages_completed")
    private Integer readingPassagesCompleted = 0;

    @Column(name = "speaking_minutes")
    private Integer speakingMinutes = 0;

    @Column(name = "listening_minutes")
    private Integer listeningMinutes = 0;

    @Column(name = "study_time_minutes")
    private Integer studyTimeMinutes = 0;

    @Column(name = "correct_answers")
    private Integer correctAnswers = 0;

    @Column(name = "total_answers")
    private Integer totalAnswers = 0;

    @Column(name = "video_calls_count")
    private Integer videoCallsCount = 0;

    @Column(name = "video_calls_minutes")
    private Integer videoCallsMinutes = 0;

    @Column(name = "daily_goal_completed")
    private Boolean dailyGoalCompleted = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructors
    public UserDailyStats() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public UserDailyStats(User user, LocalDate date) {
        this();
        this.user = user;
        this.statDate = date;
    }

    // Business Methods
    public double getAccuracyRate() {
        if (totalAnswers == 0)
            return 0;
        return (double) correctAnswers / totalAnswers * 100;
    }

    public void addXp(int xp) {
        this.xpEarned += xp;
        this.updatedAt = LocalDateTime.now();
    }

    public void incrementWordsLearned() {
        this.wordsLearned++;
        this.updatedAt = LocalDateTime.now();
    }

    public void incrementWordsReviewed() {
        this.wordsReviewed++;
        this.updatedAt = LocalDateTime.now();
    }

    public void addStudyTime(int minutes) {
        this.studyTimeMinutes += minutes;
        this.updatedAt = LocalDateTime.now();
    }

    public void recordAnswer(boolean correct) {
        this.totalAnswers++;
        if (correct)
            this.correctAnswers++;
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
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

    public LocalDate getStatDate() {
        return statDate;
    }

    public void setStatDate(LocalDate statDate) {
        this.statDate = statDate;
    }

    public Integer getXpEarned() {
        return xpEarned;
    }

    public void setXpEarned(Integer xpEarned) {
        this.xpEarned = xpEarned;
    }

    public Integer getWordsLearned() {
        return wordsLearned;
    }

    public void setWordsLearned(Integer wordsLearned) {
        this.wordsLearned = wordsLearned;
    }

    public Integer getWordsReviewed() {
        return wordsReviewed;
    }

    public void setWordsReviewed(Integer wordsReviewed) {
        this.wordsReviewed = wordsReviewed;
    }

    public Integer getSentencesPracticed() {
        return sentencesPracticed;
    }

    public void setSentencesPracticed(Integer sentencesPracticed) {
        this.sentencesPracticed = sentencesPracticed;
    }

    public Integer getReadingPassagesCompleted() {
        return readingPassagesCompleted;
    }

    public void setReadingPassagesCompleted(Integer readingPassagesCompleted) {
        this.readingPassagesCompleted = readingPassagesCompleted;
    }

    public Integer getSpeakingMinutes() {
        return speakingMinutes;
    }

    public void setSpeakingMinutes(Integer speakingMinutes) {
        this.speakingMinutes = speakingMinutes;
    }

    public Integer getListeningMinutes() {
        return listeningMinutes;
    }

    public void setListeningMinutes(Integer listeningMinutes) {
        this.listeningMinutes = listeningMinutes;
    }

    public Integer getStudyTimeMinutes() {
        return studyTimeMinutes;
    }

    public void setStudyTimeMinutes(Integer studyTimeMinutes) {
        this.studyTimeMinutes = studyTimeMinutes;
    }

    public Integer getCorrectAnswers() {
        return correctAnswers;
    }

    public void setCorrectAnswers(Integer correctAnswers) {
        this.correctAnswers = correctAnswers;
    }

    public Integer getTotalAnswers() {
        return totalAnswers;
    }

    public void setTotalAnswers(Integer totalAnswers) {
        this.totalAnswers = totalAnswers;
    }

    public Integer getVideoCallsCount() {
        return videoCallsCount;
    }

    public void setVideoCallsCount(Integer videoCallsCount) {
        this.videoCallsCount = videoCallsCount;
    }

    public Integer getVideoCallsMinutes() {
        return videoCallsMinutes;
    }

    public void setVideoCallsMinutes(Integer videoCallsMinutes) {
        this.videoCallsMinutes = videoCallsMinutes;
    }

    public Boolean getDailyGoalCompleted() {
        return dailyGoalCompleted;
    }

    public void setDailyGoalCompleted(Boolean dailyGoalCompleted) {
        this.dailyGoalCompleted = dailyGoalCompleted;
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
}
