# Home Assistant Docker Setup - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up a complete Home Assistant Docker environment with MQTT broker, Zigbee2MQTT, and InfluxDB on macOS M3 for local testing and learning.

**Architecture:** Docker Compose with 4 services on a shared network. Home Assistant uses host networking for device discovery. Zigbee dongle passed through USB. InfluxDB stores sensor history.

**Tech Stack:** Docker Compose, Home Assistant, Eclipse Mosquitto, Zigbee2MQTT, InfluxDB 2

---

## File Structure

```
my-home-assistant/
├── docker-compose.yml      # Main compose file with all 4 services
├── .env                    # Environment variables
├── homeassistant/
│   └── config/             # Created on first run
├── mosquitto/
│   ├── config/mosquitto.conf
│   ├── data/               # Created on run
│   └── log/                # Created on run
├── zigbee2mqtt/
│   └── data/
│       ├── configuration.yaml
│       └── secrets.yaml
└── influxdb/
    └── (data stored here)
```

---

## Tasks

### Task 1: Create Directory Structure and Mosquitto Config

**Files:**
- Create: `mosquitto/config/mosquitto.conf`

- [ ] **Step 1: Create directories**

```bash
mkdir -p mosquitto/config mosquitto/data mosquitto/log
mkdir -p zigbee2mqtt/data homeassistant/config influxdb
```

- [ ] **Step 2: Create Mosquitto configuration**

```bash
cat > mosquitto/config/mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
persistence_file mosquitto.db
log_dest file /mosquitto/log/mosquitto.log
EOF
```

- [ ] **Step 3: Commit**

```bash
git add mosquitto/
git commit -m "feat: add mosquitto config"
```

---

### Task 2: Create Zigbee2MQTT Configuration

**Files:**
- Create: `zigbee2mqtt/data/configuration.yaml`
- Create: `zigbee2mqtt/data/secrets.yaml`

- [ ] **Step 1: Create secrets file**

```bash
cat > zigbee2mqtt/data/secrets.yaml << 'EOF'
# Zigbee2MQTT secrets
# Get your Zigbee device path from: system_profiler SPUSBDataType
# Will update after USB identification
EOF
```

- [ ] **Step 2: Create configuration file**

```bash
cat > zigbee2mqtt/data/configuration.yaml << 'EOF'
homeassistant: true
permit_join: true
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
serial:
  port: /dev/serial/by-id/YOUR_ZIGBEE_DEVICE_ID
frontend:
  port: 8080
advanced:
  network_key: GENERATE_LATER
  pan_id: GENERATE_LATER
  channel: 20
```

- [ ] **Step 3: Commit**

```bash
git add zigbee2mqtt/
git commit -m "feat: add zigbee2mqtt config (placeholder device path)"
```

---

### Task 3: Create Docker Compose File

**Files:**
- Create: `docker-compose.yml`
- Create: `.env`

- [ ] **Step 1: Create .env file**

```bash
cat > .env << 'EOF'
TZ=Europe/Berlin
```

- [ ] **Step 2: Create docker-compose.yml**

```bash
cat > docker-compose.yml << 'EOF'
services:
  homeassistant:
    container_name: homeassistant
    image: homeassistant/home-assistant:stable
    ports:
      - "8123:8123"
    volumes:
      - ./homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - TZ=${TZ}
    network_mode: host
    depends_on:
      - mosquitto
    restart: unless-stopped

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    restart: unless-stopped

  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt
    ports:
      - "8080:8080"
      - "8484:8484"
    volumes:
      - ./zigbee2mqtt/data:/app/data
      - /run/udev:/run/udev:ro
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
    environment:
      - TZ=${TZ}
    depends_on:
      - mosquitto
    restart: unless-stopped

  influxdb:
    container_name: influxdb
    image: influxdb:2
    ports:
      - "8086:8086"
    volumes:
      - ./influxdb:/var/lib/influxdb2
    environment:
      - TZ=${TZ}
    restart: unless-stopped

networks: {}
EOF
```

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml .env
git commit -m "feat: add docker-compose with all services"
```

---

### Task 4: Identify Zigbee USB Device and Update Config

**Files:**
- Modify: `zigbee2mqtt/data/configuration.yaml`

- [ ] **Step 1: List USB devices to find Zigbee dongle**

```bash
system_profiler SPUSBDataType | grep -A5 "Zigbee\|ZStack\|Silicon Labs\|Newgreentech\|C3003"
```

Expected output: Look for device with "Newgreentech" or "C3003" or "Silicon Labs" in the name. Note the Vendor ID and Product ID.

- [ ] **Step 2: Try to find device path**

```bash
ls -la /dev/tty.usbmodem* /dev/tty.usbserial* 2>/dev/null || echo "No USB serial devices found"
```

- [ ] **Step 3: Check if /dev/ttyACM0 exists (may need permission)**

```bash
ls -la /dev/ttyACM0 2>/dev/null || echo "ttyACM0 not found (normal on macOS)"
```

- [ ] **Step 4: Update Zigbee2MQTT config with correct port**

If device path found, update `zigbee2mqtt/data/configuration.yaml`:
```yaml
serial:
  port: /dev/ttyACM0  # or discovered path
