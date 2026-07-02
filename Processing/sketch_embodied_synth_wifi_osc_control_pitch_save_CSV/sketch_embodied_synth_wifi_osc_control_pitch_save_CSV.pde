/* Diana A. Serbanescu 
 * This schetch is doing a simple sensor data --> pitch mapping (proportional)
 * Sensor data via OSC over WiFi → pitch mapping
 * Saves incoming OSC data to a new CSV file every run.
 *
**/


import oscP5.*;
import netP5.*;
import processing.sound.*;

OscP5 oscP5;
SinOsc sine;

float rawValue = 0;
float smoothedValue = 700;
float sensorTimestamp = 0;

// Must match the port used in the ESP32 code
int oscReceivePort = 8000;

// Calibration values for the sensor range
float minSensor = 2500;
float maxSensor = 3240;

PrintWriter csv;
int sampleIndex = 0;

void setup() {
  size(800, 400);

  try{
    // Start OSC receiver
    oscP5 = new OscP5(this, oscReceivePort);
    println("Listening for OSC on port " + oscReceivePort);
  } catch (Exception e){
    println("OSC ERROR:");
    println(e);
    exit();
  }
  // Initialising the CSV file
  String timestamp =
    year() +
    nf(month(), 2) +
    nf(day(), 2) + "_" +
    nf(hour(), 2) +
    nf(minute(), 2) +
    nf(second(), 2);

  String filename =
    "stretch_dataset_osc_" +
    timestamp +
    ".csv";

  csv = createWriter(filename);

  // CSV header
  csv.println("sample,processing_time_ms,sensor_time_ms,raw,smoothed,frequency");
  csv.flush();

  println("Recording to: " + filename);
  
  // Create and start a sine wave oscillator
  sine = new SinOsc(this);
  sine.play();
  sine.amp(0.2);
}

void draw() {
  background(0);

  // Map sensor values to a frequency range
  float freq = map(smoothedValue, minSensor, maxSensor, 100, 1000);
  // Prevent frequencies from going outside safe limits
  freq = constrain(freq, 100, 1000);

  // Update oscillator frequency
  sine.freq(freq);
  
  // Write incoming data into the CSV file
  csv.println(
    sampleIndex + "," +
    millis() + "," +
    sensorTimestamp + "," +
    rawValue + "," +
    smoothedValue + "," +
    freq
  );

  sampleIndex++;
  if (frameCount % 60 == 0) {
    csv.flush();
  }

  // Display sensor and frequency information
  fill(255);
  textSize(18);
  text("OSC PORT: " + oscReceivePort, 20, 30);
  text("SENSOR TIME: " + sensorTimestamp, 20, 55);
  text("RAW: " + rawValue, 20, 80);
  text("SMOOTH: " + smoothedValue, 20, 105);
  text("FREQ: " + freq + " Hz", 20, 130);

  // Draw visual representation of the sound wave
  drawWaveform(freq);
}


void oscEvent(OscMessage msg) {

  println("OSC received: " + msg.addrPattern());

  if (msg.checkAddrPattern("/stretch")) {
    if (msg.arguments().length >= 3) {
      sensorTimestamp = msg.get(0).intValue();
      rawValue = msg.get(1).intValue();
      smoothedValue = msg.get(2).floatValue();

      println(
        "sensor time: " + sensorTimestamp +
        " raw: " + rawValue +
        " smooth: " + smoothedValue
      );
    }
  }
}



void drawWaveform(float freq) {
  stroke(255);
  noFill();

  beginShape();
  // number of visible sine cycles
  float cycles = map(freq, 100, 1000, 1, 20);

  for (int x = 0; x < width; x++) {
    float phase = map(x, 0, width, 0, TWO_PI * cycles);
    float y = height / 2 + sin(phase) * 80;
    vertex(x, y);
  }
  endShape();
  
  // center line
  stroke(100);
  line(0, height / 2, width, height / 2);
}

void exit() {

  if (csv != null) {
    csv.flush();
    csv.close();
  }

  println("CSV saved.");
  super.exit();
}
