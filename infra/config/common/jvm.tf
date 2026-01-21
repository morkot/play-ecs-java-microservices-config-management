// Common JVM parameters for ALL services in ALL environments
// These define sensible defaults for container memory allocation

locals {
  common_jvm_params = {
    "jvm/opts" = join(" ", [
      "-XX:+UseG1GC",
      "-Xmx384M",
      "-XX:MaxGCPauseMillis=100",
      "-XX:+UseStringDeduplication",
      "-XX:+DisableExplicitGC",
      "-XX:+AlwaysPreTouch",
      "-XX:MetaspaceSize=150m",
      "-XX:MaxMetaspaceSize=200m",
      "-XX:MinMetaspaceFreeRatio=0",
      "-XX:MaxMetaspaceFreeRatio=90",
      "-XX:CompressedClassSpaceSize=50m",
      "-XX:InitialCodeCacheSize=50m",
      "-XX:ReservedCodeCacheSize=100m",
      "-XX:MaxDirectMemorySize=50m",
    ])
  }
}
