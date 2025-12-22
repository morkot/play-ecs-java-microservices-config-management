package com.example.framework.ssm;

import software.amazon.awssdk.services.ssm.SsmClient;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathRequest;
import software.amazon.awssdk.services.ssm.model.GetParametersByPathResponse;
import software.amazon.awssdk.services.ssm.model.Parameter;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility class for loading parameters from AWS SSM Parameter Store.
 * Handles pagination and path-to-property key conversion.
 */
public class SsmParameterLoader {

    private SsmParameterLoader() {
        // Utility class
    }

    /**
     * Load all parameters from the given SSM path.
     * Parameters are converted from path format (/path/key) to property format (path.key).
     *
     * @param path the SSM parameter path prefix
     * @return map of property keys to values
     */
    public static Map<String, Object> loadFromPath(String path) {
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
}
