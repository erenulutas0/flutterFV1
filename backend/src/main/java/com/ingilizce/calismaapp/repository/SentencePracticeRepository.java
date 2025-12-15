package com.ingilizce.calismaapp.repository;

import com.ingilizce.calismaapp.entity.SentencePractice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SentencePracticeRepository extends JpaRepository<SentencePractice, Long> {
    
    // Find all sentences ordered by creation date
    List<SentencePractice> findAllByOrderByCreatedDateDesc();
    
    // Find sentences by difficulty level
    List<SentencePractice> findByDifficultyOrderByCreatedDateDesc(SentencePractice.DifficultyLevel difficulty);
    
    // Find sentences by date range
    @Query("SELECT sp FROM SentencePractice sp WHERE sp.createdDate BETWEEN :startDate AND :endDate ORDER BY sp.createdDate DESC")
    List<SentencePractice> findByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // Find sentences by specific date
    List<SentencePractice> findByCreatedDateOrderByCreatedDateDesc(LocalDate date);
    
    // Count sentences by difficulty
    long countByDifficulty(SentencePractice.DifficultyLevel difficulty);
    
    // Get all distinct dates when sentences were created
    @Query("SELECT DISTINCT sp.createdDate FROM SentencePractice sp ORDER BY sp.createdDate DESC")
    List<LocalDate> findDistinctCreatedDates();
}
