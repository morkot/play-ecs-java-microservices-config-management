package com.example.ecsdemo;

import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.ssm.SsmClient;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathRequest;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathResponse;
import software.amazon.awssdk.services.ssm.model.Parameter;

import java.util.HashMap;
import java.util.Map;

/**
 * Custom property source that loads configuration from AWS SSM Parameter Store.
 * Add this to META-INF/spring.factories for automatic loading:
 *
 * org.springframework.context.ApplicationListener=\
 * com.example.ecsdemo.SsmPropertySourceLoader
 */
public class SsmPropertySourceLoader implements ApplicationListener<ApplicationEnvironmentPreparedEvent> {

    private static final String SSM_PROPERTY_SOURCE_NAME = "ssmParameterStore";

    @Override
    public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        ConfigurableEnvironment environment = event.getEnvironment();

        // Check if SSM configuration should be loaded
        String useSsm = environment.getProperty("app.config.use-ssm", "false");
        if (!"true".equalsIgnoreCase(useSsm)) {
            System.out.println("SSM Parameter Store integration disabled");
            return;
        }

        String parameterPath = environment.getProperty("app.config.ssm.path", "/ecs-config-demo/");

        System.out.println("Loading configuration from SSM Parameter Store: " + parameterPath);

        try {
            Map<String, Object> ssmProperties = loadFromSsm(parameterPath);
            MapPropertySource propertySource = new MapPropertySource(SSM_PROPERTY_SOURCE_NAME, ssmProperties);
            environment.getPropertySources().addFirst(propertySource);

            System.out.println("Successfully loaded " + ssmProperties.size() + " parameters from SSM");
        } catch (Exception e) {
            System.err.println("Failed to load SSM parameters: " + e.getMessage());
            // Don't fail startup, fall back to properties file
        }
    }

    private Map<String, Object> loadFromSsm(String path) {
        Map<String, Object> properties = new HashMap<>();

        // SDK auto-detects region from AWS_REGION env var (set by ECS) or instance metadata
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
}
