package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.SentencePractice;
import com.ingilizce.calismaapp.entity.Sentence;
import com.ingilizce.calismaapp.service.SentencePracticeService;
import com.ingilizce.calismaapp.repository.SentenceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/sentences")
public class SentencePracticeController {
    
    @Autowired
    private SentencePracticeService sentencePracticeService;
    
    @Autowired
    private SentenceRepository sentenceRepository;
    
    // Get all sentences from both tables
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getAllSentences() {
        List<Map<String, Object>> allSentences = new ArrayList<>();
        
        // Get sentences from sentence_practices table
        List<SentencePractice> practiceSentences = sentencePracticeService.getAllSentences();
        System.out.println("Found " + practiceSentences.size() + " practice sentences");
        for (SentencePractice sp : practiceSentences) {
            Map<String, Object> sentenceMap = new HashMap<>();
            sentenceMap.put("id", "practice_" + sp.getId());
            sentenceMap.put("englishSentence", sp.getEnglishSentence());
            sentenceMap.put("turkishTranslation", sp.getTurkishTranslation());
            sentenceMap.put("difficulty", sp.getDifficulty());
            sentenceMap.put("createdDate", sp.getCreatedDate());
            sentenceMap.put("source", "practice");
            allSentences.add(sentenceMap);
        }
        
        // Get sentences from sentences table with word information
        List<Sentence> wordSentences = sentenceRepository.findAllWithWord();
        System.out.println("Found " + wordSentences.size() + " word sentences");
        for (Sentence s : wordSentences) {
            System.out.println("Processing sentence: " + s.getSentence());
            System.out.println("Difficulty: " + s.getDifficulty());
            System.out.println("Word: " + (s.getWord() != null ? s.getWord().getEnglishWord() : "null"));
            System.out.println("Word learned date: " + (s.getWord() != null ? s.getWord().getLearnedDate() : "null"));
            
            Map<String, Object> sentenceMap = new HashMap<>();
            sentenceMap.put("id", "word_" + s.getId());
            sentenceMap.put("englishSentence", s.getSentence()); // Using 'sentence' column from sentences table
            sentenceMap.put("turkishTranslation", s.getTranslation());
            String difficulty = s.getDifficulty();
            if (difficulty == null || difficulty.trim().isEmpty()) {
                difficulty = "easy";
            } else {
                difficulty = difficulty.toLowerCase();
            }
            sentenceMap.put("difficulty", difficulty);
            sentenceMap.put("createdDate", s.getWord() != null ? s.getWord().getLearnedDate() : null); // Use word's learned date
            sentenceMap.put("source", "word");
            // Add word information
            if (s.getWord() != null) {
                sentenceMap.put("word", s.getWord().getEnglishWord());
                sentenceMap.put("wordTranslation", s.getWord().getTurkishMeaning());
                System.out.println("Added word info: " + s.getWord().getEnglishWord() + " - " + s.getWord().getTurkishMeaning());
            } else {
                System.out.println("Word is null for sentence: " + s.getSentence());
            }
            allSentences.add(sentenceMap);
        }
        
        return ResponseEntity.ok(allSentences);
    }
    
