// --------------------------------------

// Embodied Stretch Synth - Sensor Test 

// by Diana Alina Serbanescu

// XIAO ESP32S3

// Reads stretch sensor on A0
// Reads stretch sensor on A1
// --------------------------------------


// Value from the stretch sensor is read from pin A0
const int sensorPin0 = A0;
// Value from the stretch sensor is read from pin A1
const int sensorPin1 = A1;

// smoothing
float smoothedValue0 = 0.0;
float smoothedValue1 = 0.0;
float smoothing = 0.04;   

bool paused = false;

void setup() {
  
  Serial.begin(115200);

  analogReadResolution(12);

  pinMode(sensorPin0, INPUT);
  pinMode(sensorPin1, INPUT);

  // wait for serial monitor
  delay(1000);

  // Initialize smoothing from actual sensor readings
  smoothedValue0 = analogRead(sensorPin0);
  smoothedValue1 = analogRead(sensorPin1);
  Serial.println("XIAO ESP32-S3 Dual Stretch Sensor Test");
}

void loop() {
  
  // check keyboard input
  if (Serial.available() > 0) {
    char c = Serial.read();
    
    if (c == 'p') {
      paused = !paused;

      if (paused) {
        Serial.println("=== PAUSED ===");
      } else {
        Serial.println("=== RUNNING ===");
      }
    }
  }

 if (!paused) {
  // read raw ADC values
  int rawValue0 = analogRead(sensorPin0);
  int rawValue1 = analogRead(sensorPin1);
  
  // exponential smoothing 
  smoothedValue0 = 
    (smoothedValue0 * (1.0 - smoothing)) 
    + (rawValue0 * smoothing);
  
  smoothedValue1 = 
    (smoothedValue1 * (1.0 - smoothing)) 
    + (rawValue1 * smoothing);

  // Send one clean line to Processing:
  // raw0,smoothed0,raw1,smoothed1
  Serial.print(rawValue0);
  Serial.print(",");
  Serial.print(smoothedValue0);
  Serial.print(",");
  Serial.print(rawValue1);
  Serial.print(",");
  Serial.println(smoothedValue1);
 }

  delay(10);
}

