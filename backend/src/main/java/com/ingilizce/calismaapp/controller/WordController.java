package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.Word;
import com.ingilizce.calismaapp.dto.CreateWordRequest;
import com.ingilizce.calismaapp.service.WordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Map;

@RestController
@RequestMapping("/api/words")
public class WordController {
    
    @Autowired
    private WordService wordService;
    
    @GetMapping
    public List<Word> getAllWords() {
        return wordService.getAllWords();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Word> getWordById(@PathVariable Long id) {
        Optional<Word> word = wordService.getWordById(id);
        return word.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/{id}/sentences")
    public ResponseEntity<List<com.ingilizce.calismaapp.entity.Sentence>> getWordSentences(@PathVariable Long id) {
        Optional<Word> word = wordService.getWordById(id);
        if (word.isPresent()) {
            return ResponseEntity.ok(word.get().getSentences());
        }
        return ResponseEntity.notFound().build();
    }
    
    @GetMapping("/date/{date}")
    public List<Word> getWordsByDate(@PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return wordService.getWordsByDate(date);
    }
    
    @GetMapping("/dates")
    public List<LocalDate> getAllDistinctDates() {
        return wordService.getAllDistinctDates();
    }
    
    @GetMapping("/range")
    public List<Word> getWordsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return wordService.getWordsByDateRange(startDate, endDate);
    }
    
    @PostMapping
    public Word createWord(@RequestBody Word word) {
        return wordService.saveWord(word);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Word> updateWord(@PathVariable Long id, @RequestBody Word wordDetails) {
        Word updatedWord = wordService.updateWord(id, wordDetails);
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWord(@PathVariable Long id) {
        wordService.deleteWord(id);
        return ResponseEntity.ok().build();
    }
    
    // Sentence management endpoints
    @PostMapping("/{wordId}/sentences")
    public ResponseEntity<Word> addSentence(@PathVariable Long wordId, @RequestBody Map<String, String> request) {
        String sentence = request.get("sentence");
        String translation = request.get("translation");
        String difficulty = request.get("difficulty");
        
        Word updatedWord = wordService.addSentence(wordId, sentence, translation, difficulty);
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }
    
    @DeleteMapping("/{wordId}/sentences/{sentenceId}")
    public ResponseEntity<Word> deleteSentence(@PathVariable Long wordId, @PathVariable Long sentenceId) {
        Word updatedWord = wordService.deleteSentence(wordId, sentenceId);
        if (updatedWord != null) {
            return ResponseEntity.ok(updatedWord);
        }
        return ResponseEntity.notFound().build();
    }
}
