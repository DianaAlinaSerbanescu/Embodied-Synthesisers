// --------------------------------------

// Embodied Stretch Synth - Sensor Test 

// by Diana Alina Serbanescu

// XIAO ESP32C3

// Reads stretch sensors on A0 and A1

// --------------------------------------


const int sensorPin1 = A0;
const int sensorPin2 = A1;

// int minValue = 2500;
// int maxValue = 3220;

// smoothing
float smoothedValue1 = 0.0;
float smoothedValue2 = 0.0;

float smoothing = 0.08;   
// smaller = smoother/slower
// larger = faster/noisier

bool paused = false;

void setup() {
  
  Serial.begin(115200);

  analogReadResolution(12);
  // wait for serial monitor
  delay(1000);

  pinMode(sensorPin1, INPUT);
  pinMode(sensorPin2, INPUT);

  Serial.println("XIAO ESP32C3 Dual Stretch Sensor Test");
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
  

  // ----------------------
  // SENSOR 1
  // ----------------------
  int rawValue1 = analogRead(sensorPin1);

  // exponential smoothing
  smoothedValue1 = 
    (smoothedValue1 * (1.0 - smoothing))
     + (rawValue1 * smoothing);

    // ----------------------
    // SENSOR 2
    // ----------------------

    int rawValue2 = analogRead(sensorPin2);

    smoothedValue2 =
      (smoothedValue2 * (1.0 - smoothing))
      + (rawValue2 * smoothing);

  // print values
  // Serial.print("RAW: ");
  // Serial.print(rawValue);
  // Serial.print("\tSMOOTH: ");
  // Serial.println(smoothedValue);

  // Send clean data to Processing:

  // raw,smoothed

  // float stretch = (rawValue - minValue) / float(maxValue - minValue);

  // stretch = constrain(stretch, 0.0, 1.0);

  // ----------------------
  // Serial output
  // ----------------------
  //
  // raw1,smoothed1,raw2,smoothed2
  //
  // Serial.print(rawValue1);
  // Serial.print(",");

  // Serial.print(smoothedValue1);
  // Serial.print(",");

  Serial.print(rawValue2);
  Serial.print(",");

  Serial.println(smoothedValue2);
  // Serial.print(smoothedValue);
  // Serial.print(",");
  // Serial.println(stretch);
  
  }
  delay(10);
}
