package com.ingilizce.calismaapp.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class PiperTtsService {
    
    @Value("${piper.tts.path:}")
    private String configuredPiperPath;
    
    // --- KRİTİK DEĞİŞİKLİK BURADA ---
    // Modelleri Türkçe karakter sorunu olmaması için C:\piper klasöründen okuyoruz.
    // Docker'da /piper mount point'i kullanılır
    private static final String MODEL_BASE_DIR = System.getProperty("os.name").toLowerCase().contains("windows") 
        ? "C:\\piper" 
        : "/piper"; 
    
    // Klasör yolları olmadan sadece dosya isimleri (Çünkü hepsi C:\piper içinde yan yana)
    private static final String MODEL_LESSAC = "en_US-lessac-medium.onnx";
    private static final String MODEL_AMY = "en_US-amy-medium.onnx";
    private static final String MODEL_ALAN = "en_GB-alan-medium.onnx";
    
    /**
     * Generate speech audio from text using Piper TTS
     * @param text Text to convert to speech
     * @param voice Voice model to use (lessac, amy, alan)
     * @return Base64 encoded WAV audio data
     */
    public String synthesizeSpeech(String text, String voice) {
        try {
            // Select model based on voice
            String modelFile = getModelFile(voice);
            
            // Create temporary output file
            String tempDir = System.getProperty("java.io.tmpdir");
            String outputFile = tempDir + File.separator + UUID.randomUUID().toString() + ".wav";
            
            // Build Piper command - use absolute path for model file
            File modelFileObj = new File(modelFile);
            String absoluteModelPath = modelFileObj.getAbsolutePath();
            
            // Verify model file exists
            if (!modelFileObj.exists()) {
                throw new RuntimeException("Model file not found at SAFE path: " + absoluteModelPath);
            }
            System.out.println("Using SAFE model file: " + absoluteModelPath);
            System.out.println("Model file exists: " + modelFileObj.exists());
            
            String piperPath = findPiperPath();
            System.out.println("Using Piper path: " + piperPath);
            
            ProcessBuilder processBuilder = new ProcessBuilder(
                piperPath,
                "--model", absoluteModelPath,
                "--output_file", outputFile
            );
            
            // Working directory is less important now since we use absolute paths, 
            // but setting it to the model base directory ensures espeak-ng-data is found easily.
            File workingDir = new File(MODEL_BASE_DIR);
            if (workingDir.exists()) {
                processBuilder.directory(workingDir);
            }
            
            processBuilder.redirectErrorStream(true);
            Process process = processBuilder.start();
            
            // Write text to process stdin and explicitly close it
            OutputStream stdin = process.getOutputStream();
            try (BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(stdin, java.nio.charset.StandardCharsets.UTF_8))) {
                writer.write(text);
                writer.flush();
            } finally {
                // Explicitly close stdin to signal end of input
                try {
                    stdin.close();
                } catch (IOException e) {
                    System.err.println("Error closing stdin: " + e.getMessage());
                }
            }
            
            // Read output/error stream in a separate thread to prevent blocking
            StringBuilder output = new StringBuilder();
            final Process finalProcess = process;
            
            Thread outputThread = new Thread(() -> {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(finalProcess.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        output.append(line).append("\n");
                        System.out.println("Piper output: " + line);
                    }
                } catch (IOException e) {
                    System.err.println("Error reading Piper output: " + e.getMessage());
                }
            });
            outputThread.setDaemon(true);
            outputThread.start();
            
            // Wait for process to complete with timeout (30 seconds)
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new RuntimeException("Piper TTS process timed out after 30 seconds");
            }
            
            outputThread.join(5000); // Wait max 5 seconds for output thread
            
            int exitCode = process.exitValue();
            
            if (exitCode != 0) {
                String errorMsg = output.length() > 0 ? output.toString() : "Unknown error (exit code: " + exitCode + ")";
                System.err.println("Piper TTS failed with exit code: " + exitCode);
                System.err.println("Piper output: " + errorMsg);
                throw new RuntimeException("Piper TTS failed: " + errorMsg);
            }
            
            // Read generated audio file
            Path audioPath = Paths.get(outputFile);
            byte[] audioData = Files.readAllBytes(audioPath);
            
            // Clean up temporary file
            Files.deleteIfExists(audioPath);
            
            // Return base64 encoded audio
            return Base64.getEncoder().encodeToString(audioData);
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to synthesize speech: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get model file path based on voice name
     */
    private String getModelFile(String voice) {
        if (voice == null || voice.isEmpty()) {
            voice = "amy"; // Default to amy since it's available
        }
        
        String modelFileName;
        switch (voice.toLowerCase()) {
            case "amy":
                modelFileName = MODEL_AMY;
                break;
            case "alan":
                modelFileName = MODEL_ALAN;
                break;
            case "lessac":
                modelFileName = MODEL_LESSAC;
                break;
            default:
                // Fallback to amy if requested voice not found
                modelFileName = MODEL_AMY;
                break;
        }
        
        // Construct full path: C:\piper + \ + en_US-amy-medium.onnx
        String fullPath = MODEL_BASE_DIR + File.separator + modelFileName;
        
        // Check if file exists, if not fallback to amy
        File modelFile = new File(fullPath);
        if (!modelFile.exists()) {
            System.out.println("Model not found: " + fullPath + ", falling back to amy");
            fullPath = MODEL_BASE_DIR + File.separator + MODEL_AMY;
            modelFile = new File(fullPath);
        }
        
        System.out.println("Selected model path (SAFE - C:\\piper): " + fullPath);
        return fullPath;
    }
    
    /**
     * Find Piper executable path
     */
    private String findPiperPath() {
        // First, try configured path
        if (configuredPiperPath != null && !configuredPiperPath.trim().isEmpty()) {
            String path = configuredPiperPath.trim();
            
            File file = new File(path);
            
            if (file.exists()) {
                return file.getAbsolutePath();
            }
        }
        
        // Try common locations (including our new safe location)
        // Docker'da Linux path'leri, Windows'ta Windows path'leri
        boolean isWindows = System.getProperty("os.name").toLowerCase().contains("windows");
        String[] pathsToTry = isWindows ? new String[]{
            "C:\\piper\\piper.exe", // Windows location
            "piper.exe",
            "piper"
        } : new String[]{
            "/usr/local/bin/piper", // Docker installed location
            "/piper/piper", // Docker mount location (fallback)
            "piper"
        };
        
        for (String path : pathsToTry) {
             File file = new File(path);
            if (file.exists() && file.canExecute()) {
                return file.getAbsolutePath();
            }
             // Check if it's just a command available in PATH
             if (!path.contains(File.separator) && !path.contains("/") && !path.contains("\\")) {
                 return path;
                }
            }
        
        return "piper";
    }
    
    /**
     * Check if Piper TTS is available
     */
    public boolean isAvailable() {
        try {
            String piperPath = findPiperPath();
            System.out.println("Trying Piper path: " + piperPath);
            
            ProcessBuilder processBuilder = new ProcessBuilder(piperPath, "--version");
            processBuilder.redirectErrorStream(true);
            Process process = processBuilder.start();
            
            long startTime = System.currentTimeMillis();
            while (process.isAlive() && (System.currentTimeMillis() - startTime) < 5000) {
                Thread.sleep(100);
            }
            
            if (process.isAlive()) {
                process.destroy();
                return false;
            }
            
            int exitCode = process.exitValue();
            
            // Also check if model file exists in the NEW location
            String amyModelPath = MODEL_BASE_DIR + File.separator + MODEL_AMY;
            File amyModel = new File(amyModelPath);
            boolean modelExists = amyModel.exists();
            
            System.out.println("Piper TTS check - path: " + piperPath + ", exitCode: " + exitCode + ", modelExists: " + modelExists);
            
            return exitCode == 0 && modelExists;
        } catch (Exception e) {
            System.err.println("Piper TTS availability check failed: " + e.getMessage());
            return false;
        }
    }
}