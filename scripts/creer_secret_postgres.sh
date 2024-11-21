#!/bin/bash

# Variables
NAMESPACE="trading"
SECRET_NAME="ib-gateway-secrets"  # Doit correspondre à .Values.secret.name dans values.yaml

# Lecture des variables sensibles depuis le fichier .env
IB_ACCOUNT=$(grep IB_ACCOUNT .env | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs)
IB_USERNAME=$(grep IB_USERNAME .env | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs)
IB_PASSWORD=$(grep IB_PASSWORD .env | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs)

# Vérification des variables requises
if [ -z "$IB_ACCOUNT" ] || [ -z "$IB_USERNAME" ] || [ -z "$IB_PASSWORD" ]; then
    echo "❌ Erreur: Toutes les variables requises doivent être définies dans le fichier .env"
    echo "Variables requises:"
    echo "- IB_ACCOUNT"
    echo "- IB_USERNAME"
    echo "- IB_PASSWORD"
    exit 1
fi

# Création du namespace s'il n'existe pas
echo "📁 Création du namespace ${NAMESPACE} si nécessaire..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Création du secret pour IB Gateway
echo "🔒 Création du secret IB Gateway..."
kubectl create secret generic ${SECRET_NAME} \
  -n ${NAMESPACE} \
  --from-literal=account="${IB_ACCOUNT}" \
  --from-literal=username="${IB_USERNAME}" \
  --from-literal=password="${IB_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Vérification du secret
echo "✅ Vérification de la création du secret..."
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}

echo "🎉 Secret créé avec succès !"