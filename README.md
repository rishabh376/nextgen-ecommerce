# Next‑Gen E‑Commerce on Azure AKS 🛒⚡️

A production‑grade, AI‑assisted, event‑driven e‑commerce platform built for scale on Azure Kubernetes Service (AKS). Multi‑region active‑active, sub‑second APIs, autoscaling, spot savings, and full observability.

[![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS_1.29-326ce5?logo=kubernetes&logoColor=white)](https://learn.microsoft.com/azure/aks/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform)](https://developer.hashicorp.com/terraform)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Azure%20Pipelines-2560E0?logo=azurepipelines&logoColor=white)](https://azure.microsoft.com/services/devops/pipelines/)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%7C%20RBAC%20%7C%20NetPols-0b8235)](#-security--compliance)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Highlights: 1M+ daily txns, 99.99% uptime (active‑active), 35% cost savings with spot/AS, AI forecasting pipeline, PCI‑ready patterns.

---

<img alt="Storefront Screenshot" src="docs/screenshots/storefront.png" width="920">
<!-- Temporary placeholder (remove once you add real screenshots):
<img alt="Storefront Screenshot" src="https://via.placeholder.com/1400x800?text=Storefront" width="920">
-->

## 🔗 Quick Links

- Live (Front Door): https://YOUR_FRONTDOOR_DEFAULT_DOMAIN/  ↗
- API: https://api.yourdomain.com/  ↗
- Shop: https://shop.yourdomain.com/  ↗
- Grafana: port‑forward or publish via Helm (see Observability)
- Architecture: [below](#-architecture)

## ✨ What you get

- Event‑driven microservices: cart, inventory, orders, payments (Stripe), gateway, recommendations (FastAPI), nightly forecasting job
- Multi‑region AKS with Front Door active‑active, Cosmos DB multi‑write, Service Bus Premium
- Secure secrets via Azure Key Vault CSI, zero‑trust defaults (RBAC, restricted PSP, NetworkPolicies)
- Observability out of the box: Prometheus + Grafana, metrics endpoints, ServiceMonitors
- Autoscaling: HPA on services, KEDA on Service Bus queue, spot node pool for cost savings
- One‑clickish deploy via Azure DevOps (Terraform infra + Docker builds + kubectl/Helm rollout)

---

## 🧭 Architecture

```mermaid
flowchart LR
  U[User/Browser] --> FD[Azure Front Door]
  FD --> IN[NGINX Ingress (AKS)]
  IN --> FE[Frontend (Next.js)]
  IN --> GW[Gateway (BFF)]

  GW --> INV[Inventory Service]
  GW --> CART[Cart Service]
  GW --> ORD[Orders Service]
  FE -->|/api/*| GW

  ORD -- payment request --> SBQ[Service Bus: payment-requests]
  PAY[Payments Service] -- consume --> SBQ
  PAY -- result --> SBR[Service Bus: payment-results]
  ORD -- subscribe --> SBR

  subgraph Data
    COSMOS[(Cosmos DB)]
    REDIS[(Redis Cache)]
  end

  CART --- COSMOS
  INV --- COSMOS
  ORD --- COSMOS
  GW --- REDIS

  REC[Recommendation (FastAPI)]:::dim
  FJ[Forecasting CronJob]:::dim --> COSMOS

  classDef dim fill:#f0f0f0,stroke:#999,color:#666