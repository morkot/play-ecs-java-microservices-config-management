package com.example.service2;

import com.example.framework.ecs.EcsMetadataService;
import com.example.framework.ssm.SsmConfigService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class Service2Application {
    public static void main(String[] args) {
        SpringApplication.run(Service2Application.class, args);
    }
}

@RestController
class ConfigController {

    private final org.springframework.core.env.Environment env;
    private final SsmConfigService ssmConfigService;
    private final EcsMetadataService ecsMetadataService;

    public ConfigController(org.springframework.core.env.Environment env,
                            SsmConfigService ssmConfigService,
                            EcsMetadataService ecsMetadataService) {
        this.env = env;
        this.ssmConfigService = ssmConfigService;
        this.ecsMetadataService = ecsMetadataService;
    }

    @GetMapping("/api/config")
    public Map<String, Object> getConfig() {
        Map<String, Object> response = new HashMap<>();

        Map<String, Object> appConfig = new HashMap<>();
        appConfig.put("name", env.getProperty("app.name", "service-2"));
        appConfig.put("environment", env.getProperty("app.environment", "local"));
        appConfig.put("version", env.getProperty("app.version", "1.0.0"));
        appConfig.put("featureFlag", env.getProperty("app.feature.flag", "false"));

        if (ssmConfigService.getLastRefreshTime() != null) {
            appConfig.put("lastSsmRefresh", ssmConfigService.getLastRefreshTime().toString());
            appConfig.put("ssmParameterCount", ssmConfigService.getLastParameterCount());
        }

        response.put("application", appConfig);
        response.put("ecsMetadata", ecsMetadataService.getMetadata());

        return response;
    }

    @PostMapping("/api/config/refresh")
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
        health.put("application", env.getProperty("app.name", "service-2"));
        health.put("environment", env.getProperty("app.environment", "local"));
        return health;
    }

    @GetMapping("/api/ssm-properties")
    public Map<String, Object> getSsmProperties() {
        return ssmConfigService.getSsmProperties();
    }
}