    // Get sentence by ID
    @GetMapping("/{id}")
    public ResponseEntity<SentencePractice> getSentenceById(@PathVariable Long id) {
        Optional<SentencePractice> sentence = sentencePracticeService.getSentenceById(id);
        return sentence.map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
    
    // Create a new sentence
    @PostMapping
    public ResponseEntity<SentencePractice> createSentence(@RequestBody SentencePractice sentencePractice) {
        SentencePractice savedSentence = sentencePracticeService.saveSentence(sentencePractice);
        return ResponseEntity.ok(savedSentence);
    }
    
    // Update an existing sentence
    @PutMapping("/{id}")
    public ResponseEntity<SentencePractice> updateSentence(@PathVariable Long id, @RequestBody SentencePractice sentencePractice) {
        SentencePractice updatedSentence = sentencePracticeService.updateSentence(id, sentencePractice);
        if (updatedSentence != null) {
            return ResponseEntity.ok(updatedSentence);
        }
        return ResponseEntity.notFound().build();
    }
    
    // Delete a sentence
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSentence(@PathVariable String id) {
        try {
            System.out.println("Delete request for ID: " + id);
            if (id.startsWith("practice_")) {
                // For practice sentences, extract the numeric ID
                Long numericId = Long.parseLong(id.substring(8)); // Remove "practice_" prefix
                System.out.println("Extracted numeric ID: " + numericId);
                boolean deleted = sentencePracticeService.deleteSentence(numericId);
                System.out.println("Delete result: " + deleted);
                if (deleted) {
                    return ResponseEntity.ok().build();
                }
                return ResponseEntity.notFound().build();
            } else if (id.startsWith("word_")) {
                // For word-related sentences, we need to delete from sentences table
                Long sentenceId = Long.parseLong(id.substring(5)); // Remove "word_" prefix
                System.out.println("Deleting word sentence with ID: " + sentenceId);
                // Delete from sentences table
                sentenceRepository.deleteById(sentenceId);
                System.out.println("Word sentence deleted successfully");
                return ResponseEntity.ok().build();
            } else {
                // Try as numeric ID for backward compatibility
                Long numericId = Long.parseLong(id);
                System.out.println("Trying as numeric ID: " + numericId);
                boolean deleted = sentencePracticeService.deleteSentence(numericId);
                System.out.println("Delete result: " + deleted);
                if (deleted) {
                    return ResponseEntity.ok().build();
                }
                return ResponseEntity.notFound().build();
            }
        } catch (NumberFormatException e) {
            System.out.println("NumberFormatException: " + e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            System.out.println("Exception: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
    
    // Get sentences by difficulty
    @GetMapping("/difficulty/{difficulty}")
    public ResponseEntity<List<SentencePractice>> getSentencesByDifficulty(@PathVariable String difficulty) {
        try {
            SentencePractice.DifficultyLevel difficultyLevel = SentencePractice.DifficultyLevel.valueOf(difficulty.toUpperCase());
            List<SentencePractice> sentences = sentencePracticeService.getSentencesByDifficulty(difficultyLevel);
            return ResponseEntity.ok(sentences);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Get sentences by date
    @GetMapping("/date/{date}")
    public ResponseEntity<List<SentencePractice>> getSentencesByDate(@PathVariable String date) {
        try {
            LocalDate localDate = LocalDate.parse(date);
            List<SentencePractice> sentences = sentencePracticeService.getSentencesByDate(localDate);
            return ResponseEntity.ok(sentences);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Get all distinct dates
    @GetMapping("/dates")
    public ResponseEntity<List<LocalDate>> getAllDistinctDates() {
        List<LocalDate> dates = sentencePracticeService.getAllDistinctDates();
        return ResponseEntity.ok(dates);
    }
    
    // Get sentences by date range
    @GetMapping("/date-range")
    public ResponseEntity<List<SentencePractice>> getSentencesByDateRange(
            @RequestParam String startDate, 
            @RequestParam String endDate) {
        try {
            LocalDate start = LocalDate.parse(startDate);
            LocalDate end = LocalDate.parse(endDate);
            List<SentencePractice> sentences = sentencePracticeService.getSentencesByDateRange(start, end);
            return ResponseEntity.ok(sentences);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Get statistics from both tables
    @GetMapping("/stats")
    public ResponseEntity<Object> getStatistics() {
        // Count from sentence_practices table
        long practiceTotal = sentencePracticeService.getTotalSentenceCount();
        long practiceEasy = sentencePracticeService.getSentenceCountByDifficulty(SentencePractice.DifficultyLevel.EASY);
        long practiceMedium = sentencePracticeService.getSentenceCountByDifficulty(SentencePractice.DifficultyLevel.MEDIUM);
        long practiceHard = sentencePracticeService.getSentenceCountByDifficulty(SentencePractice.DifficultyLevel.HARD);
        
        // Count from sentences table with actual difficulty
        long wordTotal = sentenceRepository.count();
        long wordEasy = sentenceRepository.countByDifficulty("easy");
        long wordMedium = sentenceRepository.countByDifficulty("medium");
        long wordHard = sentenceRepository.countByDifficulty("hard");
        
        // Combine statistics
        long totalCount = practiceTotal + wordTotal;
        long easyCount = practiceEasy + wordEasy;
        long mediumCount = practiceMedium + wordMedium;
        long hardCount = practiceHard + wordHard;
        
        return ResponseEntity.ok(new Object() {
            public final long total = totalCount;
            public final long easy = easyCount;
            public final long medium = mediumCount;
            public final long hard = hardCount;
        });
    }
}


