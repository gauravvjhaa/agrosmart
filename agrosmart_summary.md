# AgroSmart: Smart Irrigation & Crop Intelligence Platform  
Smart India Hackathon 2025 – Problem ID: SIH25062  

## 1. Project Overview  
AgroSmart is an integrated smart agriculture IoT platform tailored for hilly and rain-prone regions where erratic runoff, fragmented plots, and unreliable connectivity reduce yields. It combines low-power edge sensing (soil moisture, rainfall, temperature, flow), adaptive irrigation automation, localized decision intelligence, and an inclusive Flutter-based app (mobile + web) to empower farmers with data-driven water and crop management. Distinct value:  
- Terrain-aware irrigation zoning with runoff mitigation.  
- Works in low-connectivity conditions via LoRa + offline-capable app + SMS/Bluetooth fallback.  
- Progressive intelligence: starts rule-based, evolves to predictive scheduling.  
- Modular hardware (retrofit-friendly) + secure, scalable cloud + local resilience.  

## 2. Core Problem Being Solved  
| Challenge | Impact | AgroSmart Response |
|-----------|--------|--------------------|
| Water runoff during rains | Topsoil & nutrient loss | Rain capture + flow diversion + predictive irrigation pausing |
| Uneven water distribution | Over/under watering zones | Soil-zone mapping + per-zone valve control |
| Limited farming tech adoption | Low trust & usability barriers | Multilingual, voice assist, simple KPIs |
| Connectivity issues | Data gaps & control failure | LoRa mesh + store & forward + offline sync + SMS fallback |

Additional constraints: fragmented holdings, variable microclimates, labor scarcity, rising input costs.

## 3. Solution: AgroSmart Platform  

### 3.1 Hardware Components  
- Soil Moisture Sensors (capacitive, multi-depth)  
- Soil Temperature & Ambient Humidity Sensors (SHT31 / BME280)  
- Rain Gauge (tipping bucket) + Rain Intensity Estimator  
- Flow + Pressure Sensors (for leak detection)  
- Motorized/solenoid Valves (per irrigation zone)  
- Edge MCU Nodes:  
  - ESP32 (primary: Wi-Fi/BLE + compute)  
  - Arduino Nano (ultra-low-power satellite probes)  
- Communication:  
  - LoRa (SX1276) for long range, low bandwidth telemetry  
  - Optional NB-IoT / LTE-M uplink module (plug-in)  
- Power:  
  - Solar + LiFePO4 battery packs (5–7 day autonomy)  
  - Power budget tracking (adaptive sampling)  
- Gateway:  
  - ESP32 + LoRa Concentrator (bridges to Wi-Fi / Cellular)  
  - Local failover buffer (SPI Flash / SD)  
- Actuation Safety:  
  - Manual override switch  
  - Watchdog + safe-close on brownout  
- Rainwater Harvesting Integration:  
  - Tank level ultrasonic sensor  
  - Diversion valve logic (overflow prediction)  

### 3.2 Software Platform (Flutter + Cloud + Edge)  
- Flutter App (Android / iOS / Web / Desktop-ready)  
- Firestore (real-time docs) + Cloud Storage (media)  
- Firebase Auth (Phone/Email/Optional Aadhaar KYC)  
- Cloud Functions (validation, anomaly alerts, ML triggers)  
- Local Edge Scheduler (failsafe if cloud unreachable)  
- Background Sync Engine (delta-based, conflict resolution)  

## 4. Key Features of the App  

### 4.1 Dashboard & Monitoring  
- Real-time zone cards: moisture %, temp, valve state, last irrigation time  
- Historical charts (hourly/daily/seasonal) with anomaly markers  
- Integrated weather (IMD / OpenWeather + altitude-adjusted ET)  
- Tank level + rainfall capture efficiency widget  
- Alert stream (low moisture, sensor offline, excess flow)  

### 4.2 Irrigation Control  
- Modes: Manual | Scheduled | Smart Auto | Emergency Flush  
- Per-zone scheduling (cron-like + sunset/sunrise aware)  
- Override: stop all / pause due to forecasted rain  
- Water budget tracking (weekly quota vs usage)  

### 4.3 Smart Automation  
- Crop-specific moisture threshold bands (dynamic via phenological stage)  
- Predictive irrigation (soil trend + evapotranspiration + forecast rain probability)  
- Adaptive learning: refines zone water dose based on past response curves  
- Leak / burst detection (flow vs expected discharge curve)  

