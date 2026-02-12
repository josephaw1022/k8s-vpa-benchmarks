# General Instructions for VPA Autoscaling Repo Agent

This file contains high-level instructions for the AI agent working in this repository.

## Operational Rules

### 1. STRICT: Use Taskfile
-   **ALWAYS** use the tasks defined in `Taskfile.yml` for operations. Use `task --list-all` to see available tasks that you can run.
-   **DO NOT** run shell scripts (e.g., `./setup.sh`) directly unless absolutely necessary and no task exists.
-   **DO NOT** run `kubectl` commands directly unless standard tasks do not cover the specific operation required.
-   **Check Taskfiles First**: Before proposing a command, read the `Taskfile.yml` to see if a relevant task exists.


## Cluster Management
-   **Verification First**: Before suggesting `kubectl` commands, always check if the Kind cluster is running (`kind get clusters`).
-   **Safe Teardown**: Use `task cleanup` to remove the cluster.

## VPA Analysis
-   **Metrics First**: Status of `metrics-server` is critical for VPA. Always verify it is running if VPA is behaving unexpectedly.
