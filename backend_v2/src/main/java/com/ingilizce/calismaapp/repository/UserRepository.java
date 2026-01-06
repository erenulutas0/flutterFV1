package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // === Temel Sorgular ===
    Optional<User> findByEmail(String email);

    Optional<User> findByUserTag(String userTag);

    boolean existsByEmail(String email);

    boolean existsByUserTag(String userTag);

    // === Aktif Kullanıcılar ===
    List<User> findByIsActiveTrue();

    List<User> findByIsOnlineTrue();

    // === Arama ===
    @Query("SELECT u FROM User u WHERE " +
            "LOWER(u.displayName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(u.userTag) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<User> searchUsers(@Param("query") String query);

    // === Liderlik Tablosu ===
    @Query("SELECT u FROM User u WHERE u.isActive = true ORDER BY u.totalXp DESC")
    List<User> findTopUsersByXp();

    @Query("SELECT u FROM User u WHERE u.isActive = true ORDER BY u.currentStreak DESC")
    List<User> findTopUsersByStreak();

    @Query("SELECT u FROM User u WHERE u.isActive = true ORDER BY u.wordsLearned DESC")
    List<User> findTopUsersByWordsLearned();

    // === Son Aktif Kullanıcılar ===
    List<User> findByLastActivityAtAfterOrderByLastActivityAtDesc(LocalDateTime since);

    // === Seviyeye Göre ===
    List<User> findByLevel(Integer level);

    @Query("SELECT u FROM User u WHERE u.level BETWEEN :minLevel AND :maxLevel")
    List<User> findByLevelRange(@Param("minLevel") int minLevel, @Param("maxLevel") int maxLevel);

    // === Premium Kullanıcılar ===
    List<User> findByIsPremiumTrue();

    @Query("SELECT u FROM User u WHERE u.isPremium = true AND u.premiumExpiresAt < :date")
    List<User> findExpiredPremiumUsers(@Param("date") LocalDateTime date);

    // === İstatistikler ===
    @Query("SELECT COUNT(u) FROM User u WHERE u.isActive = true")
    long countActiveUsers();

    @Query("SELECT COUNT(u) FROM User u WHERE u.isOnline = true")
    long countOnlineUsers();

    @Query("SELECT COUNT(u) FROM User u WHERE u.createdAt > :since")
    long countNewUsersSince(@Param("since") LocalDateTime since);
}
