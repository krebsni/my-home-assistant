# Home Assistant Docker Setup Specification

## Overview

Set up a local Home Assistant environment using Docker Compose on macOS (Apple Silicon M3) for testing and learning before deploying to a Raspberry Pi. Include Zigbee integration, WLED control, and database persistence.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌───────────┐    ┌────────────────┐  │
│  │     Home     │    │   MQTT    │    │  Zigbee2MQTT   │  │
│  │  Assistant   │◄──►│  Mosquitto│◄──►│                │  │
│  │  :8123       │    │   :1883   │    │  :8080 (zigbee)│  │
│  └──────────────┘    └───────────┘    └───────┬──────────┘  │
│                                               │             │
│  ┌──────────────┐                             │             │
│  │   InfluxDB   │◄── Home Assistant stores    │             │
│  │   :8086      │    sensor history            │             │
│  └──────────────┘                             │             │
│                                              ▼              │
│                  ┌──────────────────────────────┐           │
│                  │  WLED (Future - Hardware)    │           │
│                  │  ESP32 board + LED strips   │           │
│                  │  Controlled via HTTP/WiFi   │           │
│                  └──────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                   USB /dev/ttyACM0
                   (Zigbee Dongle)
```

## Services

### 1. Home Assistant
- **Image**: `homeassistant/home-assistant:stable`
- **Ports**: `8123:8123`
- **Volumes**:
  - `./homeassistant/config:/config` - persistent configuration
  - `/etc/localtime:/etc/localtime:ro` - timezone
  - `/etc/timezone:/etc/timezone:ro` - timezone
- **Network**: `host` mode (required for device discovery)
- **Depends on**: Mosquitto (for MQTT integration)

### 2. Mosquitto MQTT Broker
- **Image**: `eclipse-mosquitto:2`
- **Ports**: `1883:1883`, `9001:9001`
- **Volumes**:
  - `./mosquitto/config:/mosquitto/config` - configuration
  - `./mosquitto/data:/mosquitto/data` - persistence
  - `./mosquitto/log:/mosquitto/log` - logs
- **Config**: Allow anonymous, enable persistence

### 3. Zigbee2MQTT
- **Image**: `koenkk/zigbee2mqtt`
- **Ports**: `8080:8080` (frontend), `8484:8484` (zigbee)
- **Volumes**:
  - `./zigbee2mqtt/data:/app/data` - configuration and database
  - `/run/udev:/run/udev:ro` - device permissions
- **Devices**: USB Zigbee dongle passthrough
- **Environment**: MQTT server connection
- **Depends on**: Mosquitto

### 4. WLED (Hardware Required - Later)
**NOT a Docker service** - WLED is firmware for ESP32/ESP8266 microcontrollers.

- **To add later**: Purchase an ESP32 board (~$5-10), flash WLED firmware onto it
- **Integration**: Connect ESP32 to your LED strips, configure IP in Home Assistant
- **Docker side**: Home Assistant WLED integration connects via HTTP to the ESP32's IP address

### 5. InfluxDB
- **Image**: `influxdb:2`
- **Ports**: `8086:8086`
- **Volumes**: `./influxdb:/var/lib/influxdb2` - persistence
- **Environment**: Initial setup via UI (admin/token creation)

## Network Configuration

- **Access URL**: `http://<macbook-local-ip>:8123`
- **Discovery**: Home Assistant auto-discovers devices on `host` network
- **Phone access**: Connect via same WiFi network using MacBook's IP

## USB Device Setup (macOS)

macOS doesn't expose `/dev/tty*` paths to Docker. Solution:

1. Identify USB device via `system_profiler SPUSBDataType`
2. Pass device by vendor/product ID using `--device` flag
3. For Silicon (M3), use: `--device=/dev/ttyACM0` (if available) or USB device mapping

## File Structure

```
my-home-assistant/
├── docker-compose.yml
├── .env
├── homeassistant/
│   └── config/           # HA configuration (created on first run)
├── mosquitto/
│   ├── config/
│   │   └── mosquitto.conf
│   ├── data/
│   └── log/
├── zigbee2mqtt/
│   ├── data/
│   │   ├── configuration.yaml
│   │   └── secrets.yaml
│   └── (database files created on run)
├── influxdb/
│   └── (data stored here)
└── docs/
    └── setup-guide.md    # User guide for post-setup steps
```

### Future (Hardware Required)
```
├── wled/
│   └── ESP32 board with WLED firmware  (NOT Docker)
```

## Configuration Files

### docker-compose.yml
Standard Compose file defining 4 Docker services (HA, Mosquitto, Zigbee2MQTT, InfluxDB) with proper networking and volumes.

### mosquitto.conf
```
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
listener 1883
```

### Zigbee2MQTT configuration.yaml
```yaml
homeassistant: true
permit_join: true
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://mosquitto:1883
serial:
  port: /dev/serial/by-id/usb-XXXXX  # To be updated after USB identification
frontend:
  port: 8080
```

## Setup Phases

### Phase 1: Docker Setup
- Create docker-compose.yml
- Create configuration files
- Create directory structure
- Test Docker connectivity

### Phase 2: Initial Launch
- Start Mosquitto first
- Start Home Assistant
- Complete HA initial setup via web UI
- Verify MQTT integration works

### Phase 3: Zigbee Integration
- Identify USB dongle device path
- Configure Zigbee2MQTT
- Start Zigbee2MQTT
- Pair test device (if available)
- Configure MQTT discovery in HA

### Phase 4: Database Setup
- Start InfluxDB
- Configure InfluxDB integration in HA
- Set up retention policies
- Verify historical data logging

### Phase 5: WLED Integration (Future - Hardware Required)
- Purchase ESP32 board
- Flash WLED firmware onto ESP32
- Connect ESP32 to LED strips
- Configure WLED integration in HA via HTTP/IP

## Testing Checklist

- [ ] Home Assistant web UI accessible
- [ ] Home Assistant can connect to MQTT
- [ ] Zigbee2MQTT web UI accessible (port 8080)
- [ ] Zigbee devices can be discovered
- [ ] Sensor data persists in InfluxDB
- [ ] All containers restart cleanly after `docker compose down && up`
- [ ] Phone can access Home Assistant on local WiFi

## Future Expansions

- **WLED** (Hardware): Purchase ESP32, flash WLED firmware, add LED strips
- Raspberry Pi deployment (Docker Compose transfers directly)
- Remote access via Cloudflare Tunnel or Tailscale
- Additional integrations: ESPHome, Node-RED, etc.
- Zigbee device network expansion
- Multiple WLED controllers
