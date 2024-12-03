# IB Gateway Helm Chart

Ce chart Helm permet de déployer Interactive Brokers Gateway sur Kubernetes avec une interface graphique accessible via navigateur web.

## Prérequis

- Kubernetes 1.19+
- Helm 3+
- Un compte Interactive Brokers
- Un gestionnaire de stockage configuré dans votre cluster (StorageClass)

## Installation

### 1. Préparation des secrets

Créez d'abord les secrets nécessaires pour les credentials IB :

```bash
./scripts/creer_secret_ib.sh trading ib-gateway-secrets VOTRE_USERNAME VOTRE_PASSWORD
```

### 2. Configuration

Modifiez le fichier `values.yaml` selon vos besoins. Les paramètres principaux sont :

```yaml
namespace:
  name: "trading"  # Namespace pour le déploiement

ibgateway:
  mode: "paper"    # "paper" ou "live"
  timezone: "Europe/Paris"

persistence:
  enabled: true
  size: "1Gi"
  storageClass: "local-path"  # Adaptez selon votre cluster
```

### 3. Installation du chart

```bash
# Créer le namespace si nécessaire
kubectl create namespace trading

# Installer le chart
helm install ib-gateway . -n trading
```

## Accès à l'interface graphique

### Via navigateur web (Recommandé)
1. Obtenez l'IP externe du service :
   ```bash
   kubectl get svc ib-gateway -n trading
   ```
2. Accédez à l'interface via : `http://<EXTERNAL-IP>:6080/vnc.html`

### Via client VNC
- Connectez-vous à : `<EXTERNAL-IP>:5900`
- Mot de passe par défaut : `myVNCpass` (configurable dans values.yaml)

## Structure des ports

- 4001 : Port TWS Gateway
- 4002 : Port API
- 5900 : Port VNC
- 6080 : Interface Web (noVNC)

## Surveillance et logs

### Consulter les logs

```bash
# Logs du pod
kubectl logs -f -n trading $(kubectl get pods -n trading -l app=ib-gateway -o jsonpath='{.items[0].metadata.name}')

# Logs spécifiques via supervisor
kubectl exec -it -n trading $(kubectl get pods -n trading -l app=ib-gateway -o jsonpath='{.items[0].metadata.name}') -- tail -f /var/log/ibgateway.log
```

### Statut des composants

```bash
kubectl exec -it -n trading $(kubectl get pods -n trading -l app=ib-gateway -o jsonpath='{.items[0].metadata.name}') -- supervisorctl status
```

## Configuration avancée

### Sécurité réseau

Pour restreindre l'accès, configurez les IPs autorisées dans `values.yaml` :

```yaml
security:
  allowedIPs:
    - "192.168.1.0/24"
    - "10.0.0.0/8"
```

### Ressources

Ajustez les ressources selon vos besoins :

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

## Dépannage

### Problèmes courants

1. **Pod en CrashLoopBackOff**
   ```bash
   kubectl describe pod -n trading $(kubectl get pods -n trading -l app=ib-gateway -o jsonpath='{.items[0].metadata.name}')
   ```

2. **Impossible d'accéder à l'interface**
   - Vérifiez le statut du