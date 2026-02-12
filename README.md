# VPA Autoscaling Sandbox

A quick-start playground for experimenting with Kubernetes Vertical Pod Autoscaling (VPA) on a local machine.

## Prerequisites
You'll need these installed:
- **Docker** & **Kind** (for the cluster)
- **Helm** (for charts)
- **Taskfile** (for automation)
- **kubectl**

## How to use

1. **Spin up the environment:**
   ```bash
   task setup
   ```
   *Creates a local Kind cluster and installs the Metrics Server + VPA components.*

2. **Deploy the demo app:**
   ```bash
   task example:create
   ```
   *Deploys a test Nginx application with VPA configured.*

3. **Watch it work:**
   Monitor the autoscaler in one terminal:
   ```bash
   kubectl get vpa -n my-app --watch
   ```
   
   Simulate load in another (check `Taskfile.yml` for more options):
   ```bash
   task example:cpu-spike
   ```

4. **Cleanup:**
   ```bash
   task cleanup
   ```
