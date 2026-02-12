# VpaAutoscaling Repository - Gemini Context

## Overview
This repository is a sandbox for experimenting with **Vertical Pod Autoscaling (VPA)** on Kubernetes. It provides a quick and easy way to spin up a local [Kind](https://kind.sigs.k8s.io/) cluster, install the necessary VPA components and Metrics Server, and run a sample application to observe VPA in action.

## Prerequisites
To use this repository effectively, the following tools should be installed:
-   **Task** (`go-task`): For running automation commands.
-   **Kind**: For creating local Kubernetes clusters.
-   **Kubectl**: For interacting with the cluster.
-   **Helm**: For installing VPA and Metrics Server charts.
-   **Docker**: Required by Kind.

## Repsitory Structure
-   **`Taskfile.yml`**: The main entry point for automation. Contains tasks to setup and cleanup the environment.
-   **`setup.sh`**: A shell script that:
    -   Creates a Kind cluster using `kind-config.yaml`.
    -   Installs the Kubernetes Metrics Server (patched for insecure TLS for Kind).
    -   Adds the Autoscaler Helm repo.
    -   Installs the Vertical Pod Autoscaler using Helm.
-   **`kind-config.yaml`**: Kind cluster configuration defining 1 control plane node and 3 worker nodes.
-   **`example/`**: Directory containing a sample application.
    -   **`app.yaml`**: Kubernetes manifests for a test Nginx deployment and its associated VPA configuration.
    -   **`Taskfile.yml`**: Tasks to manage the example app (create, delete) and simulate load (cpu-spike, mem-spike).

## Getting Started

### 1. Setup the Environment
Initialize the Kind cluster and install dependencies:
```bash
task setup
```

### 2. Deploy Example Application
Deploy the sample Nginx application and VPA configuration:
```bash
task example:create
```
This creates a namespace `my-app` and deploys the application.

### 3. Trigger Autoscaling
VPA requires historical metrics to make recommendations. You can simulate load to force scaling recommendations:

*   **CPU Spike**:
    ```bash
    task example:cpu-spike
    ```
    (Runs an infinite loop in the container)

*   **Memory Spike**:
    ```bash
    task example:mem-spike
    ```
    (Writes 100MB to memory)

### 4. Observe VPA
Check the VPA status and recommendations:
```bash
kubectl get vpa -n my-app --watch
kubectl describe vpa my-app-vpa -n my-app
```
Watch the pods to see if they get restarted with new resource limits:
```bash
kubectl get pods -n my-app -w
```

### 5. Cleanup
Remove the Kind cluster:
```bash
task cleanup
```

## detailed Components

### Vertical Pod Autoscaler (VPA)
The VPA configuration in `example/app.yaml` is set to `updateMode: "Auto"`, meaning it will automatically evict and restart pods to apply new resource recommendations.
-   **Min Allowed**: 50m CPU, 64Mi Memory
-   **Max Allowed**: 1 CPU, 1Gi Memory

### Metrics Server
The `setup.sh` script installs the specific version of Metrics Server required for VPA to function. It includes a patch `--kubelet-insecure-tls` which is necessary for Metrics Server to communicate with Kubelets in a Kind environment.
