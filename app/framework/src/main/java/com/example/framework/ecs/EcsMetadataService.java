package com.example.framework.ecs;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for retrieving ECS container and task metadata.
 */
@Service
public class EcsMetadataService {

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public EcsMetadataService(HttpClient httpClient, ObjectMapper objectMapper) {
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
    }

    /**
     * Check if running in ECS environment.
     *
     * @return true if ECS metadata endpoint is available
     */
    public boolean isRunningInEcs() {
        String metadataUri = System.getenv("ECS_CONTAINER_METADATA_URI_V4");
        return metadataUri != null && !metadataUri.isEmpty();
    }

    /**
     * Get ECS metadata including container and task information.
     *
     * @return map containing ECS metadata
     */
    public Map<String, Object> getMetadata() {
        Map<String, Object> metadata = new HashMap<>();

        String metadataUri = System.getenv("ECS_CONTAINER_METADATA_URI_V4");

        if (metadataUri == null || metadataUri.isEmpty()) {
            metadata.put("available", false);
            metadata.put("message", "Not running in ECS (ECS_CONTAINER_METADATA_URI_V4 not found)");
            return metadata;
        }

        try {
            JsonNode containerMeta = fetchMetadata(metadataUri);
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
