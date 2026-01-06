package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.UserFriend;
import com.ingilizce.calismaapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserFriendRepository extends JpaRepository<UserFriend, Long> {

    // Arkadaşlık durumunu kontrol et
    Optional<UserFriend> findByUserAndFriend(User user, User friend);

    // Kullanıcının tüm arkadaşlık kayıtları
    List<UserFriend> findByUser(User user);

    List<UserFriend> findByFriend(User friend);

    // Duruma göre filtrele
    List<UserFriend> findByUserAndStatus(User user, UserFriend.FriendStatus status);

    List<UserFriend> findByFriendAndStatus(User friend, UserFriend.FriendStatus status);

    // Bekleyen arkadaşlık istekleri
    @Query("SELECT uf FROM UserFriend uf WHERE uf.friend = :user AND uf.status = 'PENDING'")
    List<UserFriend> findPendingRequestsForUser(@Param("user") User user);

    // Kabul edilmiş arkadaşlar
    @Query("SELECT uf FROM UserFriend uf WHERE " +
            "(uf.user = :user OR uf.friend = :user) AND uf.status = 'ACCEPTED'")
    List<UserFriend> findAcceptedFriendships(@Param("user") User user);

    // Engellenenler
    @Query("SELECT uf FROM UserFriend uf WHERE uf.user = :user AND uf.status = 'BLOCKED'")
    List<UserFriend> findBlockedByUser(@Param("user") User user);

    // Arkadaş sayısı
    @Query("SELECT COUNT(uf) FROM UserFriend uf WHERE " +
            "(uf.user = :user OR uf.friend = :user) AND uf.status = 'ACCEPTED'")
    long countFriends(@Param("user") User user);

    // Arkadaş mı kontrol et
    @Query("SELECT COUNT(uf) > 0 FROM UserFriend uf WHERE " +
            "((uf.user = :user1 AND uf.friend = :user2) OR (uf.user = :user2 AND uf.friend = :user1)) " +
            "AND uf.status = 'ACCEPTED'")
    boolean areFriends(@Param("user1") User user1, @Param("user2") User user2);

    // Engelli mi kontrol et
    @Query("SELECT COUNT(uf) > 0 FROM UserFriend uf WHERE " +
            "uf.user = :blocker AND uf.friend = :blocked AND uf.status = 'BLOCKED'")
    boolean isBlocked(@Param("blocker") User blocker, @Param("blocked") User blocked);
}
