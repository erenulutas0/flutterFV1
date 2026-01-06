package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.UserDailyStats;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserDailyStatsRepository extends JpaRepository<UserDailyStats, Long> {

    Optional<UserDailyStats> findByUserAndStatDate(User user, LocalDate date);

    List<UserDailyStats> findByUser(User user);

    // Tarih aralığındaki istatistikler
    @Query("SELECT s FROM UserDailyStats s WHERE s.user = :user AND s.statDate BETWEEN :startDate AND :endDate ORDER BY s.statDate ASC")
    List<UserDailyStats> findByUserAndDateRange(
            @Param("user") User user,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    // Son N günün istatistikleri
    @Query("SELECT s FROM UserDailyStats s WHERE s.user = :user ORDER BY s.statDate DESC")
    List<UserDailyStats> findRecentStatsByUser(@Param("user") User user);

    // Toplam XP (belirli tarih aralığı)
    @Query("SELECT COALESCE(SUM(s.xpEarned), 0) FROM UserDailyStats s WHERE s.user = :user AND s.statDate BETWEEN :startDate AND :endDate")
    int sumXpEarned(@Param("user") User user, @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    // Toplam çalışma süresi (belirli tarih aralığı)
    @Query("SELECT COALESCE(SUM(s.studyTimeMinutes), 0) FROM UserDailyStats s WHERE s.user = :user AND s.statDate BETWEEN :startDate AND :endDate")
    int sumStudyTime(@Param("user") User user, @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    // Günlük hedefi tamamlanan gün sayısı
    @Query("SELECT COUNT(s) FROM UserDailyStats s WHERE s.user = :user AND s.dailyGoalCompleted = true AND s.statDate BETWEEN :startDate AND :endDate")
    long countDaysGoalCompleted(@Param("user") User user, @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    // Haftalık özet
    @Query("SELECT new map(" +
            "SUM(s.xpEarned) as totalXp, " +
            "SUM(s.wordsLearned) as totalWordsLearned, " +
            "SUM(s.wordsReviewed) as totalWordsReviewed, " +
            "SUM(s.studyTimeMinutes) as totalStudyTime, " +
            "SUM(s.correctAnswers) as totalCorrect, " +
            "SUM(s.totalAnswers) as totalAnswers) " +
            "FROM UserDailyStats s WHERE s.user = :user AND s.statDate BETWEEN :startDate AND :endDate")
    Object getWeeklySummary(@Param("user") User user, @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
