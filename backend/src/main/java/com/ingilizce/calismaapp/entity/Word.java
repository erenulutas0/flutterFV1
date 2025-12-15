package com.ingilizce.calismaapp.entity;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import java.time.LocalDate;
import java.util.List;
import java.util.ArrayList;

@Entity
@Table(name = "words")
public class Word {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String englishWord;
    
    @Column
    private String turkishMeaning;
    
    @Column(nullable = false)
    private LocalDate learnedDate;
    
    @Column
    private String notes;
    
    @Column
    private String difficulty;
    
    @OneToMany(mappedBy = "word", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @JsonManagedReference
    private List<Sentence> sentences = new ArrayList<>();
    
    // Constructors
    public Word() {}
    
    public Word(String englishWord, String turkishMeaning, LocalDate learnedDate) {
        this.englishWord = englishWord;
        this.turkishMeaning = turkishMeaning;
        this.learnedDate = learnedDate;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getEnglishWord() {
        return englishWord;
    }
    
    public void setEnglishWord(String englishWord) {
        this.englishWord = englishWord;
    }
    
    public String getTurkishMeaning() {
        return turkishMeaning;
    }
    
    public void setTurkishMeaning(String turkishMeaning) {
        this.turkishMeaning = turkishMeaning;
    }
    
    public LocalDate getLearnedDate() {
        return learnedDate;
    }
    
    public void setLearnedDate(LocalDate learnedDate) {
        this.learnedDate = learnedDate;
    }
    
    public String getNotes() {
        return notes;
    }
    
    public void setNotes(String notes) {
        this.notes = notes;
    }
    
    public List<Sentence> getSentences() {
        return sentences;
    }
    
    public void setSentences(List<Sentence> sentences) {
        this.sentences = sentences;
    }
    
    public void addSentence(Sentence sentence) {
        sentences.add(sentence);
        sentence.setWord(this);
    }
    
    public void removeSentence(Sentence sentence) {
        sentences.remove(sentence);
        sentence.setWord(null);
    }
    
    public String getDifficulty() {
        return difficulty;
    }
    
    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }
}
