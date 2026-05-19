# 🧬 Antibiotic Resistance Monitoring System
### Flutter BLE App + Arduino Sketch

A professional-grade IoT monitoring application for a biotechnology/medical laboratory setting. Detects environmental conditions (temperature and light) that may promote antibiotic-resistant bacterial growth.

---

## 📱 App Features

| Feature | Description |
|---|---|
| BLE Scanner | Scan and connect to the HM-10 module |
| Live Dashboard | Real-time temperature & LDR readings |
| Risk Detection | Automatic SAFE / RISK classification |
| Trend Chart | Mini temperature history sparkline |
| Status Alerts | Snackbar notifications on risk events |
| Animations | Pulsing indicators, scanner rings |

---

## 🗂 Project Structure

```
lib/
├── main.dart                     # App entry point & providers
├── theme/
│   └── app_theme.dart            # Colors, gradients, Material 3 theme
├── models/
│   └── sensor_data.dart          # Immutable sensor reading value object
├── services/
│   └── ble_service.dart          # flutter_blue_plus BLE abstraction
├── widgets/
│   └── app_widgets.dart          # Shared reusable UI components
└── screens/
    ├── scanner_screen.dart        # BLE device discovery + connect
    └── dashboard_screen.dart      # Real-time monitoring dashboard
```

---

## ⚙️ Arduino Setup

### Hardware

| Component | Pin |
|---|---|
| DHT11 DATA | D2 |
| LDR module OUT | A0 |
| Green LED (+) | D4 + 220Ω |
| Red LED (+) | D5 + 220Ω |
| Buzzer (+) | D6 |
| HM-10 TX | D8 (Arduino RX) |
| HM-10 RX | D9 (Arduino TX) |

### Required Libraries
- `DHT sensor library` by Adafruit
- `SoftwareSerial` (built-in)

### Data Format
Arduino transmits every 1 second over BLE:
```
Temperature,LDR,Status\n
24.50,620,NORMAL
35.20,200,RISK
```

---

## 🚀 Flutter Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Android permissions
Already configured in `android/app/src/main/AndroidManifest.xml`.

Requires Android 6.0+ (API 23). Tested on Android 12+ (API 31).

### 3. Fonts
Download from Google Fonts and place in `assets/fonts/`:
- `ShareTechMono-Regular.ttf`
- `Rajdhani-Regular.ttf`
- `Rajdhani-Medium.ttf`
- `Rajdhani-SemiBold.ttf`
- `Rajdhani-Bold.ttf`

Or update `pubspec.yaml` to use `google_fonts` package instead.

### 4. Run
```bash
flutter run --release
```

---

## 🔬 Risk Logic

```
IF temperature > 30°C
   OR LDR value < 500 ADC
   OR Arduino status == "RISK"
THEN → RISK DETECTED (red card, buzzer, snackbar alert)
ELSE → ENVIRONMENT STABLE (green card)
```

---

## 🎨 Design Palette

| Token | Hex | Use |
|---|---|---|
| Navy Deep | `#050E1F` | App background |
| Navy Panel | `#112254` | Cards |
| Cyan Bright | `#00E5FF` | Accents, live data |
| Safe Green | `#00E676` | Safe state |
| Risk Red | `#FF1744` | Risk state |
| Risk Orange | `#FF6D00` | LDR warning |

---

## 📦 Key Dependencies

```yaml
flutter_blue_plus: ^1.35.3   # BLE communication
provider: ^6.1.2              # State management
permission_handler: ^11.3.1  # Runtime permissions
intl: ^0.19.0                 # Timestamp formatting
```

---

## 🏫 University Presentation Notes

This project demonstrates:
1. **IoT Integration** — BLE serial communication with embedded hardware
2. **Sensor Fusion** — Combining temperature + photosensitive data for health monitoring
3. **Clean Architecture** — Separated models / services / UI layers
4. **Medical UX Design** — Accessible, color-coded status indicators
5. **Real-time Systems** — Stream-based reactive UI updates

---

*Built for a university Biotechnology project. Production-ready Flutter + Arduino code.*