```

- [ ] **Step 5: Commit**

```bash
git add zigbee2mqtt/data/configuration.yaml
git commit -m "feat: update zigbee2mqtt with device port"
```

---

### Task 5: Start Services and Verify

- [ ] **Step 1: Start Docker Compose (background)**

```bash
docker compose up -d
```

Expected: 4 containers starting

- [ ] **Step 2: Check container status**

```bash
docker compose ps
```

Expected: All 4 containers running

- [ ] **Step 3: Check logs**

```bash
docker compose logs --tail=50
```

Look for errors. If Zigbee device not found, that's OK for now.

- [ ] **Step 4: Verify Home Assistant is accessible**

Open browser: `http://localhost:8123`

If loading, great! If not, check logs.

- [ ] **Step 5: Verify Zigbee2MQTT frontend**

Open browser: `http://localhost:8080`

---

### Task 6: Configure Home Assistant MQTT Integration

- [ ] **Step 1: Get MacBook's local IP**

```bash
ipconfig getifaddr en0
```

Or: System Settings → WiFi → click your network → IP address

- [ ] **Step 2: In Home Assistant browser UI**

1. Go to: `http://localhost:8123` (or `http://<your-ip>:8123`)
2. Complete onboarding (create account)
3. Go to: Settings → Devices & Services → Add Integration
4. Search for "MQTT"
5. Configure:
   - Broker: `mosquitto` (Docker internal name)
   - Port: `1883`
   - Allow FFmpeg: No
6. Submit

- [ ] **Step 3: Commit docker state**

```bash
git add -A
git commit -m "feat: running services - HA configured with MQTT"
```

---

### Task 7: Configure InfluxDB

- [ ] **Step 1: Open InfluxDB setup**

Browser: `http://localhost:8086`

- [ ] **Step 2: Complete initial setup**

1. Get Started
2. Username: `admin`
3. Password: (choose a secure password, save it!)
4. Confirm Password
5. Initial Organization: `homeassistant`
6. Initial Bucket: `sensors`
7. Click "Continue"

- [ ] **Step 3: Get API Token**

1. Go to Load Data → API Tokens
2. Click "Generate API Token" → "Custom API Token"
3. Description: "Home Assistant"
4. Read bucket permissions for `sensors`
5. Copy and save the token (needed for HA config)

- [ ] **Step 4: Add InfluxDB integration to Home Assistant**

1. HA: Settings → Devices & Services → Add Integration
2. Search "InfluxDB"
3. Configure:
   - Host: `http://influxdb:8086`
   - Organization: `homeassistant`
   - Token: (paste your token)
   - Bucket: `sensors`
4. Submit

- [ ] **Step 5: Commit InfluxDB config**

Add to `docker-compose.yml` or create a `.env` with credentials (don't commit real tokens):
```bash
# Create a .env.local file for secrets (add to .gitignore)
cat > .env.local << 'EOF'
INFLUXDB_TOKEN=your_token_here
EOF
```

- [ ] **Step 6: Commit**

```bash
git add .gitignore 2>/dev/null || true
git commit -m "feat: add influxdb token placeholder"
```

---

### Task 8: Create User Setup Guide

**Files:**
- Create: `docs/setup-guide.md`

- [ ] **Step 1: Create comprehensive setup guide**

Document:
- How to find your MacBook's IP
- How to access HA from phone
- How to pair Zigbee devices
- How to check logs
- How to restart services
- Common troubleshooting

- [ ] **Step 2: Commit**

```bash
git add docs/setup-guide.md
git commit -m "docs: add user setup guide"
```

---

## Verification

After all tasks complete, verify:

- [ ] Home Assistant at `http://<ip>:8123`
- [ ] MQTT integration connected in HA
- [ ] Zigbee2MQTT frontend at `http://<ip>:8080`
- [ ] InfluxDB storing sensor data
- [ ] Phone can access HA on local WiFi
- [ ] `docker compose down && up` works cleanly

---

## Troubleshooting Notes

### Zigbee device not found on macOS
macOS doesn't expose `/dev/ttyACM0` like Linux. On M3 MacBooks:
1. Check System Settings → Privacy & Security → Full Disk Access for Docker
2. Try passing device by ID: `ls /dev/tty.*` to find it
3. May need to use `host` network mode for Zigbee2MQTT

### Container won't start
```bash
docker compose logs <container-name>
```

### USB device permission denied
macOS Docker Desktop handles USB differently. If issues persist:
1. Quit Docker Desktop
2. Reconnect USB dongle
3. Restart Docker Desktop
