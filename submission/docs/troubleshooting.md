# Troubleshooting

Common issues encountered during local development and deployment.

---

## 1. Port already in use

**Error:** `Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use`

**Solution:**

```bash
# Find the process using the port
sudo lsof -i :80

# Kill the process (replace PID with the actual one)
sudo kill -9 <PID>

# Or stop the conflicting service
sudo systemctl stop nginx
```

Then re-run `docker compose up -d`.

---

## 2. Docker daemon not running

**Error:** `Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`

**Solution:**

```bash
# Start the Docker daemon (Linux)
sudo systemctl start docker
sudo systemctl enable docker   # persist across reboots

# Verify
docker info
```

---

## 3. Permission denied

**Error:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**

```bash
# Add your user to the docker group
sudo usermod -aG docker "$USER"

# Apply the group change (log out and back in, or run)
newgrp docker
```

---

## 4. npm install failures

**Error:** `npm ERR! code ENOENT` or packages missing during frontend build.

**Solution:**

- Ensure `package.json` and `package-lock.json` are present.
- Try a clean install:

```bash
cd frontend
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

- If behind a corporate proxy, configure npm:

```bash
npm config set registry https://registry.npmjs.org/
```

---

## 5. EC2 connection refused

**Problem:** Cannot reach the app at `http://<EC2_PUBLIC_IP>`.

**Checklist:**

1. **Security group** — ensure inbound rules allow traffic on ports 80 and 443 from `0.0.0.0/0` (or your IP).
2. **NGINX is running** — `sudo docker compose ps` should show `nginx` as `Up`.
3. **App bound to 0.0.0.0** — verify the backend and frontend listen on `0.0.0.0` (not `127.0.0.1`).
4. **Firewall** — check `sudo iptables -L` or `sudo ufw status`.

---

## 6. ECR authentication errors

**Error:** `denied: Your authorization token has expired. Reauthenticate and try again.`

**Solution:**

Re-authenticate with ECR:

```bash
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

Ensure the AWS CLI is configured with valid credentials:

```bash
aws configure
```

---

## 7. ECS task failures

**Symptom:** ECS tasks exit immediately or fail to start.

**Debug steps:**

1. **Check task logs** in CloudWatch Logs (if configured).
2. **Verify IAM role** — the task execution role must have `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, and `logs:CreateLogStream` / `logs:PutLogEvents`.
3. **Resource limits** — ensure the task definition CPU/memory values are within the cluster's available capacity.
4. **Pull failure** — confirm the ECR repository and tag exist.
5. **Stop then start** — force a new deployment:

```bash
aws ecs update-service \
  --cluster <cluster> \
  --service <service> \
  --force-new-deployment
```
