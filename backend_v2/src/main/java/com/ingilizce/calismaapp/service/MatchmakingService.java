package com.ingilizce.calismaapp.service;

import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class MatchmakingService {

    // Kullanıcıları bekleyen kuyruk
    private final Queue<String> waitingQueue = new LinkedList<>();

    // Aktif eşleşmeler: userId -> matchedUserId
    private final Map<String, String> activeMatches = new ConcurrentHashMap<>();

    // Eşleşme bilgileri: roomId -> {user1, user2}
    private final Map<String, MatchInfo> matchRooms = new ConcurrentHashMap<>();

    // Heartbeat takibi: userId -> lastHeartbeatTime
    private final Map<String, Long> userHeartbeats = new ConcurrentHashMap<>();

    // Kuyruk giriş zamanları: userId -> joinTime
    private final Map<String, Long> queueJoinTimes = new ConcurrentHashMap<>();

    // Timeout süreleri (milisaniye)
    private static final long QUEUE_TIMEOUT_MS = 60000; // 60 saniye kuyruk timeout
    private static final long HEARTBEAT_TIMEOUT_MS = 15000; // 15 saniye heartbeat timeout

    public static class MatchInfo {
        public String user1;
        public String user2;
        public String roomId;
        public long createdAt;

        public MatchInfo(String user1, String user2, String roomId) {
            this.user1 = user1;
            this.user2 = user2;
            this.roomId = roomId;
            this.createdAt = System.currentTimeMillis();
        }
    }

    /**
     * Kullanıcı heartbeat günceller
     */
    public void updateHeartbeat(String userId) {
        userHeartbeats.put(userId, System.currentTimeMillis());
    }

    /**
     * Kullanıcının kuyrukta bekleme süresini döndürür (saniye)
     */
    public long getWaitingTime(String userId) {
        Long joinTime = queueJoinTimes.get(userId);
        if (joinTime == null)
            return 0;
        return (System.currentTimeMillis() - joinTime) / 1000;
    }

    /**
     * Kullanıcının kuyruk timeout olup olmadığını kontrol eder
     */
    public boolean isQueueTimedOut(String userId) {
        Long joinTime = queueJoinTimes.get(userId);
        if (joinTime == null)
            return false;
        return (System.currentTimeMillis() - joinTime) > QUEUE_TIMEOUT_MS;
    }

    /**
     * Hayalet kullanıcıları temizler (heartbeat göndermeyen)
     * Her 10 saniyede bir çalışır
     */
    @Scheduled(fixedRate = 10000)
    public synchronized void cleanupStaleUsers() {
        long now = System.currentTimeMillis();
        List<String> staleUsers = new ArrayList<>();

        // Heartbeat timeout olan kullanıcıları bul
        for (Map.Entry<String, Long> entry : userHeartbeats.entrySet()) {
            if ((now - entry.getValue()) > HEARTBEAT_TIMEOUT_MS) {
                staleUsers.add(entry.getKey());
            }
        }

        // Kuyrukta çok uzun bekleyenleri bul
        for (Map.Entry<String, Long> entry : queueJoinTimes.entrySet()) {
            if ((now - entry.getValue()) > QUEUE_TIMEOUT_MS) {
                if (!staleUsers.contains(entry.getKey())) {
                    staleUsers.add(entry.getKey());
                }
            }
        }

        // Hayalet kullanıcıları temizle
        for (String userId : staleUsers) {
            System.out.println("Cleaning up stale user: " + userId);
            leaveQueue(userId);
            userHeartbeats.remove(userId);
            queueJoinTimes.remove(userId);
        }
    }

    /**
     * Kullanıcıyı eşleşme kuyruğuna ekler
     * 
     * @param userId Kullanıcı ID'si
     * @return Eğer eşleşme bulunduysa MatchInfo, yoksa null
     */
    public synchronized MatchInfo joinQueue(String userId) {
        // Heartbeat başlat
        updateHeartbeat(userId);

        // Eğer kullanıcı zaten eşleşmişse, mevcut eşleşmeyi döndür
        if (activeMatches.containsKey(userId)) {
            String matchedUserId = activeMatches.get(userId);
            String roomId = generateRoomId(userId, matchedUserId);
            return matchRooms.get(roomId);
        }

        // Kuyrukta bekleyen biri var mı?
        if (!waitingQueue.isEmpty()) {
            String matchedUserId = waitingQueue.poll();
            queueJoinTimes.remove(matchedUserId); // Kuyruktan çıktı

            String roomId = generateRoomId(userId, matchedUserId);

            MatchInfo match = new MatchInfo(userId, matchedUserId, roomId);
            matchRooms.put(roomId, match);
            activeMatches.put(userId, matchedUserId);
            activeMatches.put(matchedUserId, userId);

            return match;
        }

        // Kuyrukta kimse yoksa, kullanıcıyı kuyruğa ekle
        waitingQueue.offer(userId);
        queueJoinTimes.put(userId, System.currentTimeMillis()); // Kuyruk giriş zamanı
        return null;
    }

    /**
     * Kullanıcıyı kuyruktan çıkarır
     */
    public synchronized void leaveQueue(String userId) {
        waitingQueue.remove(userId);
        activeMatches.remove(userId);
        queueJoinTimes.remove(userId);
        userHeartbeats.remove(userId);

        // Eşleşmeyi temizle
        matchRooms.entrySet()
                .removeIf(entry -> entry.getValue().user1.equals(userId) || entry.getValue().user2.equals(userId));
    }

    /**
     * Eşleşme bilgisini getirir
     */
    public MatchInfo getMatch(String userId) {
        String matchedUserId = activeMatches.get(userId);
        if (matchedUserId == null) {
            return null;
        }

        String roomId = generateRoomId(userId, matchedUserId);
        return matchRooms.get(roomId);
    }

    /**
     * Eşleşmeyi sonlandırır
     */
    public synchronized void endMatch(String userId) {
        String matchedUserId = activeMatches.remove(userId);
        if (matchedUserId != null) {
            activeMatches.remove(matchedUserId);
            String roomId = generateRoomId(userId, matchedUserId);
            matchRooms.remove(roomId);
        }
        userHeartbeats.remove(userId);
    }

    /**
     * Room ID oluşturur (her zaman aynı sırada)
     */
    private String generateRoomId(String user1, String user2) {
        // Alfabetik sıralama ile tutarlı room ID
        String[] users = { user1, user2 };
        Arrays.sort(users);
        return "room_" + users[0] + "_" + users[1];
    }

    /**
     * Kuyruk durumunu getirir
     */
    public int getQueueSize() {
        return waitingQueue.size();
    }

    /**
     * Kullanıcının kuyrukta olup olmadığını kontrol eder
     */
    public boolean isInQueue(String userId) {
        return waitingQueue.contains(userId);
    }
}
