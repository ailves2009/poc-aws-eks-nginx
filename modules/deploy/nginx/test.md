# Отредактируйте deployment
kubectl set resources deployment/nginx-demo -n nginx \
  --requests=cpu=50m,memory=128Mi \
  --limits=cpu=200m,memory=256Mi

# Проверьте
kubectl get deployment nginx-demo -n nginx -o yaml | grep -A 10 "resources:"