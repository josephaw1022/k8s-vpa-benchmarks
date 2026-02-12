---
name: debug_vpa
description: Debug Vertical Pod Autoscaler issues by checking metrics, recommender logs, and eviction events.
---

# Debugging Vertical Pod Autoscaler (VPA)

Follow these steps to diagnose issues with VPA not recommending resources or not updating pods.

## 1. Check Metrics Server
VPA relies on the Metrics Server to gather historical usage data. If it's down, VPA won't work.

```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods -A
```
*If `kubectl top` fails or returns "Metrics not available", the Metrics Server is the issue.*

## 2. Check VPA Components
Ensure the VPA recommender, updater, and admission-controller are running.

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=vpa
```

## 3. Inspect VPA Object
Check the VPA object for `Conditions` and `Recommendations`.

```bash
kubectl get vpa -A
kubectl describe vpa <vpa-name> -n <namespace>
```
*Look for `Provided` condition being True. If False, check the `message` field.*

## 4. Check Recommender Logs
If recommendations are missing, check the recommender logs.

```bash
kubectl logs -n kube-system -l app=vpa-recommender
```
*Look for permission errors or "no metrics" warnings.*

## 5. Check Evictions
If recommendations exist but pods aren't updating, check if the VPA Updater is evicting pods.

```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```
*Look for `EvictedByVPA` events.*
