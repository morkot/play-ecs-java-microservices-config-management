package com.example.framework.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import java.net.http.HttpClient;

/**
 * Auto-configuration for ECS microservices framework.
 * Provides common beans used across services.
 */
@Configuration
@ComponentScan(basePackages = {
        "com.example.framework.ssm",
        "com.example.framework.ecs"
})
public class FrameworkAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public HttpClient httpClient() {
        return HttpClient.newBuilder().build();
    }

    @Bean
    @ConditionalOnMissingBean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
