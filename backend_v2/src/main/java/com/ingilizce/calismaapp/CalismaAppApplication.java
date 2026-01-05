package com.ingilizce.calismaapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import com.ingilizce.calismaapp.util.SSLUtils;

@SpringBootApplication
@EnableScheduling
public class CalismaAppApplication {

    public static void main(String[] args) {
        // Disable SSL verification for development/testing
        SSLUtils.disableSSLVerification();

        SpringApplication.run(CalismaAppApplication.class, args);
    }

}
