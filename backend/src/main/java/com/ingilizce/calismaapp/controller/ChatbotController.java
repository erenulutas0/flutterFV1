package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.ChatbotService;
import com.ingilizce.calismaapp.service.WordService;
import com.ingilizce.calismaapp.entity.Word;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/chatbot")
public class ChatbotController {
    
    @Autowired
    private ChatbotService chatbotService;
    
    @Autowired
    private WordService wordService;

    @PostMapping("/generate-sentences")
    public ResponseEntity<Map<String, Object>> generateSentences(@RequestBody Map<String, String> request) {
        String word = request.get("word");
        
        if (word == null || word.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Please provide a word");
            return ResponseEntity.badRequest().body(error);
        }
        
        try {
            String response = chatbotService.generateSentences(word.trim());
            
            // Parse sentences from response
            List<String> sentences = parseSentences(response);
            
            Map<String, Object> result = new HashMap<>();
            result.put("sentences", sentences);
            result.put("count", sentences.size());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to generate sentences: " + e.getMessage());
            return ResponseEntity.internalServerError().body(error);
        }
    }

    @PostMapping("/check-translation")
    public ResponseEntity<Map<String, Object>> checkTranslation(@RequestBody Map<String, String> request) {
        String englishSentence = request.get("englishSentence");
        String userTranslation = request.get("userTranslation");
        
        if (englishSentence == null || userTranslation == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Please provide both English sentence and translation");
            return ResponseEntity.badRequest().body(error);
        }
        
        try {
            // Log the request for debugging
            System.out.println("Checking translation:");
            System.out.println("English: " + englishSentence);
            System.out.println("Turkish: " + userTranslation);
            
            // Combine parameters into a single message for LangChain4j
            // Format: English sentence: [sentence]. User's Turkish translation: [translation]. Check if the translation is correct. Return ONLY a JSON object with isCorrect, correctTranslation, and feedback fields.
            String combinedMessage = "English sentence: " + englishSentence + ". User's Turkish translation: " + userTranslation + ". Check if the translation is correct. Return ONLY a JSON object with isCorrect, correctTranslation, and feedback fields.";
            
            String response = chatbotService.checkTranslation(combinedMessage);
            
            System.out.println("Chatbot response: " + response);
            
            // Parse JSON response
            Map<String, Object> result = parseJsonResponse(response);
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            System.err.println("Error checking translation: " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to check translation: " + e.getMessage());
            error.put("details", e.getClass().getSimpleName());
            return ResponseEntity.internalServerError().body(error);
        }
    }

    private List<String> parseSentences(String response) {
        List<String> sentences = new ArrayList<>();
        
        // Pattern to match numbered sentences: 1) Sentence (Translation)
        Pattern pattern = Pattern.compile("\\d+\\)\\s*(.+?)(?=\\d+\\)|$)", Pattern.DOTALL);
        Matcher matcher = pattern.matcher(response);
        
        while (matcher.find()) {
            String sentence = matcher.group(1).trim();
            if (!sentence.isEmpty()) {
                sentences.add(sentence);
            }
        }
        
        // If no numbered format found, try to split by newlines
        if (sentences.isEmpty()) {
            String[] lines = response.split("\n");
            for (String line : lines) {
                line = line.trim();
                if (!line.isEmpty() && !line.startsWith("ROLE:") && !line.startsWith("TASK:")) {
                    sentences.add(line);
                }
            }
        }
        
        return sentences;
    }

    private Map<String, Object> parseJsonResponse(String response) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Clean response - remove markdown code blocks if present
            response = response.trim();
            response = response.replaceAll("```json", "").replaceAll("```", "").trim();
            
            // Try to extract JSON object
            int jsonStart = response.indexOf("{");
            int jsonEnd = response.lastIndexOf("}") + 1;
            
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
                String jsonStr = response.substring(jsonStart, jsonEnd);
                
                // Parse isCorrect
                Pattern isCorrectPattern = Pattern.compile("\"isCorrect\"\\s*:\\s*(true|false)");
                Matcher isCorrectMatcher = isCorrectPattern.matcher(jsonStr);
                if (isCorrectMatcher.find()) {
                    result.put("isCorrect", Boolean.parseBoolean(isCorrectMatcher.group(1)));
                } else {
                    result.put("isCorrect", false);
                }
                
                // Extract correctTranslation
                Pattern correctPattern = Pattern.compile("\"correctTranslation\"\\s*:\\s*\"([^\"]+)\"");
                Matcher correctMatcher = correctPattern.matcher(jsonStr);
                if (correctMatcher.find()) {
                    result.put("correctTranslation", correctMatcher.group(1));
                } else {
                    result.put("correctTranslation", "");
                }
                
                // Extract feedback
                Pattern feedbackPattern = Pattern.compile("\"feedback\"\\s*:\\s*\"([^\"]+)\"");
                Matcher feedbackMatcher = feedbackPattern.matcher(jsonStr);
                if (feedbackMatcher.find()) {
                    result.put("feedback", feedbackMatcher.group(1));
                } else {
                    result.put("feedback", "Çeviri kontrol edildi.");
                }
            } else {
                // If no JSON found, try to infer from text
                boolean isCorrect = response.toLowerCase().contains("\"isCorrect\":true") || 
                                   response.toLowerCase().contains("doğru") ||
                                   (!response.toLowerCase().contains("incorrect") && 
                                    !response.toLowerCase().contains("yanlış") &&
                                    !response.toLowerCase().contains("\"isCorrect\":false"));
                
                result.put("isCorrect", isCorrect);
                result.put("correctTranslation", "");
                result.put("feedback", response);
            }
        } catch (Exception e) {
            // Fallback
            result.put("isCorrect", false);
            result.put("correctTranslation", "");
            result.put("feedback", "Çeviri kontrol edilemedi: " + e.getMessage());
        }
        
        return result;
    }

    @PostMapping("/save-to-today")
    @SuppressWarnings("unchecked")
    public ResponseEntity<Map<String, Object>> saveToToday(@RequestBody Map<String, Object> request) {
        try {
            String englishWord = (String) request.get("englishWord");
            List<String> meanings = request.get("meanings") != null 
                ? (List<String>) request.get("meanings") 
                : new ArrayList<>();
            List<String> sentences = request.get("sentences") != null 
                ? (List<String>) request.get("sentences") 
                : new ArrayList<>();
            
            if (englishWord == null || englishWord.trim().isEmpty()) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "English word is required");
                return ResponseEntity.badRequest().body(error);
            }
            
            // Create word with today's date
            Word word = new Word();
            word.setEnglishWord(englishWord.trim());
            
            // Combine all meanings into Turkish meaning
            String turkishMeaning = meanings != null && !meanings.isEmpty() 
                ? String.join(", ", meanings) 
                : "";
            word.setTurkishMeaning(turkishMeaning);
            word.setLearnedDate(LocalDate.now());
            word.setDifficulty("medium");
            
            // Save word first
            Word savedWord = wordService.saveWord(word);
            
            // Add sentences if provided
            if (sentences != null && !sentences.isEmpty()) {
                for (String sentenceStr : sentences) {
                    // Parse sentence to extract English and Turkish parts
                    String englishSentence = sentenceStr;
                    String turkishTranslation = "";
                    
                    // Extract Turkish translation from parentheses if present
                    Pattern pattern = Pattern.compile("(.+?)\\s*\\(([^)]+)\\)\\s*$");
                    Matcher matcher = pattern.matcher(sentenceStr);
                    if (matcher.find()) {
                        englishSentence = matcher.group(1).trim();
                        turkishTranslation = matcher.group(2).trim();
                    }
                    
                    wordService.addSentence(
                        savedWord.getId(), 
                        englishSentence, 
                        turkishTranslation, 
                        "medium"
                    );
                }
            }
            
            // Reload word with sentences
            savedWord = wordService.getWordById(savedWord.getId()).orElse(savedWord);
            
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("word", savedWord);
            result.put("message", "Kelime ve cümleler bugünkü tarihe başarıyla eklendi.");
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to save word: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(error);
        }
    }

    @PostMapping("/chat")
    public ResponseEntity<Map<String, Object>> chat(@RequestBody Map<String, String> request) {
        String message = request.get("message");
        
        if (message == null || message.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Please provide a message");
            return ResponseEntity.badRequest().body(error);
        }
        
        try {
            String response = chatbotService.chat(message.trim());
            
            Map<String, Object> result = new HashMap<>();
            result.put("response", response);
            result.put("timestamp", System.currentTimeMillis());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            System.err.println("Error in chat: " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to get response: " + e.getMessage());
            return ResponseEntity.internalServerError().body(error);
        }
    }
}

