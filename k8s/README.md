# K8s Basic - The Complete Go & Kubernetes Masterclass: Building the Order Mall

<br>

---

<br>

This guide takes you from raw Go code to a fully orchestrated, internally networked, and observable microservice architecture running locally on Kubernetes.

<br>

## Prerequisites

Ensure you have the following installed:

* __Go__ (v1.23+)
* __Docker Desktop__
* __kind__ (`brew install kind`)
* __kubectl__ (`brew install kubectl`)
* __k9s__ (`brew install k9s`)

<br>
<br>

| Phase | Milestone | Core K8s Concept to Learn | Mall Project Action Item |
|------|-----------|---------------------------|--------------------------|
| 1 | Containerization | Docker, Container Images | Write dummy Go code for order-api and product-api. Write Dockerfiles for both using multi-stage builds. |
| 2 | The Local Cluster | Nodes, Control Plane | Install kind (Kubernetes in Docker) and spin up a local development cluster. |
| 3 | Compute & Scaling | Pods, Deployments, ReplicaSets | Write deployment.yaml files to run your Go containers. Try scaling the order-api to 3 replicas. |
| 4 | Internal Networking | Services, DNS | Write service.yaml files. Learn how the order-api can call the product-api using its internal DNS name. |
| 5 | State & Storage | PersistentVolumes, StatefulSets | Deploy PostgreSQL to the cluster. Attach a persistent volume so data survives a pod restart. |
| 6 | Configuration | ConfigMaps, Secrets | Move your Postgres connection strings out of your Go code and into K8s Secrets. Inject them as environment variables. |
| 7 | External Access | Ingress, NodePort | Set up an Ingress controller to expose your mall APIs to your local browser (e.g., localhost/api/orders). |
| 8 | Oberserve with k9s | k8s management without command |

<br>
<br>

## Phase 1: Containerization (The Go Microservices)

We will build two services: a product-api (catalog) and an order-api (checkout) that communicates with the product service.

### 1. The Product API

Create a directory named product-api.

`product-api/main.go`

