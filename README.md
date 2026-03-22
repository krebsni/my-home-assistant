# My Home Assistant Setup

Docker-based Home Assistant environment for macOS (Apple Silicon M3) with Zigbee integration, MQTT messaging, and time-series database.

## Services

| Service | Port | Description |
|---------|------|-------------|
| Home Assistant | 8123 | Smart home hub |
| Mosquitto MQTT | 1883 | Message broker |
| Zigbee2MQTT | 8080 | Zigbee bridge |
| InfluxDB | 8086 | Time-series database |

## Quick Start

### 1. Clone and Start

```bash
git clone https://github.com/krebsni/my-home-assistant.git
cd my-home-assistant
docker compose up -d
```

### 2. Access Home Assistant

- **Mac**: http://localhost:8123
- **Phone**: http://<your-mac-ip>:8123

To find your Mac's IP:
```bash
ipconfig getifaddr en0
```

### 3. First-Time Setup

1. Open http://localhost:8123
2. Create your admin account
3. Complete the onboarding wizard

## Configuration

### MQTT Integration

1. Settings → Devices & Services → Add Integration
2. Search "MQTT"
3. Configure:
   - Broker: `mosquitto`
   - Port: `1883`

### InfluxDB Setup

1. Open http://localhost:8086
2. Create admin account
3. Generate API token (Load Data → API Tokens)
4. Add InfluxDB integration in Home Assistant:
   - Host: `http://influxdb:8086`
   - Organization: `homeassistant`
   - Bucket: `sensors`
   - Token: (your API token)

### Zigbee Setup

1. Enable USB in Docker Desktop: Settings → Resources → USB → Enable USB debugging
2. Restart the Zigbee2MQTT container:
   ```bash
   docker compose restart zigbee2mqtt
   ```
3. Open Zigbee2MQTT: http://localhost:8080
4. Put devices in pairing mode and click "Permit join"

## Useful Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f homeassistant
docker compose logs -f zigbee2mqtt

# Restart a service
docker compose restart zigbee2mqtt

# Check status
docker compose ps
```

## Finding Your Zigbee USB Device

If Zigbee2MQTT can't find the USB dongle:

```bash
# List USB devices
system_profiler SPUSBDataType

# List serial ports
ls -la /dev/tty.*

# Update device path in docker-compose.yml if needed
```

## File Structure

```
.
├── docker-compose.yml          # Docker services configuration
├── .env                       # Environment variables
├── docs/
│   ├── setup-guide.md         # Detailed setup guide
│   └── superpowers/
│       ├── specs/             # Design specifications
│       └── plans/             # Implementation plans
├── homeassistant/config/      # Home Assistant config (generated)
├── mosquitto/
│   └── config/mosquitto.conf # MQTT broker config
├── zigbee2mqtt/
│   └── data/configuration.yaml # Zigbee2MQTT config
└── influxdb/                  # Database files (generated)
```

## Future Expansions

- **WLED**: Add ESP32 with WLED firmware for LED control
- **ESPHome**: Add custom ESP devices
- **Remote Access**: Cloudflare Tunnel or Tailscale VPN
- **Raspberry Pi**: Deploy to Pi using same Docker Compose

## Security Notes

- Never commit runtime data (databases, logs, secrets)
- `.gitignore` excludes all sensitive directories
- Change default passwords for MQTT and InfluxDB
- Use strong passwords for Home Assistant accounts

## Troubleshooting

### Home Assistant won't start
```bash
docker compose logs homeassistant
```

### MQTT not connecting
- Ensure MQTT integration uses `mosquitto` (not `localhost`)

### Zigbee2MQTT can't find USB
- Enable USB in Docker Desktop settings
- Try a different USB port
- Check device path: `ls -la /dev/tty.*`

### Can't access from phone
- Use your Mac's IP address, not `localhost`
- Ensure phone is on the same WiFi network
