package com.ingilizce.calismaapp.controller;

import com.ingilizce.calismaapp.service.PiperTtsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/tts")
public class TtsController {
    
    @Autowired
    private PiperTtsService piperTtsService;
    
    @PostMapping("/synthesize")
    public ResponseEntity<?> synthesize(@RequestBody Map<String, String> request) {
        String text = request.get("text");
        String voice = request.get("voice"); 
        
        if (text == null || text.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Text is required");
            return ResponseEntity.badRequest().body(error);
        }
        
        try {
            if (!piperTtsService.isAvailable()) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "Piper TTS is not available.");
                error.put("available", false);
                return ResponseEntity.status(503).body(error);
            }
            
            // Service bize zaten Base64 string veriyor, onu hiç bozmadan JSON'a koyuyoruz.
            // (Eskiden decode edip byte[] yapıyorduk, artık gerek yok)
            String audioBase64 = piperTtsService.synthesizeSpeech(text.trim(), voice);
            
            Map<String, String> response = new HashMap<>();
            response.put("audio", audioBase64); // "audio" anahtarı ile gönderiyoruz
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Failed to synthesize: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(error);
        }
    }
    
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        Map<String, Object> status = new HashMap<>();
        boolean available = piperTtsService.isAvailable();
        status.put("available", available);
        status.put("voices", new String[]{"lessac", "amy", "alan"});
        return ResponseEntity.ok(status);
    }
}