// --------------------------------------

// Embodied Stretch Synth - OSC WiFi Sender

// by Diana Alina Serbanescu

// XIAO ESP32C3

// Reads stretch sensor on A0

// Sends OSC over WiFi

// --------------------------------------

#include <WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>

// ---------- WiFi settings ----------

const char* ssid = "iPhone";
const char* password = "Replica22";

// Laptop IP address on the iPhone hotspot
// To find your Mac IP while connected to the iPhone hotspot: ipconfig getifaddr en0
IPAddress laptopIP(172, 20, 10, 9);

// OSC receive port in Processing / Max 
const int oscPort = 8000;

// ---------- UDP / OSC ----------
WiFiUDP udp;

// ---------- Sensor ----------
// Value from the stretch sensor is read from pin A0
const int sensorPin = A0;

// smoothing
float smoothedValue = 0.0;
float smoothing = 0.08;   

bool paused = false;

// Send rate
const unsigned long sendInterval = 10; // ms = 100 Hz
unsigned long lastSendTime = 0;

void setup() {
  
  // Serial.begin(115200);
  // wait for serial monitor
  // delay(1000);

  analogReadResolution(12);
  pinMode(sensorPin, INPUT);

  // Serial.println("XIAO ESP32C3 Stretch Sensor OSC WiFi Sender");

  // ---------- Connect to WiFi ----------
  // Serial.print("Connecting to WiFi: ");
  // Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    // Serial.print(".");
  }

  // Serial.println();
  // Serial.println("WiFi connected.");
  // Serial.print("ESP32 IP address: ");
  // Serial.println(WiFi.localIP());

  udp.begin(oscPort);

  // Serial.println("OSC sender ready.");
}

void loop() {

  unsigned long now = millis(); 
  
  if (now - lastSendTime >= sendInterval) {
    lastSendTime = now;

    // read raw ADC value
    int rawValue = analogRead(sensorPin);

    // exponential smoothing
    smoothedValue = (smoothedValue * (1.0 - smoothing)) + (rawValue * smoothing);

    // timestamp in milliseconds since board boot
    unsigned long timestamp = millis();

    // ---------- Serial debug ----------
    // Serial.print("OSC -> ");
    // Serial.print(laptopIP);
    // Serial.print(":");
    // Serial.print(oscPort);
    // Serial.print("  /stretch ");
    
    // Serial.print(timestamp);
    // Serial.print(",");
    // Serial.print(rawValue);
    // Serial.print(",");
    // Serial.println(smoothedValue);
  
    // ---------- OSC message ----------
    OSCMessage msg("/stretch");
    
    msg.add((int32_t)timestamp);
    msg.add((int32_t)rawValue);
    msg.add((float)smoothedValue);

    udp.beginPacket(laptopIP, oscPort);
    msg.send(udp);
    udp.endPacket();
    
    msg.empty();
 }
}
