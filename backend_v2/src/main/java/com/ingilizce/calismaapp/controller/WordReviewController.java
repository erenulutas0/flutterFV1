package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.entity.WordReview;
import com.ingilizce.calismaapp.service.WordReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
public class WordReviewController {
    
    @Autowired
    private WordReviewService wordReviewService;
    
    // Add a review for a word
    @PostMapping("/words/{wordId}")
    public ResponseEntity<WordReview> addReview(
            @PathVariable Long wordId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate reviewDate,
            @RequestParam(required = false) String reviewType,
            @RequestParam(required = false) String notes) {
        
        try {
            WordReview review = wordReviewService.addReview(wordId, reviewDate, reviewType, notes);
            return ResponseEntity.ok(review);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    // Get all reviews for a word
    @GetMapping("/words/{wordId}")
    public ResponseEntity<List<WordReview>> getWordReviews(@PathVariable Long wordId) {
        List<WordReview> reviews = wordReviewService.getWordReviews(wordId);
        return ResponseEntity.ok(reviews);
    }
    
    // Get reviews for a specific date
    @GetMapping("/date/{date}")
    public ResponseEntity<List<WordReview>> getReviewsByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<WordReview> reviews = wordReviewService.getReviewsByDate(date);
        return ResponseEntity.ok(reviews);
    }
    
    // Check if a word was reviewed on a specific date
    @GetMapping("/words/{wordId}/check/{date}")
    public ResponseEntity<Boolean> isWordReviewedOnDate(
            @PathVariable Long wordId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        boolean isReviewed = wordReviewService.isWordReviewedOnDate(wordId, date);
        return ResponseEntity.ok(isReviewed);
    }
    
    // Get review count for a word
    @GetMapping("/words/{wordId}/count")
    public ResponseEntity<Long> getReviewCount(@PathVariable Long wordId) {
        long count = wordReviewService.getReviewCount(wordId);
        return ResponseEntity.ok(count);
    }
    
    // Get review dates for a word
    @GetMapping("/words/{wordId}/dates")
    public ResponseEntity<List<LocalDate>> getReviewDates(@PathVariable Long wordId) {
        List<LocalDate> dates = wordReviewService.getReviewDates(wordId);
        return ResponseEntity.ok(dates);
    }
    
    // Get review summary for a word
    @GetMapping("/words/{wordId}/summary")
    public ResponseEntity<Map<LocalDate, WordReview>> getReviewSummary(@PathVariable Long wordId) {
        Map<LocalDate, WordReview> summary = wordReviewService.getReviewSummary(wordId);
        return ResponseEntity.ok(summary);
    }
    
    // Delete a review
    @DeleteMapping("/{reviewId}")
    public ResponseEntity<Void> deleteReview(@PathVariable Long reviewId) {
        wordReviewService.deleteReview(reviewId);
        return ResponseEntity.ok().build();
    }
    
    // Delete review for a word on a specific date
    @DeleteMapping("/words/{wordId}/date/{date}")
    public ResponseEntity<Void> deleteReviewByWordAndDate(
            @PathVariable Long wordId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        wordReviewService.deleteReviewByWordAndDate(wordId, date);
        return ResponseEntity.ok().build();
    }
}
