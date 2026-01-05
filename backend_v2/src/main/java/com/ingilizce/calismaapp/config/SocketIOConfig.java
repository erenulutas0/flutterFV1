package com.ingilizce.calismaapp.config;

import com.corundumstudio.socketio.SocketIOServer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SocketIOConfig {

    @Bean
    public SocketIOServer socketIOServer() {
        com.corundumstudio.socketio.Configuration config = new com.corundumstudio.socketio.Configuration();
        config.setHostname("0.0.0.0");
        config.setPort(9092);

        // CORS ayarları Socket.IO için de gerekli olabilir, ancak genelde istemci
        // tarafında handled edilir.
        // Gerekirse origin ayarı eklenebilir.

        return new SocketIOServer(config);
    }
}
