#!/bin/bash

set -euo pipefail

CLUSTER_NAME="booster-production"
REGION="us-east-1"
NODE_COUNT=5

echo "🚀 Setting up Kubernetes cluster: $CLUSTER_NAME"

setup_eks_cluster() {
    echo "Creating EKS cluster..."
    eksctl create cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --nodegroup-name standard-workers \
        --node-type t3.large \
        --nodes $NODE_COUNT \
        --nodes-min 3 \
        --nodes-max 10 \
        --managed

    echo "✓ Cluster created"
}

install_ingress_controller() {
    echo "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml

    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s

    echo "✓ Ingress controller installed"
}

install_cert_manager() {
    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

    kubectl wait --namespace cert-manager \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/instance=cert-manager \
        --timeout=120s

    echo "✓ cert-manager installed"
}

setup_monitoring() {
    echo "Setting up Prometheus and Grafana..."

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace

    echo "✓ Monitoring stack installed"
}

deploy_services() {
    echo "Deploying Booster services..."

    kubectl create namespace production || true

    kubectl apply -f infrastructure/kubernetes/ -n production

    echo "✓ Services deployed"
}

setup_autoscaling() {
    echo "Configuring autoscaling..."

    kubectl apply -f infrastructure/kubernetes/hpa-config.yaml -n production

    echo "✓ Autoscaling configured"
}

main() {
    setup_eks_cluster
    install_ingress_controller
    install_cert_manager
    setup_monitoring
    deploy_services
    setup_autoscaling

    echo ""
    echo "✅ Cluster setup complete!"
    echo "Cluster: $CLUSTER_NAME"
    echo "Region: $REGION"
    echo "Nodes: $NODE_COUNT"
}

main
