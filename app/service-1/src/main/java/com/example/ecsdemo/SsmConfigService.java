package com.example.ecsdemo;

import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.ssm.SsmClient;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathRequest;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathResponse;
import software.amazon.awssdk.services.ssm.model.Parameter;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for loading and refreshing configuration from AWS SSM Parameter Store.
 * Supports hot reload without application restart.
 */
@Service
public class SsmConfigService {

    private static final String SSM_PROPERTY_SOURCE_NAME = "ssmParameterStore";

    private final ConfigurableEnvironment environment;
    private Instant lastRefreshTime;
    private int lastParameterCount;

    public SsmConfigService(ConfigurableEnvironment environment) {
        this.environment = environment;
    }

    /**
     * Refresh configuration from SSM Parameter Store.
     * @return refresh result with details
     */
    public RefreshResult refresh() {
        String useSsm = environment.getProperty("app.config.use-ssm", "false");
        if (!"true".equalsIgnoreCase(useSsm)) {
            return new RefreshResult(false, "SSM integration disabled", 0, null);
        }

        String parameterPath = environment.getProperty("app.config.ssm.path", "/ecs-config-demo/");

        try {
            Map<String, Object> ssmProperties = loadFromSsm(parameterPath);

            // Remove old SSM property source if exists
            MutablePropertySources propertySources = environment.getPropertySources();
            if (propertySources.contains(SSM_PROPERTY_SOURCE_NAME)) {
                propertySources.remove(SSM_PROPERTY_SOURCE_NAME);
            }

            // Add new SSM property source with highest priority
            MapPropertySource propertySource = new MapPropertySource(SSM_PROPERTY_SOURCE_NAME, ssmProperties);
            propertySources.addFirst(propertySource);

            lastRefreshTime = Instant.now();
            lastParameterCount = ssmProperties.size();

            return new RefreshResult(true, "Configuration refreshed from SSM", ssmProperties.size(), lastRefreshTime);
        } catch (Exception e) {
            return new RefreshResult(false, "Failed to refresh: " + e.getMessage(), 0, null);
        }
    }

    private Map<String, Object> loadFromSsm(String path) {
        Map<String, Object> properties = new HashMap<>();

        try (SsmClient ssmClient = SsmClient.builder().build()) {
            String nextToken = null;

            do {
                GetParametersByPathRequest.Builder requestBuilder = GetParametersByPathRequest.builder()
                        .path(path)
                        .recursive(true)
                        .withDecryption(true);

                if (nextToken != null) {
                    requestBuilder.nextToken(nextToken);
                }

                GetParametersByPathResponse response = ssmClient.getParametersByPath(requestBuilder.build());

                for (Parameter parameter : response.parameters()) {
                    String key = parameter.name().substring(path.length());
                    key = key.replace("/", ".");
                    properties.put(key, parameter.value());
                }

                nextToken = response.nextToken();
            } while (nextToken != null);
        }

        return properties;
    }

    public Instant getLastRefreshTime() {
        return lastRefreshTime;
    }

    public int getLastParameterCount() {
        return lastParameterCount;
    }

    /**
     * Result of a refresh operation
     */
    public record RefreshResult(
            boolean success,
            String message,
            int parameterCount,
            Instant refreshTime
    ) {}
}
