package com.example.framework.ssm;

import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.Map;

/**
 * Loads configuration from AWS SSM Parameter Store at application startup.
 * Register via META-INF/spring.factories for automatic loading.
 */
public class SsmPropertySourceLoader implements ApplicationListener<ApplicationEnvironmentPreparedEvent> {

    public static final String SSM_PROPERTY_SOURCE_NAME = "ssmParameterStore";

    @Override
    public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        ConfigurableEnvironment environment = event.getEnvironment();

        String useSsm = environment.getProperty("app.config.use-ssm", "false");
        if (!"true".equalsIgnoreCase(useSsm)) {
            System.out.println("SSM Parameter Store integration disabled");
            return;
        }

        String parameterPath = environment.getProperty("app.config.ssm.path", "/app/");

        System.out.println("Loading configuration from SSM Parameter Store: " + parameterPath);

        try {
            Map<String, Object> ssmProperties = SsmParameterLoader.loadFromPath(parameterPath);
            MapPropertySource propertySource = new MapPropertySource(SSM_PROPERTY_SOURCE_NAME, ssmProperties);
            environment.getPropertySources().addFirst(propertySource);

            System.out.println("Successfully loaded " + ssmProperties.size() + " parameters from SSM");
        } catch (Exception e) {
            System.err.println("Failed to load SSM parameters: " + e.getMessage());
            // Don't fail startup, fall back to properties file
        }
    }
}
