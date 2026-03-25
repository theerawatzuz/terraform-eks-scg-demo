alb_controller_iam_role_arn = "arn:aws:iam::030635936907:role/thebrainsurf-eks-aws-load-balancer-controller"
alb_controller_service_account = "kube-system/aws-load-balancer-controller"
cluster_access_instructions = <<EOT
To configure kubectl access to the cluster, run:

aws eks update-kubeconfig --name thebrainsurf-eks --region ap-southeast-1 --profile default

Then verify access with:

kubectl get nodes
kubectl get pods -A

EOT
cluster_endpoint = "https://5954832E77C1618478675ACFD87B90C6.gr7.ap-southeast-1.eks.amazonaws.com"
cluster_id = "thebrainsurf-eks"
cluster_name = "thebrainsurf-eks"
cluster_oidc_issuer_url = "https://oidc.eks.ap-southeast-1.amazonaws.com/id/5954832E77C1618478675ACFD87B90C6"
cluster_role_arn = "arn:aws:iam::030635936907:role/thebrainsurf-eks-cluster-role"
cluster_version = "1.32"
cost_optimization_summary = <<EOT
Cost Optimization Configuration:

- NAT Gateway: Single NAT Gateway (saves ~$32/month per additional NAT)
- Node Instance Type: t3.small (2 vCPU, 2GB RAM)
- Node Count: Min=1, Desired=1, Max=3
- Node Storage: 20GB gp3 volumes
- Control Plane Logging: Disabled

Estimated Monthly Cost: $150-166

To reduce costs further:

- Scale down nodes during off-hours
- Use Spot instances for non-production workloads
- Monitor and right-size node instance types based on actual usage

EOT
domain_name = "thebrainsurf.site"
ebs_csi_driver_role_arn = "arn:aws:iam::030635936907:role/thebrainsurf-eks-ebs-csi-driver-role"
kubectl_config_command = "aws eks update-kubeconfig --name thebrainsurf-eks --region ap-southeast-1 --profile default"
nat_gateway_ids = [
"nat-04bacac8ce20187cd",
]
node_role_arn = "arn:aws:iam::030635936907:role/thebrainsurf-eks-node-role"
oidc_provider_arn = "arn:aws:iam::030635936907:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/5954832E77C1618478675ACFD87B90C6"
private_subnet_ids = [
"subnet-021859a49d84a535f",
"subnet-038f379c7f0f876e1",
]
public_subnet_ids = [
"subnet-066e3afa3ab5cc02c",
"subnet-072e341a6124107e2",
]
tls_setup_instructions = <<EOT
Self-Signed TLS Certificate Setup:

1. Generate the certificate:
   ./scripts/gen-cert.sh

2. Apply the TLS secret to Kubernetes:
   kubectl apply -f tls-secret.yaml

3. Get the ALB DNS name after deploying an Ingress:
   kubectl get ingress <ingress-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

4. Create a CNAME record in Cloudflare pointing \*.thebrainsurf.site to the ALB DNS name
   (Proxy status: DNS only)

EOT
vpc_cidr = "10.0.0.0/16"
vpc_id = "vpc-0c7f2e35781466f1f"

kubectl get pods
NAME STATUS ROLES AGE VERSION
ip-10-0-10-210.ap-southeast-1.compute.internal Ready <none> 22m v1.32.12-eks-f69f56f
ip-10-0-11-97.ap-southeast-1.compute.internal Ready <none> 22m v1.32.12-eks-f69f56f

❯ kubectl get pods -n kube-system | grep -E "(coredns|ebs)"
coredns-68bb4d6745-q7w6w 1/1 Running 0 21m
coredns-68bb4d6745-z6crg 1/1 Running 0 21m
ebs-csi-controller-785dbbb7f9-hwvfh 6/6 Running 0 21m
ebs-csi-controller-785dbbb7f9-qpdq6 6/6 Running 0 21m
ebs-csi-node-896hm 3/3 Running 0 21m
ebs-csi-node-h9mt4 3/3 Running 0 21m

kubectl get pods -A
NAMESPACE NAME READY STATUS RESTARTS AGE
kube-system aws-load-balancer-controller-86dd84fdd9-5mrpc 1/1 Running 0 19m
kube-system aws-load-balancer-controller-86dd84fdd9-mkcv9 1/1 Running 0 19m
kube-system aws-node-mjm9c 2/2 Running 0 22m
kube-system aws-node-s5qx6 2/2 Running 0 22m
kube-system coredns-68bb4d6745-q7w6w 1/1 Running 0 21m
kube-system coredns-68bb4d6745-z6crg 1/1 Running 0 21m
kube-system ebs-csi-controller-785dbbb7f9-hwvfh 6/6 Running 0 21m
kube-system ebs-csi-controller-785dbbb7f9-qpdq6 6/6 Running 0 21m
kube-system ebs-csi-node-896hm 3/3 Running 0 21m
kube-system ebs-csi-node-h9mt4 3/3 Running 0 21m
kube-system kube-proxy-86xtf 1/1 Running 0 22m
kube-system kube-proxy-d4skb 1/1 Running 0 22m
