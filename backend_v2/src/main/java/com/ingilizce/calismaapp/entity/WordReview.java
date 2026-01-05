package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "word_reviews")
public class WordReview {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne
    @JoinColumn(name = "word_id", nullable = false)
    private Word word;
    
    @Column(name = "review_date", nullable = false)
    private LocalDate reviewDate;
    
    @Column(name = "review_type")
    private String reviewType; // "daily", "weekly", "monthly" etc.
    
    @Column(name = "notes")
    private String notes;
    
    // Constructors
    public WordReview() {}
    
    public WordReview(Word word, LocalDate reviewDate) {
        this.word = word;
        this.reviewDate = reviewDate;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Word getWord() {
        return word;
    }
    
    public void setWord(Word word) {
        this.word = word;
    }
    
    public LocalDate getReviewDate() {
        return reviewDate;
    }
    
    public void setReviewDate(LocalDate reviewDate) {
        this.reviewDate = reviewDate;
    }
    
    public String getReviewType() {
        return reviewType;
    }
    
    public void setReviewType(String reviewType) {
        this.reviewType = reviewType;
    }
    
    public String getNotes() {
        return notes;
    }
    
    public void setNotes(String notes) {
        this.notes = notes;
    }
}
