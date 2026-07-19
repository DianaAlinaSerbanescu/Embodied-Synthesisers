// --------------------------------------

// Embodied Stretch Synth - Sensor Test 

// by Diana Alina Serbanescu

// XIAO ESP32S3

// Reads stretch sensor on A0

// --------------------------------------


// Value from the stretch sensor is read from pin A0
const int sensorPin0 = A0;

// int minValue = 2500;
// int maxValue = 3220;

// smoothing
float smoothedValue0 = 0.0;
float smoothing = 0.04;   
// smaller = smoother/slower
// larger = faster/noisier

bool paused = false;

void setup() {
  
  Serial.begin(115200);

  analogReadResolution(12);
  // wait for serial monitor
  delay(1000);

  pinMode(sensorPin0, INPUT);

  Serial.println("XIAO ESP32-S3 Stretch Sensor Test");
}

void loop() {
  
  // check keyboard input

  if (Serial.available()) {
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
  // read raw ADC value
  int rawValue0 = analogRead(sensorPin0);

  // exponential smoothing
  smoothedValue0 = (smoothedValue0 * (1.0 - smoothing)) + (rawValue0 * smoothing);

  // print values
  // Serial.print("RAW: ");
  // Serial.print(rawValue0);
  // Serial.print("\tSMOOTH: ");
  // Serial.println(smoothedValue0);

  // Send clean data to Processing:

  // raw,smoothed

  // float stretch = (rawValue0 - minValue) / float(maxValue - minValue);

  // stretch = constrain(stretch, 0.0, 1.0);

  Serial.print("RAW0: ");
  Serial.print(rawValue0);
  Serial.print(",");
  Serial.print("\tSMOOTH0: ");
  Serial.println(smoothedValue0);
  // Serial.print(smoothedValue0);
  // Serial.print(",");
  // Serial.println(stretch);
  
  }

  delay(10);
}

