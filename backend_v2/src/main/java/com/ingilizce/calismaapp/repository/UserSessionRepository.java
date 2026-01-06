package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.UserSession;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, Long> {

    Optional<UserSession> findBySessionToken(String sessionToken);

    Optional<UserSession> findByRefreshToken(String refreshToken);

    List<UserSession> findByUser(User user);

    List<UserSession> findByUserAndIsActiveTrue(User user);

    // Aktif oturum sayısı
    long countByUserAndIsActiveTrue(User user);

    // Süresi dolmuş oturumları bul
    @Query("SELECT s FROM UserSession s WHERE s.expiresAt < :now AND s.isActive = true")
    List<UserSession> findExpiredSessions(@Param("now") LocalDateTime now);

    // Süresi dolmuş oturumları pasifleştir
    @Modifying
    @Query("UPDATE UserSession s SET s.isActive = false WHERE s.expiresAt < :now AND s.isActive = true")
    int invalidateExpiredSessions(@Param("now") LocalDateTime now);

    // Kullanıcının tüm oturumlarını kapat
    @Modifying
    @Query("UPDATE UserSession s SET s.isActive = false, s.logoutAt = :now WHERE s.user = :user AND s.isActive = true")
    int invalidateAllUserSessions(@Param("user") User user, @Param("now") LocalDateTime now);

    // Belirli bir cihaz türündeki oturumları bul
    List<UserSession> findByUserAndDeviceTypeAndIsActiveTrue(User user, String deviceType);
}
