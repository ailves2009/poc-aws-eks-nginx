# modules/alb/README.md

### How to check ALB after deploy
- % k get all -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
NAME  READY   STATUS    RESTARTS   AGE
pod/aws-load-balancer-controller-bc67b9f9d-njxjk 1/1 Running 0 6m35s
pod/aws-load-balancer-controller-bc67b9f9d-qxv2z 1/1 Running 0 6m35s

NAME   TYPE   CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/aws-load-balancer-webhook-service ClusterIP 172.20.244.33 <none> 443/TCP 6m36s

NAME  READY. UP-TO-DATE.  AVAILABLE.  AGE
deployment.apps/aws-load-balancer-controller 2/2. 2. 2. 6m36s

NAME.  DESIRED   CURRENT   READY   AGE
replicaset.apps/aws-load-balancer-controller-bc67b9f9d 2 2 2 6m36s

% helm list -n kube-system
NAME  NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
aws-load-balancer-controller	kube-system	2       	2026-02-26 16:38:53.071847 +0100 CET	deployed	aws-load-balancer-controller-3.0.0	v3.0.0
metrics                     	kube-system	2       	2026-02-26 16:53:08.701092 +0100 CET	deployed	metrics-server-3.13.0             	0.8.0