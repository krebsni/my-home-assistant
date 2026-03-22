# Home Assistant Docker Setup Guide

Your Home Assistant Docker environment is ready. Follow this guide to complete the setup.

---

## Prerequisites

1. **Docker Desktop** must be installed and running
2. **Zigbee USB dongle** plugged in (optional, for Zigbee devices)
3. **Docker images downloaded** (first pull takes 10-20 minutes)

---

## Step 1: Download Docker Images

The first time you start the containers, Docker needs to download the images. This takes 10-20 minutes depending on your internet speed.

```bash
cd .worktrees/home-assistant-setup
docker compose up -d
```

To watch progress:
```bash
docker compose logs -f
```

To check if images are downloaded:
```bash
docker images | grep -E "homeassistant|mosquitto|zigbee2mqtt|influxdb"
```

---

## Step 2: Find Your MacBook's IP Address

Home Assistant will be accessible at `http://<your-ip>:8123`

**Option A: Via Terminal**
```bash
ipconfig getifaddr en0
```

**Option B: Via System Settings**
1. Click WiFi icon in menu bar
2. Click your network name
3. Note the IP address (e.g., `192.168.1.100`)

---

## Step 3: Access Home Assistant

1. Open a browser
2. Go to: `http://localhost:8123` (on MacBook)
3. Or: `http://<your-ip>:8123` (from phone/other devices on same WiFi)

### First-Time Setup

1. **Create Account**
   - Enter your name
   - Create a username (e.g., `admin`)
   - Create a strong password
   - Click "Create Account"

2. **Name Your Home**
   - Enter a name for your smart home (e.g., "My Home")
   - Set your location (for weather/sunrise features)
   - Click "Next"

