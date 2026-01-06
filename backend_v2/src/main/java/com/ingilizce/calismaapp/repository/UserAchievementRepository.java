package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.User;
import com.ingilizce.calismaapp.entity.UserAchievement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserAchievementRepository extends JpaRepository<UserAchievement, Long> {

    // Yeni User-based metotlar
    List<UserAchievement> findByUser(User user);

    boolean existsByUserAndAchievementCode(User user, String achievementCode);

    // Geriye uyumluluk için userId-based metotlar
    @Query("SELECT ua FROM UserAchievement ua WHERE ua.user.id = :userId")
    List<UserAchievement> findByUserId(@Param("userId") Long userId);

    @Query("SELECT COUNT(ua) > 0 FROM UserAchievement ua WHERE ua.user.id = :userId AND ua.achievementCode = :code")
    boolean existsByUserIdAndAchievementCode(@Param("userId") Long userId, @Param("code") String achievementCode);

    // Achievement sayısı
    @Query("SELECT COUNT(ua) FROM UserAchievement ua WHERE ua.user = :user")
    long countByUser(@Param("user") User user);
}
