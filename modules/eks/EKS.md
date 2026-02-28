# Requirements for creating EKS VPC:

1. Create VPC (e.g. poc-plt-vpc).
Subnets:

1.1. Create public subnets for internet access via Internet Gateway.
1.2. Create private subnets to host EKS nodes (Worker Nodes) with access to NAT Gateway.
1.3. Internet Gateway must be connected to public subnets.
1.4. NAT Gateway must be connected to public subnets to provide internet access from private subnets.

EKS Cluster:

1. Create an EKS cluster using Terraform.
2. IAM Roles:

Create IAM roles for EKS Cluster and Worker Nodes.
3. Security Groups:

Configure Security Groups for EKS Cluster and Worker Nodes.

# SPOT instances (if needed)
https://aws.amazon.com/blogs/containers/amazon-eks-now-supports-provisioning-and-managing-ec2-spot-instances-in-managed-node-groups/

## Доступ к EKS Control Plane API разрешен только из Private Subnet (через OpenVPN клиента)
inputs = {
  cluster_name    = "poc-plt-eks"
  cluster_version = "1.33"

  endpoint_public_access           = false
  endpoint_private_access          = true
...

### На OpenVPN сервере должен быть добавлен маршрут для клиента:
ubuntu@ip-10-0-4-55:/etc/openvpn$ cat server.conf
proto udp
dev tun
topology subnet

...
route 10.9.0.0 255.255.0.0          # Это маршрут на сервере
push "route 10.0.0.0 255.255.0.0"   # а это маршорут для клиента
...

На клиенте после подключения д.б.
% netstat -rn | grep utun8
10/16              10.9.0.1           UGSc                utun8
10.9/16            10.9.255.254       UGSc                utun8
10.9.0.1           10.9.255.254       UH                  utun8

### Так же в SG Control Plane (Cluster security group) дб добавлено разрешение:
eks-cluster-sg-poc-plt-eks-393666524
EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads.
IPv4 HTTPS TCP 443 10.0.4.55/32 (адрес OpenVPN server)


### Так же на OpenVPN сервере надо добавить SNAT/MASQUERADE

Все пакеты от VPN-клиентов подменяются на IP OpenVPN сервера.
Для EC2-ноды это обычный трафик из VPC, и ответ всегда возвращается на OpenVPN сервер.
% sudo iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -d 10.0.0.0/16 -j SNAT --to-source 10.0.4.55 (800255511525)
% sudo iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -d 10.0.0.0/16 -j SNAT --to-source 10.0.4.110 (042666117474)
% sudo iptables -t nat -A POSTROUTING -s 10.86.0.0/20 -d 	172.16.0.0/16 -j SNAT --to-source 172.16.123.16 (875004833186)

#### Проверка маскарадинга:
sudo iptables -t nat -L -n -v
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 3 packets, 268 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 SNAT       0    --  *      *       10.9.0.0/16          10.0.0.0/16          to:10.0.4.110


###  После этого можно проверить доступ к API (Control Plane). WorkerNodes не слушат на 443 порту.
#### Узнать адрес Control Plane:
aws eks describe-cluster --name poc-plt-eks --region me-central-1 --query 'cluster.endpoint' --output text --profile=ae-poc-plt-init
https://9EF2C031E198666B2C3196663A098028.yl4.me-central-1.eks.amazonaws.com

#### Узнать SG ControlPlane:
aws eks describe-cluster --name poc-plt-eks --region me-central-1 --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --profile=ae-poc-plt-init

#### Получить правила SG:
aws ec2 describe-security-groups \
  --group-ids sg-04c8f796eb9863842 \
  --region me-central-1 \
  --profile ae-poc-plt-init \
  --query 'SecurityGroups[].IpPermissions' \
  --output table

#### Проверить доступ к ControlPlane
% nc -vz 9EF2C031E198666B2C3196663A098028.yl4.me-central-1.eks.amazonaws.com 443
Connection to 9EF2C031E198666B2C3196663A098028.yl4.me-central-1.eks.amazonaws.com port 443 [tcp/https] succeeded!
% k get ns
NAME                STATUS   AGE
amazon-cloudwatch   Active   21d
default             Active   92d
kube-node-lease     Active   92d
kube-public         Active   92d
kube-system         Active   92d
poc-plt             Active   92d

## Доступ к WorkerNode
% aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=10.0.3.60" \
  --region me-central-1 \
  --profile ae-poc-plt-init \
  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Groups'
[
    {
        "GroupName": "poc-plt-eks-node-20250724130043451700000004",
        "GroupId": "sg-0f4b3d3465e543cc2"
    }
]

### Получить правила SG
aws ec2 describe-security-groups \
  --group-ids <GroupId> \
  --region me-central-1 \
  --profile ae-poc-plt-init \
  --output table

## Roles in Cluster
### The EBS CSI driver requires AWS API permissions to:
- create/delete EBS volumes
- mount/unmount volumes
- tag volumes
The role is linked to the ServiceAccount through which the driver operates in the cluster
Without the role:
- the driver will not be able to create/mount disks
- persistent volumes will not work in Kubernetes

Is it possible to avoid creating one?
✅ Yes, we can, if:
- you we the EKS managed EBS CSI driver, which already has a built-in IAM role,
- or grant the node IAM role full rights (not recommended)
❌ Not recommended because:
- it violates the least privilege principle
- the driver gets all node rights, not just the required EBS rights
- auditing/security compliance is more complicated


#######
### Authentication & Token Management

**For CLI/Terraform (Human operators):**
```bash
aws eks update-kubeconfig --region eu-west-3 --name poc-plt-eks
# → Stores AWS SigV4 auth in kubeconfig
```

**For Terraform Kubernetes provider:**
```hcl
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}
```

**Why exec auth?** Static tokens expire after 15 minutes. Using `aws eks get-token` ensures fresh tokens for each `terraform apply`.