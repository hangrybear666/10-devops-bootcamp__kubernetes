#!/bin/bash

helm uninstall checkoutservice
helm uninstall adservice
helm uninstall frontend
helm uninstall paymentservice
helm uninstall productcatalogservice
helm uninstall recommendationservice
helm uninstall currencyservice
helm uninstall cartservice
helm uninstall shippingservice
helm uninstall emailservice
helm uninstall redis-cart 