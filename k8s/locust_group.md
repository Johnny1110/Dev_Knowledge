# Distributed Load Testing with Locust on Kubernetes

<br>

To ensure our Order Mall can handle high traffic, we need to stress-test our microservices. Locust is a modern, Python-based load-testing tool. By deploying it inside our Kubernetes cluster, we can leverage a **Master-Worker** architecture to generate massive, distributed simulated traffic.



In this phase, we will containerize a custom Locust test suite and deploy a distributed testing cluster consisting of **1 Master** (to serve the UI and aggregate metrics) and **3 Workers** (to execute the actual HTTP requests).

<br>

## Step 1: The Locust Project Files

Create a new directory named `locust-project` and add the following three files. These files define the test logic, dependencies, and how to package them into a Docker image.

### `requirements.txt`
Specifies the Locust version to ensure consistency.
```text
locust==2.33.0
```

### `locustfile.py`
This Python script defines the behavior of our simulated users. It hits the endpoints we exposed via our Ingress controller.
```python
import os
from locust import HttpUser, task, between

class MallUser(HttpUser):
    # Base URL for the Ingress routing
    host = "http://my-mall.local"
    
    # Each simulated user waits randomly between 1 to 2 seconds after a task
    wait_time = between(1, 2)

    @task(2)
    def get_products(self):
        """Simulate browsing the product catalog"""
        self.client.get("/products/1")

    @task(1)
    def create_order(self):
        """Simulate checkout / creating an order"""
        self.client.post("/orders")
```

### `Dockerfile`
We use the official Locust image as a base and inject our custom test script.
```dockerfile
FROM locustio/locust:2.33.0

# Switch to working directory
WORKDIR /mnt/locust

# Copy dependencies and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the load testing script
COPY locustfile.py .

# Expose ports for Web UI (8089) and Master-Worker communication (5557)
EXPOSE 8089 5557
```

<br>

---

<br>

## Step 2: Build and Load the Image

Since we are using `kind` (Kubernetes in Docker), the cluster cannot automatically see images built on your local machine. We must build the image and explicitly load it into the cluster's nodes.

Execute these commands in the terminal where your Dockerfile is located:

```bash
# 1. Build the Docker image locally
docker build -t locust-project:v1 .

# 2. Load the image into the kind cluster (Replace 'order-mall' if your cluster name differs)
kind load docker-image locust-project:v1 --name order-mall
```

<br>

---

<br>

## Step 3: Kubernetes Deployment Manifests & Networking Hack

Create a file named `k8s/locust.yaml`. This manifest defines the internal networking for Locust and spins up both the Master and Worker deployments. 

> **🚨 Crucial Networking Detail (`hostAliases`)**:
> Since our Locust workers are running *inside* the cluster, they do not use your computer's local `/etc/hosts` file. If they try to hit `http://my-mall.local`, they will get a DNS resolution error. To fix this, we use Kubernetes `hostAliases` to manually map the domain to the NGINX Ingress Controller's internal IP.

First, find your Ingress Controller's internal Cluster-IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
# Look for the CLUSTER-IP column (e.g., 10.96.x.x)
```

Now, write your `k8s/locust.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: locust-master
spec:
  selector:
    app: locust-master
  ports:
    - name: web
      port: 8089
      targetPort: 8089
    - name: communication
      port: 5557
      targetPort: 5557
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: locust-master
  template:
    metadata:
      labels:
        app: locust-master
    spec:
      containers:
        - name: master
          image: locust-project:v1
          imagePullPolicy: Never # Forces K8s to use the local image we loaded via kind
          args: ["--master", "-f", "locustfile.py"]
          ports:
            - containerPort: 8089
            - containerPort: 5557
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: locust-worker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: locust-worker
  template:
    metadata:
      labels:
        app: locust-worker
    spec:
      # Inject custom DNS resolution directly into the Pod's /etc/hosts
      hostAliases:
        - ip: "10.96.x.x" # <<-- REPLACE THIS WITH YOUR NGINX INGRESS CLUSTER-IP
          hostnames:
            - "my-mall.local"
      containers:
        - name: worker
          image: locust-project:v1
          imagePullPolicy: Never
          args: ["--worker", "--master-host=locust-master", "-f", "locustfile.py"]
```

<br>

---

<br>

## Step 4: Deploy and Execute the Test

### 1. Apply the Manifests
Deploy the Locust cluster into your Kubernetes environment:
```bash
kubectl apply -f k8s/locust.yaml
```

Verify that 1 Master pod and 3 Worker pods are running:
```bash
kubectl get pods -l "app in (locust-master, locust-worker)"
```

### 2. Access the Locust Web UI
To interact with the Master node from your local browser, establish a port-forward tunnel:
```bash
kubectl port-forward svc/locust-master 8089:8089
```

### 3. Start the Swarm
1. Open your browser and navigate to **http://localhost:8089**.
2. Notice that the **Workers** counter in the top right shows `3`.
3. Set **Number of users** (e.g., `100`).
4. Set **Spawn rate** (e.g., `10` users per second).
5. The **Host** field will be pre-filled with `http://my-mall.local` from your script.
6. Click **Start swarming** and watch the real-time statistics and graphs as the 3 worker pods unleash traffic onto your cluster!

> **💡 Pro Tip: Scaling the Load**
> If your API handles the load too easily, you can dynamically add more workers without stopping the test! Simply scale the deployment:
> `kubectl scale deployment locust-worker --replicas=10`
> The Locust Master will automatically detect the new workers and distribute the load accordingly.