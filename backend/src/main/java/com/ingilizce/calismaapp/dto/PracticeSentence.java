package com.ingilizce.calismaapp.dto;

/**
 * Practice sentence DTO for structured output from LLM
 */
public record PracticeSentence(
    String englishSentence,  // İngilizce cümle
    String turkishTranslation, // O cümledeki hedef kelime/frazın Türkçe çevirisi (1-3 kelime)
    String turkishFullTranslation // Tüm cümlenin Türkçe çevirisi (nullable for backward compatibility)
) {}


