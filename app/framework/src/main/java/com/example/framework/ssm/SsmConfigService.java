package com.example.framework.ssm;

import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;

/**
 * Service for refreshing configuration from AWS SSM Parameter Store at runtime.
 * Supports hot reload without application restart.
 */
@Service
public class SsmConfigService {

    private final ConfigurableEnvironment environment;
    private Instant lastRefreshTime;
    private int lastParameterCount;

    public SsmConfigService(ConfigurableEnvironment environment) {
        this.environment = environment;
    }

    /**
     * Refresh configuration from SSM Parameter Store.
     *
     * @return refresh result with details
     */
    public RefreshResult refresh() {
        String useSsm = environment.getProperty("app.config.use-ssm", "false");
        if (!"true".equalsIgnoreCase(useSsm)) {
            return new RefreshResult(false, "SSM integration disabled", 0, null);
        }

        String parameterPath = environment.getProperty("app.config.ssm.path", "/app/");

        try {
            Map<String, Object> ssmProperties = SsmParameterLoader.loadFromPath(parameterPath);

            MutablePropertySources propertySources = environment.getPropertySources();
            if (propertySources.contains(SsmPropertySourceLoader.SSM_PROPERTY_SOURCE_NAME)) {
                propertySources.remove(SsmPropertySourceLoader.SSM_PROPERTY_SOURCE_NAME);
            }

            MapPropertySource propertySource = new MapPropertySource(
                    SsmPropertySourceLoader.SSM_PROPERTY_SOURCE_NAME, ssmProperties);
            propertySources.addFirst(propertySource);

            lastRefreshTime = Instant.now();
            lastParameterCount = ssmProperties.size();

            return new RefreshResult(true, "Configuration refreshed from SSM", ssmProperties.size(), lastRefreshTime);
        } catch (Exception e) {
            return new RefreshResult(false, "Failed to refresh: " + e.getMessage(), 0, null);
        }
    }

    public Instant getLastRefreshTime() {
        return lastRefreshTime;
    }

    public int getLastParameterCount() {
        return lastParameterCount;
    }

    /**
     * Result of a refresh operation.
     */
    public record RefreshResult(
            boolean success,
            String message,
            int parameterCount,
            Instant refreshTime
    ) {}
}