### 4.4 Offline Functionality  
- Local SQLite cache (sensor snapshots, pending commands)  
- Command queue with retry + exponential backoff  
- Bluetooth direct-mode (near gateway) to push emergency commands  
- SMS fallback syntax (e.g., IRRIGATE Z3 10MIN)  
- Conflict resolution policy (newest authoritative by logical timestamp + vector clock tag)  

### 4.5 Crop Management Tools  
- Crop Database (water needs, ideal pH, stage milestones)  
- Rotation & soil health recommendations (NPK depletion heuristic)  
- Yield forecasting (growing degree days + moisture compliance score)  
- Pest/disease advisory hooks (optional API integration)  

### 4.6 User-Centric Design  
- Multi-language (EN / HI + extensible localization keys)  
- Voice command (Moisture Status / Start Zone 2 / Pause All)  
- Color-blind accessible palette + large touch targets  
- Low literacy mode (iconography + audio prompts)  

### 4.7 Data Security & Management  
- Firebase Auth + role tiers (Farmer / Advisor / Admin)  
- Firestore Security Rules (zone-scoped access)  
- Encrypted at-rest (Firestore managed) + TLS in transit  
- Periodic export to Cloud Storage (daily JSON snapshots)  
- Tamper flags for outlier sensor jumps  

## 5. Flutter App Directory Structure  
```text
lib/
  core/
    config/            # Env, constants, feature flags
    routing/           # GoRouter/AppRouter
    theme/             # Colors, typography, adaptive schemes
    localization/      # i18n arb helpers
    utils/             # Formatters, math, geo, validators
    error/             # Failure models, exception mappers
    services/
      network/         # Connectivity monitor
      logging/         # Structured logger
      notification/    # FCM + local notifications
      voice/           # Voice command integration
      security/        # Auth guards, token helpers
    platform/          # Platform channels (LoRa bridge, BLE, SMS)
  data/
    models/            # DTOs / domain models
    firestore/         # Query builders, converters
    repositories/      # Abstract & impl (sensor, irrigation, crop)
    local/
      db/              # SQLite (moor/isar/drift)
      cache/           # In-memory caches
      sync/            # Sync queue & conflict resolver
  features/
    dashboard/
      presentation/
      state/
    irrigation_control/
    automation/
    crops/
    alerts/
    analytics/
    auth/
    settings/
    offline/
  domain/
    entities/
    value_objects/
    usecases/
  ml/
    predictors/        # Irrigation ML models (on-device)
    adapters/          # TensorFlow Lite / custom inference
  bootstrap/
    app_initializer.dart
  app.dart
  main.dart
```

## 6. Technical Implementation Details  

### 6.1 Firestore Collections (Logical Schema)  
```json
{
  "farmers/{farmerId}": {
    "name": "string",
    "phone": "string",
    "language": "hi",
    "createdAt": "timestamp",
    "roles": ["farmer"],
    "zones": ["zoneA","zoneB"]
  },
  "cropinfo/{cropId}": {
    "name": "Tomato",
    "stages": [
      {"stage":"vegetative","minMoist":28,"maxMoist":38},
      {"stage":"flowering","minMoist":32,"maxMoist":42}
    ],
    "gddBase": 10,
    "defaultCycleDays": 110
  },
  "sensor_readings/{docId}": {
    "farmerId":"...","zoneId":"zoneA",
    "moisture":31.4,"temp":19.6,"humidity":71,
    "rainLastHour":2.1,
    "battery":87,
    "ts":"timestamp",
    "_ingest":"edge|cloud"
  },
  "zones/{zoneId}": {
    "farmerId":"...","cropId":"...","valveState":"closed",
    "currentStage":"flowering","lastIrrigation":"timestamp",
    "autoMode": true,
    "targetProfile":"profile_2025_kharif"
  },
  "irrigation_commands/{cmdId}": {
    "zoneId":"zoneA","action":"OPEN","durationSec":600,
    "issuedBy":"farmer|auto","status":"queued|sent|acked|failed",
    "createdAt":"timestamp"
  },
  "alerts/{alertId}": {
    "farmerId":"...","type":"LEAK|LOW_MOISTURE|RAIN_PAUSE",
    "zoneId":"zoneA","severity":"info|warn|critical",
    "message":"Leak suspected in Zone A",
    "ts":"timestamp","ack":false
  }
}
```
Indexes:  
- sensor_readings: compound (farmerId, zoneId, ts DESC)  
- irrigation_commands: (zoneId, status)  
- alerts: (farmerId, ack, ts DESC)  

### 6.2 Responsive Design  
- Layout breakpoints: <600 (handset), 600–1024 (tablet), >1024 (web)  
- Use Slivers + AdaptiveChart widgets  
- MediaQuery + LayoutBuilder + breakpoints constants  

