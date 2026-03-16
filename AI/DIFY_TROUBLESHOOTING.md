# 🛠️ Dify & Docker Troubleshooting Guide

This guide contains emergency procedures for when Dify gets stuck in a loop, the UI freezes with "Running", or the Docker stack needs a hard reset.

## 1. 🔄 Restarting the Dify Stack (Basic)
If Dify is sluggish or behaving strangely, a full restart of the containers often helps.

```bash
# 1. Go to the installation directory
cd /opt/dify/docker

# 2. Stop all containers (removes networks, keeps data)
docker compose down

# 3. Start everything in background
docker compose up -d

# 4. Check if all containers are Up
docker ps
```

---

## 2. 🧹 Clearing Stuck Queues (Redis)
If the AI is "thinking" forever but nothing happens, the task queue in Redis might be clogged with zombie jobs.

```bash
cd /opt/dify/docker

# 1. Flush Redis memory (Safe: only clears active queues/cache)
docker compose exec redis redis-cli FLUSHALL

# 2. Restart the worker to pick up the clean state
docker compose restart worker
```

---

## 3. 🚑 Force-Killing Stuck Workflows (Database)
**Scenario:** The UI shows "Running" forever. You restarted Docker, cleared Redis, and it **still** says "Running".
**Cause:** The status is saved in the PostgreSQL database. We need to manually edit it.

### Step 1: Find the Database Container
```bash
docker ps --format "{{.Names}}" | grep postgres
# Output usually: docker-db_postgres-1
```

### Step 2: Access the Database
```bash
docker exec -it docker-db_postgres-1 psql -U postgres -d dify
```

### Step 3: Kill the Zombies (The Magic SQL)
Inside the `dify=#` prompt, run this command to mark stuck workflows as **failed**:

```sql
-- Fix Stuck Workflows (Running -> Failed)
UPDATE workflow_runs SET status = 'failed' WHERE status = 'running';

-- Fix Stuck Messages (Processing -> Error)
UPDATE messages SET status = 'error', error = 'Force Stopped by Admin' WHERE status = 'processing';
```

### ⚠️ IMPORTANT: Valid Status Codes
Do **NOT** set the status to `'error'` for workflows. Dify only accepts specific status codes.
*   ❌ **Wrong:** `UPDATE workflow_runs SET status = 'error' ...` (Causes UI crash: "error is not a valid WorkflowExecutionStatus")
*   ✅ **Right:** `UPDATE workflow_runs SET status = 'failed' ...`

**Fixing "Invalid Status" Error:**
If you accidentally set it to 'error' and the UI crashed, run this to fix it:
```sql
UPDATE workflow_runs SET status = 'failed' WHERE status = 'error';
```

### Step 4: Exit
```sql
\q
```

---

## 4. 📝 Summary of Commands (Cheat Sheet)
```bash
# Restart Dify
cd /opt/dify/docker && docker compose down && docker compose up -d

# Kill Zombies (One-Liner)
docker exec -it docker-db_postgres-1 psql -U postgres -d dify -c "UPDATE workflow_runs SET status = 'failed' WHERE status = 'running';"
```
