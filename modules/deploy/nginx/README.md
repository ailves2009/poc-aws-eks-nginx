# envs/main/plt/poc/deploy/nginx/README.md
NGINX demo deployment (Deployment + LoadBalancer + HPA)

Содержит манифесты для простого публичного nginx с автоскейлингом подов.

Предварительно (у вас уже установлен Metrics Server):

1) Применить манифесты:

```bash
kubectl apply -f deploy/nginx/nginx-manifests.yaml
```

2) Проверить ресурсы:

```bash
kubectl get deploy nginx-demo
kubectl get svc nginx-demo-lb
kubectl get hpa nginx-demo-hpa
kubectl describe hpa nginx-demo-hpa
kubectl top pods
```

3) Получить внешний адрес (через AWS ELB) и проверить доступность:

```bash
kubectl get svc nginx-demo-lb -o wide
# Пока ELB создаётся, поле .status.loadBalancer.ingress может быть пустым
# Когда появится hostname/IP, откройте в браузере или curl
```

4) Симуляция нагрузки (быстро, из pod):

```bash
kubectl run -i --tty loadgen --image=busybox --rm --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://$(kubectl get svc nginx-demo-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'); sleep 0.05; done"
```

Альтернатива, если LB не создаётся или вы тестируете локально:

```bash
kubectl port-forward svc/nginx-demo-lb 8080:80
# затем открыть http://localhost:8080
```

Примечания:
- HPA использует CPU metrics, поэтому `metrics-server` должен быть установлен в кластере.
- В production вместо Service type=LoadBalancer используйте Ingress (ALB/Gateway API) + TLS (ACM).
