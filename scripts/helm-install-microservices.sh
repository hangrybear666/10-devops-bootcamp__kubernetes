#!/bin/bash

helm install -f helm/microservices/values/checkoutservice.yaml checkoutservice helm/microservices/
helm install -f helm/microservices/values/adservice.yaml adservice helm/microservices/
helm install -f helm/microservices/values/frontend.yaml frontend helm/microservices/
helm install -f helm/microservices/values/paymentservice.yaml paymentservice helm/microservices/
helm install -f helm/microservices/values/productcatalogservice.yaml productcatalogservice helm/microservices/
helm install -f helm/microservices/values/recommendationservice.yaml recommendationservice helm/microservices/
helm install -f helm/microservices/values/currencyservice.yaml currencyservice helm/microservices/
helm install -f helm/microservices/values/cartservice.yaml cartservice helm/microservices/
helm install -f helm/microservices/values/shippingservice.yaml shippingservice helm/microservices/
helm install -f helm/microservices/values/emailservice.yaml emailservice helm/microservices/
helm install -f helm/microservices/values/redis-cart.yaml redis-cart helm/microservices/
