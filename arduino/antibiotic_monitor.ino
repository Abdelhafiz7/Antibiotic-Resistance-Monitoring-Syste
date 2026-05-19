
#include <DHT.h>
#include <SoftwareSerial.h>

// ======================================
// BLUETOOTH CONFIGURATION (HM-10)
// ======================================

// Arduino Pin 3 = RX
// Arduino Pin 4 = TX

SoftwareSerial BTSerial(3, 4);

// ======================================
// DHT11 SENSOR CONFIGURATION
// ======================================

#define DHTPIN 2
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

// ======================================
// PIN CONFIGURATION
// ======================================

const int ldrPin = A0;

const int greenLED = 8;
const int redLED = 9;
const int buzzer = 10;

// ======================================
// THRESHOLD VALUES
// ======================================

const float TEMP_THRESHOLD = 30.0;

const int LDR_THRESHOLD = 500;

// ======================================
// SETUP
// ======================================

void setup() {

  // Serial Monitor
  Serial.begin(9600);

  // Bluetooth Serial
  BTSerial.begin(9600);

  // Start DHT11
  dht.begin();

  // Output pins
  pinMode(greenLED, OUTPUT);
  pinMode(redLED, OUTPUT);
  pinMode(buzzer, OUTPUT);

  Serial.println("======================================");
  Serial.println(" ANTIBIOTIC RESISTANCE MONITOR ");
  Serial.println(" Smart Monitoring System Started ");
  Serial.println("======================================");

  BTSerial.println("Bluetooth Connected");
}

// ======================================
// LOOP
// ======================================

void loop() {

  // ======================================
  // READ TEMPERATURE
  // ======================================

  float temperature = dht.readTemperature();

  // ======================================
  // READ LDR VALUE
  // ======================================

  int ldrValue = analogRead(ldrPin);

  // ======================================
  // CHECK DHT11
  // ======================================

  if (isnan(temperature)) {

    Serial.println("ERROR: DHT11 sensor failed!");
    BTSerial.println("ERROR:DHT11");

    Serial.println("--------------------------------");

    delay(2000);

    return;
  }

  // ======================================
  // RISK LOGIC
  // ======================================

  bool highTemperature = temperature > TEMP_THRESHOLD;

  bool highTurbidity = ldrValue < LDR_THRESHOLD;

  bool riskDetected = highTemperature || highTurbidity;

  // ======================================
  // DISPLAY VALUES ON SERIAL MONITOR
  // ======================================

  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.println(" C");

  Serial.print("LDR Value: ");
  Serial.println(ldrValue);

  // ======================================
  // SEND DATA TO FLUTTER APP
  // FORMAT:
  // Temperature,LDR,Status
  // ======================================

  BTSerial.print(temperature);
  BTSerial.print(",");

  BTSerial.print(ldrValue);
  BTSerial.print(",");

  if (riskDetected) {
    BTSerial.println("RISK");
  }
  else {
    BTSerial.println("NORMAL");
  }

  // ======================================
  // RISK CONDITION
  // ======================================

  if (riskDetected) {

    digitalWrite(greenLED, LOW);

    digitalWrite(redLED, HIGH);

    digitalWrite(buzzer, HIGH);

    Serial.println("STATUS: RISK DETECTED");

    if (highTemperature) {
      Serial.println("WARNING: High temperature detected");
    }

    if (highTurbidity) {
      Serial.println("WARNING: Possible high bacterial turbidity");
    }
  }

  // ======================================
  // NORMAL CONDITION
  // ======================================

  else {

    digitalWrite(greenLED, HIGH);

    digitalWrite(redLED, LOW);

    digitalWrite(buzzer, LOW);

    Serial.println("STATUS: NORMAL");
    Serial.println("Environment stable");
  }

  Serial.println("--------------------------------");

  delay(2000);
}