### 6.3 Offline & Sync Strategy  
- Drift/Isar local DB tables: sensor_readings_cache, pending_commands, zones_cache  
- Outbox pattern:  
  1. User issues command → stored with logicalClock + hash  
  2. NetworkListener triggers sync → optimistic UI updates  
  3. Cloud ack merges; failures rollback with snackbar prompt  
- Conflict resolution:  
  - Valve state: last authoritative ack wins.  
  - Crop stage transition: validated server-side via Cloud Function (stage sequence check).  

### 6.4 Edge Intelligence Flow  
1. Edge node ingests moisture every X mins (adaptive: dry = higher frequency)  
2. Local threshold breach? → Preps pre-emptive irrigation request (tag pre_authorized)  
3. Gateway connectivity check:  
   - Online: push to irrigation_commands  
   - Offline: store in SD queue + timestamp jitter to avoid flood  
4. Rain forecast > 70% + moisture above lower band → auto postpone scheduling  

### 6.5 Security & Reliability  
- Firestore rules enforce farmerId ownership filter  
- Command signing (short HMAC using derived device key) for critical actuator ops (optional enhancement)  
- Audit log (Cloud Function writes immutable log collection)  
- Rate limits (max irrigation open commands per zone per hour)  

### 6.6 Deployment Strategy  
- Progressive rollout (Firebase App Distribution + staged testers)  
- OTA firmware (ESP32) via signed manifest served from Cloud Storage + fallback image partition  
- Analytics:  
  - Engagement: activeZones, autoIrrigationAcceptanceRate  
  - Agronomic: moistureComplianceIndex, waterSavedLiters  
- Feedback Loop: in-app micro form after major cycle completion  

### 6.7 Performance Optimizations  
- Batch write sensor packets (up to 500) when gateway regains connectivity  
- Compression (CBOR or protobuf) over LoRa → gateway translates to JSON  
- Debounce UI charts (throttle re-renders to 1s intervals)  
- Lazy load historical series (paginated by time windows)  

### 6.8 Testing Approach  
- Unit: repositories, use cases, threshold evaluator  
- Widget: dashboard cards snapshot tests  
- Integration: simulated offline queue + reconnection scenario  
- Hardware-in-loop: valve timing variance vs expected discharge curve  

## 7. Additional Suggestions (Innovative Extensions)  

| Feature | Description | Benefit |
|---------|-------------|---------|
| AI Irrigation Optimizer | On-device lightweight regression (TF Lite) refines watering duration using past response curves | Reduced water waste |
| Weather Downscaling AI | Blend coarse forecast + local sensor variation to generate microclimate predictions | Higher accuracy scheduling |
| Blockchain Produce Traceability | Optional supply chain ledger (seed → harvest → transport) | Premium market credibility |
| Soil Carbon Credit Tracking | Estimate carbon sequestration → credit eligibility export | Additional farmer revenue |
| Gamified Engagement | Points for maintaining optimal moisture & completing training modules | Adoption & retention |
| Advisory Marketplace | Agronomists subscribe to anonymized farm dashboards | Expert guidance |
| Pest Early Warning | ML vision (leaf images offline-scored) | Loss prevention |
| Community Water Sharing | Cooperative water budget negotiation via app | Resource fairness |

## 8. References  
1. Evans, R. G., & Sadler, E. J. (2008). Methods and technologies to improve efficiency of water use. Agricultural Water Management. https://doi.org/10.1016/j.agwat.2008.01.022  
2. Jones, H. G. (2004). Irrigation scheduling: Advantages and pitfalls of plant-based methods. Journal of Experimental Botany. https://doi.org/10.1093/jxb/erh213  
3. Kim, Y., Evans, R. G., & Iversen, W. M. (2008). Remote sensing and control of an irrigation system using a distributed wireless sensor network. IEEE Transactions on Instrumentation and Measurement. https://doi.org/10.1109/TIM.2008.917198  
4. Llamas, B. et al. (2023). Machine learning–based irrigation optimization in heterogeneous soils. Computers and Electronics in Agriculture. https://doi.org/10.1016/j.compag.2023.108158  
5. Government of India – ICAR / PMKSY Guidelines (Water Use Efficiency & Micro-Irrigation): https://pmksy.gov.in / https://icar.org.in (Best practice alignment).  

## Completion Confirmation  
All required sections (1–8) delivered with added enhancements, Firestore schema, directory structure, and innovation roadmap—ready for hackathon submission.

