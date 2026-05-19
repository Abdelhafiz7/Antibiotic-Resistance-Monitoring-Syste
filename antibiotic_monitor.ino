/*
 * antibiotic_monitor.ino
 * ─────────────────────────────────────────────────────────────────────────────
 * Arduino Antibiotic Resistance Monitoring System
 * Reads DHT11 (temperature) and LDR, then sends data over HM-10 BLE module
 * in the format: "Temperature,LDR,Status\n"
 * e.g. "24.5,620,NORMAL\n"  or  "35.2,200,RISK\n"
 *
 * Wiring:
 *   DHT11 DATA  → Pin 2
 *   LDR module  → A0 (analog)
 *   Green LED   → Pin 4 (with 220Ω resistor)
 *   Red LED     → Pin 5 (with 220Ω resistor)
 *   Buzzer      → Pin 6
 *   HM-10 TX    → Pin 8  (Arduino RX via SoftwareSerial)
 *   HM-10 RX    → Pin 9  (Arduino TX via SoftwareSerial)
 * ─────────────────────────────────────────────────────────────────────────────
 */

#include <DHT.h>
#include <SoftwareSerial.h>

// ── Pin definitions ──────────────────────────────────────────────────────────
#define DHT_PIN      2
#define DHT_TYPE     DHT11
#define LDR_PIN      A0
#define GREEN_LED    4
#define RED_LED      5
#define BUZZER_PIN   6
#define HM10_RX_PIN  8   // Arduino receives on this pin (connect to HM-10 TX)
#define HM10_TX_PIN  9   // Arduino transmits on this pin (connect to HM-10 RX)

// ── Thresholds ───────────────────────────────────────────────────────────────
#define TEMP_THRESHOLD  30.0   // °C — above this is risk
#define LDR_THRESHOLD   500    // ADC — below this is risk

// ── Timing ───────────────────────────────────────────────────────────────────
#define SEND_INTERVAL_MS  1000  // Send data every 1 second

// ── Instances ────────────────────────────────────────────────────────────────
DHT           dht(DHT_PIN, DHT_TYPE);
SoftwareSerial ble(HM10_RX_PIN, HM10_TX_PIN);

// ── State ─────────────────────────────────────────────────────────────────────
unsigned long lastSendTime = 0;
bool          riskActive   = false;
unsigned long buzzerStart  = 0;
bool          buzzerOn     = false;

// ─────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);    // USB serial for debug
  ble.begin(9600);       // HM-10 default baud rate

  dht.begin();

  pinMode(GREEN_LED,  OUTPUT);
  pinMode(RED_LED,    OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Boot indication: brief green flash
  digitalWrite(GREEN_LED, HIGH);
  delay(400);
  digitalWrite(GREEN_LED, LOW);

  Serial.println(F("Antibiotic Resistance Monitor — Ready"));
  Serial.println(F("Waiting for BLE connection..."));
}

// ─────────────────────────────────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();

  // ── Send data at fixed interval ──
  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;
    sendSensorData();
  }

  // ── Non-blocking buzzer beep (500 ms on, 500 ms off) for RISK ──
  if (riskActive) {
    if (!buzzerOn && (now - buzzerStart >= 500)) {
      tone(BUZZER_PIN, 1000);   // 1 kHz tone
      buzzerOn   = true;
      buzzerStart = now;
    } else if (buzzerOn && (now - buzzerStart >= 500)) {
      noTone(BUZZER_PIN);
      buzzerOn   = false;
      buzzerStart = now;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
void sendSensorData() {
  // Read DHT11 temperature
  float temperature = dht.readTemperature();   // Celsius

  // Validate DHT11 reading
  if (isnan(temperature)) {
    Serial.println(F("DHT11 read error — skipping"));
    return;
  }

  // Read LDR (inverted: higher ADC = more light on most LDR modules)
  int ldrValue = analogRead(LDR_PIN);

  // ── Determine status ──
  bool isRisk = (temperature > TEMP_THRESHOLD) || (ldrValue < LDR_THRESHOLD);
  String status = isRisk ? "RISK" : "NORMAL";

  // ── Update LEDs & buzzer ──
  if (isRisk) {
    digitalWrite(GREEN_LED, LOW);
    digitalWrite(RED_LED,   HIGH);
    if (!riskActive) {
      riskActive  = true;
      buzzerOn    = false;
      buzzerStart = millis();
    }
  } else {
    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(RED_LED,   LOW);
    if (riskActive) {
      noTone(BUZZER_PIN);
      riskActive = false;
      buzzerOn   = false;
    }
  }

  // ── Format and send BLE payload ──
  // Format: "24.50,620,NORMAL\n"
  String payload = String(temperature, 2) + "," +
                   String(ldrValue)       + "," +
                   status                 + "\n";

  ble.print(payload);      // Send over BLE to Flutter app
  Serial.print(F("TX: "));
  Serial.print(payload);   // Echo to USB serial for debugging
}
