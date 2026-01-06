package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_friends", indexes = {
        @Index(name = "idx_friend_user", columnList = "user_id"),
        @Index(name = "idx_friend_friend", columnList = "friend_id")
}, uniqueConstraints = {
        @UniqueConstraint(columnNames = { "user_id", "friend_id" })
})
public class UserFriend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "friend_id", nullable = false)
    private User friend;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private FriendStatus status = FriendStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "blocked_at")
    private LocalDateTime blockedAt;

    @Column(name = "block_reason", length = 200)
    private String blockReason;

    // Constructors
    public UserFriend() {
        this.createdAt = LocalDateTime.now();
    }

    public UserFriend(User user, User friend) {
        this();
        this.user = user;
        this.friend = friend;
    }

    // Business Methods
    public void accept() {
        this.status = FriendStatus.ACCEPTED;
        this.acceptedAt = LocalDateTime.now();
    }

    public void block(String reason) {
        this.status = FriendStatus.BLOCKED;
        this.blockedAt = LocalDateTime.now();
        this.blockReason = reason;
    }

    public void unblock() {
        this.status = FriendStatus.ACCEPTED;
        this.blockedAt = null;
        this.blockReason = null;
    }

    public void reject() {
        this.status = FriendStatus.REJECTED;
    }

    // Enum
    public enum FriendStatus {
        PENDING("Beklemede"),
        ACCEPTED("Kabul Edildi"),
        REJECTED("Reddedildi"),
        BLOCKED("Engellendi");

        private final String displayName;

        FriendStatus(String displayName) {
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

    public User getFriend() {
        return friend;
    }

    public void setFriend(User friend) {
        this.friend = friend;
    }

    public FriendStatus getStatus() {
        return status;
    }

    public void setStatus(FriendStatus status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    public void setAcceptedAt(LocalDateTime acceptedAt) {
        this.acceptedAt = acceptedAt;
    }

    public LocalDateTime getBlockedAt() {
        return blockedAt;
    }

    public void setBlockedAt(LocalDateTime blockedAt) {
        this.blockedAt = blockedAt;
    }

    public String getBlockReason() {
        return blockReason;
    }

    public void setBlockReason(String blockReason) {
        this.blockReason = blockReason;
    }
}