3. **Optional: Install Recommended Integrations**
   - Skip for now (we'll add them manually)

4. **You're in!** The Home Assistant dashboard will load.

---

## Step 4: Configure MQTT Integration

MQTT allows Home Assistant to communicate with Zigbee2MQTT.

1. Go to: **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for **MQTT**
4. Configure:
   - **Broker**: `localhost` (or `host.docker.internal` if accessing from phone)
   - **Port**: `1883`
   - Leave other settings as default
5. Click **Submit**

If it doesn't auto-discover, manually add with:
- Broker: `mosquitto`
- Port: `1883`

---

## Step 5: Set Up Zigbee2MQTT

### 5a. Verify Zigbee2MQTT is Running

Open: `http://localhost:8080`

If you see the Zigbee2MQTT interface, it's working!

### 5b. Find Your Zigbee USB Device

If Zigbee2MQTT isn't starting, you may need to update the device path.

```bash
# With Zigbee dongle plugged in, run:
system_profiler SPUSBDataType | grep -i "zigbee\|silicon\|newgreen"

# Also check:
ls -la /dev/tty.*
```

Look for something like:
- `/dev/tty.usbmodemXXX` (common on Mac)
- `/dev/tty.usbserialXXX`

### 5c. Update Configuration

Edit `zigbee2mqtt/data/configuration.yaml`:

```yaml
serial:
  port: /dev/tty.usbmodem123456  # Update this!
```

Restart Zigbee2MQTT:
```bash
docker compose restart zigbee2mqtt
```

### 5d. Pair Zigbee Devices

1. In Zigbee2MQTT web UI (`http://localhost:8080`)
2. Click **Permit join** (top right)
3. Put your Zigbee device in pairing mode
4. Wait for it to appear in the list

**Tips for pairing:**
- Some devices need to be reset (hold button for 10 seconds)
- Check device manual for pairing instructions
- Green light usually means pairing successful

---

## Step 6: Configure InfluxDB

InfluxDB stores sensor history for charts and graphs.

### 6a. Initial Setup

1. Open: `http://localhost:8086`
2. Click **Get Started**
3. Fill in:
   - **Username**: `admin`
   - **Password**: (create a secure password)
   - **Confirm Password**: 
   - **Initial Organization**: `homeassistant`
   - **Initial Bucket**: `sensors`
   - **Flux or InfluxQL**: Select **Flux** (recommended)
4. Click **Continue**

### 6b. Get API Token

1. Click **Load Data** → **API Tokens**
2. Click **Generate API Token** → **Custom API Token**
3. **Description**: `Home Assistant`
4. **Permissions**: 
   - Buckets: Read/Write on `sensors`
5. Click **Save**
6. **Copy and save the token** (you'll need it for Home Assistant)

### 6c. Connect to Home Assistant

1. In Home Assistant: **Settings** → **Devices & Services** → **Add Integration**
2. Search for **InfluxDB**
3. Configure:
   - **Host**: `http://influxdb:8086`
   - **Organization**: `homeassistant`
   - **Token**: (paste your API token)
   - **Bucket**: `sensors`
4. Click **Submit**

---

## Step 7: Access from Phone

1. Connect phone to same WiFi network
2. Open browser
3. Go to: `http://<macbook-ip>:8123`
4. Login with your Home Assistant account

**Tips:**
- Use the IP address, not `localhost`
- Example: `http://192.168.1.100:8123`

---

## Useful Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f homeassistant
docker compose logs -f zigbee2mqtt
docker compose logs -f mosquitto
```

### Restart Services
```bash
docker compose restart
```

### Stop/Start
```bash
docker compose stop
docker compose start
```

### Full Reset
```bash
docker compose down
docker compose up -d
```

### Check Status
```bash
docker compose ps
```

---

## Troubleshooting

### Home Assistant Won't Start

```bash
# Check logs
docker compose logs homeassistant

# Common issues:
# - Port 8123 already in use: Stop other services or change port in docker-compose.yml
# - Permission denied: Check Docker Desktop has necessary permissions
```

### MQTT Not Connecting

```bash
# Check Mosquitto is running
docker compose logs mosquitto

# Test MQTT connection
docker compose exec mosquitto mosquitto_sub -t "test" &
docker compose exec mosquitto mosquitto_pub -t "test" -m "hello"
```

### Zigbee2MQTT Can't Find USB Device

On macOS with Apple Silicon, USB passthrough can be tricky:

1. Make sure Docker Desktop has USB permissions
2. Try using device by path:
   ```yaml
   devices:
     - /dev/tty.usbmodemXXX:/dev/ttyACM0
   ```

### InfluxDB Connection Issues

```bash
# Check InfluxDB logs
docker compose logs influxdb

# Verify network connectivity from Home Assistant container
docker compose exec homeassistant ping influxdb
```

---

## File Locations

| File | Path |
|------|------|
| Docker Compose | `.worktrees/home-assistant-setup/docker-compose.yml` |
| Home Assistant Config | `.worktrees/home-assistant-setup/homeassistant/config/` |
| Mosquitto Config | `.worktrees/home-assistant-setup/mosquitto/config/` |
| Zigbee2MQTT Config | `.worktrees/home-assistant-setup/zigbee2mqtt/data/` |
| InfluxDB Data | `.worktrees/home-assistant-setup/influxdb/` |

---

## Adding WLED (Future)

When you get an ESP32 board for WLED:

1. **Flash WLED firmware** onto ESP32 using [WLED Web Installer](https://install.wled.gg/)
2. **Connect ESP32** to your LED strip
3. **Find ESP32 IP** (displayed on boot or use network scanner)
4. **In Home Assistant**: Settings → Devices & Services → Add Integration → Search "WLED"
5. Enter ESP32 IP address

---

## Next Steps

1. ✅ Start Docker containers
2. ✅ Complete Home Assistant onboarding
3. ✅ Configure MQTT integration
4. ✅ Set up Zigbee2MQTT and pair devices
5. ✅ Configure InfluxDB for history
6. ✅ Access from phone on WiFi
7. 🔲 Explore Home Assistant features
8. 🔲 Add more Zigbee devices
9. 🔲 Add WLED (future - need ESP32 hardware)
