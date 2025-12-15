package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.WordReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface WordReviewRepository extends JpaRepository<WordReview, Long> {
    
    // Find all reviews for a specific word
    List<WordReview> findByWordIdOrderByReviewDateDesc(Long wordId);
    
    // Find reviews for a word on a specific date
    List<WordReview> findByWordIdAndReviewDate(Long wordId, LocalDate reviewDate);
    
    // Find all reviews for a specific date
    List<WordReview> findByReviewDate(LocalDate reviewDate);
    
    // Find reviews for a word between two dates
    @Query("SELECT wr FROM WordReview wr WHERE wr.word.id = :wordId AND wr.reviewDate BETWEEN :startDate AND :endDate ORDER BY wr.reviewDate DESC")
    List<WordReview> findByWordIdAndReviewDateBetween(@Param("wordId") Long wordId, 
                                                     @Param("startDate") LocalDate startDate, 
                                                     @Param("endDate") LocalDate endDate);
    
    // Check if a word was reviewed on a specific date
    boolean existsByWordIdAndReviewDate(Long wordId, LocalDate reviewDate);
    
    // Count reviews for a word
    long countByWordId(Long wordId);
}
