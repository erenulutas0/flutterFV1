package com.ingilizce.calismaapp.service;

import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.repository.SentencePracticeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class SentencePracticeService {
    
    @Autowired
    private SentencePracticeRepository sentencePracticeRepository;
    
    // Get all sentences
    public List<SentencePractice> getAllSentences() {
        return sentencePracticeRepository.findAllByOrderByCreatedDateDesc();
    }
    
    // Get sentence by ID
    public Optional<SentencePractice> getSentenceById(Long id) {
        return sentencePracticeRepository.findById(id);
    }
    
    // Save a new sentence
    public SentencePractice saveSentence(SentencePractice sentencePractice) {
        return sentencePracticeRepository.save(sentencePractice);
    }
    
    // Update an existing sentence
    public SentencePractice updateSentence(Long id, SentencePractice updatedSentence) {
        Optional<SentencePractice> existingSentence = sentencePracticeRepository.findById(id);
        if (existingSentence.isPresent()) {
            SentencePractice sentence = existingSentence.get();
            sentence.setEnglishSentence(updatedSentence.getEnglishSentence());
            sentence.setTurkishTranslation(updatedSentence.getTurkishTranslation());
            sentence.setDifficulty(updatedSentence.getDifficulty());
            return sentencePracticeRepository.save(sentence);
        }
        return null;
    }
    
    // Delete a sentence
    public boolean deleteSentence(Long id) {
        if (sentencePracticeRepository.existsById(id)) {
            sentencePracticeRepository.deleteById(id);
            return true;
        }
        return false;
    }
    
    // Get sentences by difficulty
    public List<SentencePractice> getSentencesByDifficulty(SentencePractice.DifficultyLevel difficulty) {
        return sentencePracticeRepository.findByDifficultyOrderByCreatedDateDesc(difficulty);
    }
    
    // Get sentences by date
    public List<SentencePractice> getSentencesByDate(LocalDate date) {
        return sentencePracticeRepository.findByCreatedDateOrderByCreatedDateDesc(date);
    }
    
    // Get all distinct dates
    public List<LocalDate> getAllDistinctDates() {
        return sentencePracticeRepository.findDistinctCreatedDates();
    }
    
    // Get sentences by date range
    public List<SentencePractice> getSentencesByDateRange(LocalDate startDate, LocalDate endDate) {
        return sentencePracticeRepository.findByDateRange(startDate, endDate);
    }
    
    // Get statistics
    public long getTotalSentenceCount() {
        return sentencePracticeRepository.count();
    }
    
    public long getSentenceCountByDifficulty(SentencePractice.DifficultyLevel difficulty) {
        return sentencePracticeRepository.countByDifficulty(difficulty);
    }
}