```go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/products/", func(w http.ResponseWriter, r *http.Request) {
		// Log environment variables to prove K8s injected our DB/Cache secrets later
		log.Printf("DB_USER: %s, REDIS_HOST: %s", os.Getenv("DB_USER"), os.Getenv("REDIS_HOST"))
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"id": "1", "name": "Mechanical Keyboard", "price": 120.50})
		log.Println("Served product data.")
	})

	fmt.Println("Product API running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

`product-api/Dockerfile`

```dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o product-api main.go

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/product-api .
EXPOSE 8080
CMD ["./product-api"]
```

<br>
<br>

### 2. The Order API


Create a directory named `order-api`.

`order-api/main.go`

```go
package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/orders", func(w http.ResponseWriter, r *http.Request) {
		// Communicate via Kubernetes internal DNS ("product-api")
		resp, err := http.Get("http://product-api:8080/products/1")
		if err != nil {
			http.Error(w, "Failed to reach Product API", http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		w.WriteHeader(http.StatusCreated)
		fmt.Fprintf(w, "Order created! Product verified: %s\n", string(body))
	})

	fmt.Println("Order API running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

<br>

`order-api/Dockerfile`

```dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o order-api main.go

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/order-api .
EXPOSE 8080
CMD ["./order-api"]
```

<br>
<br>

---

<br>
<br>

## Phase 2: The Local Cluster (`kind`) -> kind is "K8s in Docker"

### 1. Create the Cluster:

```Bash
kind create cluster --name order-mall
Build Docker Images:
```

### 2. Build Docker Images:
```Bash
docker build -t product-api:v1 ./product-api
docker build -t order-api:v1 ./order-api
Load Images into the Cluster:
```

### 3. Load Images into the Cluster:
```Bash
kind load docker-image product-api:v1 --name order-mall
kind load docker-image order-api:v1 --name order-mall
```

<br>
<br>

---

<br>
<br>

## Phase 3 & 4: Compute & Networking (Deployments & Services)

Create a directory named `k8s`.

`k8s/product.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-api
  template:
    metadata:
      labels:
        app: product-api
    spec:
      containers:
      - name: api
        image: product-api:v1
        imagePullPolicy: Never # Crucial for local Kind images
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: product-api
spec:
  selector:
    app: product-api
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

<br>

`k8s/order.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-api
  template:
    metadata:
      labels:
        app: order-api
    spec:
      containers:
      - name: api
        image: order-api:v1
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: order-api
spec:
  selector:
    app: order-api
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

<br>

Apply them:

```bash
kubectl apply -f k8s/product.yaml
kubectl apply -f k8s/order.yaml
```

<br>
<br>

---

<br>
<br>

## Phase 5: State & Caching (PostgreSQL & Redis)

`k8s/postgres.yaml` (Database with Persistent Storage)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: "mall_admin"
        - name: POSTGRES_PASSWORD
          value: "supersecret"
        - name: POSTGRES_DB
          value: "mall_db"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
```

<br>

`k8s/redis.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
```

Apply them:

```bash
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml
```

<br>
<br>

---

<br>
<br>

## Phase 6: Configuration & Secrets

`k8s/config.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_HOST: "postgres"
  REDIS_HOST: "redis"

---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  DB_USER: bWFsbF9hZG1pbg== # base64 for: mall_admin
  DB_PASS: c3VwZXJzZWNyZXQ= # base64 for: supersecret
```

<br>

### Update Deployments to Use Configs:

Edit k8s/product.yaml and k8s/order.yaml to include this inside the containers spec (right under ports):

```yaml
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-credentials
```

Apply updates:

```bash
kubectl apply -f k8s/config.yaml
kubectl apply -f k8s/product.yaml
kubectl apply -f k8s/order.yaml
```

<br>
<br>

---

<br>
<br>

## Phase 7: External Access (Ingress)


### 1. Install NGINX Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

### 2. Create `k8s/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mall-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
      - path: /orders
        pathType: Prefix
        backend:
          service:
            name: order-api
            port:
              number: 8080
      - path: /products
        pathType: Prefix
        backend:
          service:
            name: product-api
            port:
              number: 8080
```

<br>

### 3. Apply and Test:

```bash
kubectl apply -f k8s/ingress.yaml

# In a separate terminal, forward the Ingress traffic:
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80

# Test your full system!
curl -X POST http://localhost:8080/orders
```

<br>
<br>

---

<br>
<br>

## Phase 8: Master Observability with `k9s`

<br>

`k9s` replaces clunky `kubectl` commands with a fast, Vim-like terminal UI.

### Launch it:

```bash
k9s
```

<br>

### Essential Navigation Commands

* `:pods` - View all running containers.

* `:svc` - View all network services.

* `:deploy` - View deployment statuses.

* `:ing` - View Ingress routing rules.

* `0` - Show resources across ALL namespaces (useful to see NGINX).

* `1` - Show resources in the default namespace only.

<br>
<br>

### Interactive Workflows (Try these!)

#### 1. Shell into Redis (The "Touch" process)

* Type `:pods`.

* Arrow down to highlight your **redis** pod.

* Press `s` to open a shell inside the container.

* Type `redis-cli ping` (You will see **PONG**). Type `exit` to return to k9s.

<br>

#### 2. Live Scaling (Changing Replicas)

* Type `:deploy`.

* Highlight **order-api**.

* Press `e` to edit the live YAML.

* Change `replicas: 1` to `replicas: 3`. Save and exit your text editor.

* Type `:pods` and watch Kubernetes instantly spin up two new instances of your Go application.

<br>

#### 3. Read Live Go Logs

* Type `:pods`.

* Highlight **product-api**.

* Press `l` (lowercase L) to view the live log stream. Hit `curl` on your terminal again to watch the DB/Redis environment variables print out in real-time.

<br>

#### 4. Connect to Postgres Locally

* Type `:svc`.

* Highlight **postgres**.

* Press `Shift + f` to port-forward `5432:5432`.

* You can now open a database tool like DBeaver on your Mac/PC and connect directly to the cluster's database!