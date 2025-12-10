package com.example.ecsdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class EcsConfigDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(EcsConfigDemoApplication.class, args);
    }
}

@RestController
class ConfigController {

    @Value("${app.name:ecs-config-demo}")
    private String appName;

    @Value("${app.environment:local}")
    private String environment;

    @Value("${app.version:1.0.0}")
    private String version;

    @Value("${app.feature.flag:false}")
    private String featureFlag;

    @Value("${app.config.source:properties-file}")
    private String configSource;

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public ConfigController(HttpClient httpClient, ObjectMapper objectMapper) {
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/api/config")
    public Map<String, Object> getConfig() {
        Map<String, Object> response = new HashMap<>();

        // Application configuration
        Map<String, String> appConfig = new HashMap<>();
        appConfig.put("name", appName);
        appConfig.put("environment", environment);
        appConfig.put("version", version);
        appConfig.put("featureFlag", featureFlag);
        appConfig.put("configSource", configSource);

        response.put("application", appConfig);
        response.put("ecsMetadata", getEcsMetadata());

        return response;
    }

    @GetMapping("/api/health")
    public Map<String, String> health() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "UP");
        health.put("application", appName);
        health.put("environment", environment);
        return health;
    }

    private Map<String, Object> getEcsMetadata() {
        Map<String, Object> metadata = new HashMap<>();

        String metadataUri = System.getenv("ECS_CONTAINER_METADATA_URI_V4");

        if (metadataUri == null || metadataUri.isEmpty()) {
            metadata.put("available", false);
            metadata.put("message", "Not running in ECS (ECS_CONTAINER_METADATA_URI_V4 not found)");
            return metadata;
        }

        try {
            // Fetch container metadata
            JsonNode containerMeta = fetchMetadata(metadataUri);

            // Fetch task metadata
            JsonNode taskMeta = fetchMetadata(metadataUri + "/task");

            metadata.put("available", true);
            metadata.put("containerArn", containerMeta.path("ContainerARN").asText());
            metadata.put("containerName", containerMeta.path("Name").asText());
            metadata.put("imageName", containerMeta.path("Image").asText());
            metadata.put("taskArn", taskMeta.path("TaskARN").asText());
            metadata.put("taskFamily", taskMeta.path("Family").asText());
            metadata.put("taskRevision", taskMeta.path("Revision").asText());
            metadata.put("cluster", taskMeta.path("Cluster").asText());
            metadata.put("availabilityZone", taskMeta.path("AvailabilityZone").asText());

        } catch (Exception e) {
            metadata.put("available", false);
            metadata.put("error", e.getMessage());
        }

        return metadata;
    }

    private JsonNode fetchMetadata(String uri) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(uri))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request,
                HttpResponse.BodyHandlers.ofString());

        return objectMapper.readTree(response.body());
    }
}

@Configuration
class AppConfig {
    @Bean
    public HttpClient httpClient() {
        return HttpClient.newBuilder().build();
    }

    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
