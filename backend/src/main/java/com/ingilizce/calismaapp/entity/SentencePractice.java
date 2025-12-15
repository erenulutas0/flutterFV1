package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "sentence_practices")
public class SentencePractice {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String englishSentence;
    
    @Column(columnDefinition = "TEXT")
    private String turkishTranslation;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DifficultyLevel difficulty;
    
    @Column(name = "created_date")
    private LocalDate createdDate;
    
    // Constructors
    public SentencePractice() {
        this.createdDate = LocalDate.now();
    }
    
    public SentencePractice(String englishSentence, String turkishTranslation, DifficultyLevel difficulty) {
        this.englishSentence = englishSentence;
        this.turkishTranslation = turkishTranslation;
        this.difficulty = difficulty;
        this.createdDate = LocalDate.now();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getEnglishSentence() {
        return englishSentence;
    }
    
    public void setEnglishSentence(String englishSentence) {
        this.englishSentence = englishSentence;
    }
    
    public String getTurkishTranslation() {
        return turkishTranslation;
    }
    
    public void setTurkishTranslation(String turkishTranslation) {
        this.turkishTranslation = turkishTranslation;
    }
    
    public DifficultyLevel getDifficulty() {
        return difficulty;
    }
    
    public void setDifficulty(DifficultyLevel difficulty) {
        this.difficulty = difficulty;
    }
    
    public LocalDate getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(LocalDate createdDate) {
        this.createdDate = createdDate;
    }
    
    // Enum for difficulty levels
    public enum DifficultyLevel {
        EASY("Kolay"),
        MEDIUM("Orta"),
        HARD("Zor");
        
        private final String displayName;
        
        DifficultyLevel(String displayName) {
            this.displayName = displayName;
        }
        
        public String getDisplayName() {
            return displayName;
        }
    }
}
