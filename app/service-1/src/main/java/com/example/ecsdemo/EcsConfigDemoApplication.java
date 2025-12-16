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

    private final org.springframework.core.env.Environment env;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final SsmConfigService ssmConfigService;

    public ConfigController(org.springframework.core.env.Environment env,
                            HttpClient httpClient,
                            ObjectMapper objectMapper,
                            SsmConfigService ssmConfigService) {
        this.env = env;
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
        this.ssmConfigService = ssmConfigService;
    }

    @GetMapping("/api/config")
    public Map<String, Object> getConfig() {
        Map<String, Object> response = new HashMap<>();

        // Application configuration - read from Environment for live updates
        Map<String, Object> appConfig = new HashMap<>();
        appConfig.put("name", env.getProperty("app.name", "ecs-config-demo"));
        appConfig.put("environment", env.getProperty("app.environment", "local"));
        appConfig.put("version", env.getProperty("app.version", "1.0.0"));
        appConfig.put("featureFlag", env.getProperty("app.feature.flag", "false"));
        appConfig.put("configSource", env.getProperty("app.config.source", "properties-file"));

        // Add refresh metadata
        if (ssmConfigService.getLastRefreshTime() != null) {
            appConfig.put("lastSsmRefresh", ssmConfigService.getLastRefreshTime().toString());
            appConfig.put("ssmParameterCount", ssmConfigService.getLastParameterCount());
        }

        response.put("application", appConfig);
        response.put("ecsMetadata", getEcsMetadata());

        return response;
    }

    @org.springframework.web.bind.annotation.PostMapping("/api/config/refresh")
    public Map<String, Object> refreshConfig() {
        SsmConfigService.RefreshResult result = ssmConfigService.refresh();

        Map<String, Object> response = new HashMap<>();
        response.put("success", result.success());
        response.put("message", result.message());
        response.put("parameterCount", result.parameterCount());
        if (result.refreshTime() != null) {
            response.put("refreshTime", result.refreshTime().toString());
        }

        return response;
    }

    @GetMapping("/api/health")
    public Map<String, String> health() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "UP");
        health.put("application", env.getProperty("app.name", "ecs-config-demo"));
        health.put("environment", env.getProperty("app.environment", "local"));
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
