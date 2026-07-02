// --------------------------------------

// Embodied Stretch Synth - Sensor Test 

// by Diana Alina Serbanescu

// XIAO RP2040

// Reads stretch sensor on A0

// --------------------------------------


// Value from the stretch sensor is read from pin A0

const int sensorPin = A0;

// int minValue = 2500;
// int maxValue = 3220;

// smoothing
float smoothedValue = 0.0;
float smoothing = 0.08;   
// smaller = smoother/slower
// larger = faster/noisier

bool paused = false;

void setup() {
  
  Serial.begin(115200);

  analogReadResolution(12);
  // wait for serial monitor
  delay(1000);

  pinMode(sensorPin, INPUT);

  Serial.println("XIAO RP2040 Stretch Sensor Test");
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
  int rawValue = analogRead(sensorPin);

  // exponential smoothing
  smoothedValue = (smoothedValue * (1.0 - smoothing)) + (rawValue * smoothing);

  // print values
  // Serial.print("RAW: ");
  // Serial.print(rawValue);
  // Serial.print("\tSMOOTH: ");
  // Serial.println(smoothedValue);

  // Send clean data to Processing:

  // raw,smoothed

  // float stretch = (rawValue - minValue) / float(maxValue - minValue);

  // stretch = constrain(stretch, 0.0, 1.0);

  Serial.print(rawValue);
  Serial.print(",");
  Serial.println(smoothedValue);
  // Serial.print(smoothedValue);
  // Serial.print(",");
  // Serial.println(stretch);
  
  }

  delay(10);
}
