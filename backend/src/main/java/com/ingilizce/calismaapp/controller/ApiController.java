package com.ingilizce.calismaapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ApiController {
    
    @GetMapping
    public Map<String, Object> getApiInfo() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "English Learning App API");
        response.put("version", "1.0.0");
        response.put("endpoints", Map.of(
            "words", "/api/words",
            "sentences", "/api/sentences",
            "reviews", "/api/reviews"
        ));
        return response;
    }
}

