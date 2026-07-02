/* Diana A. Serbanescu 
 * This schetch is doing a simple sensor data --> pitch mapping (proportional)
 * This sketch also saves incoming data from the sensor to a new CSV file, every time it runs the sketch.
 *
**/


import processing.serial.*;
import processing.sound.*;

Serial myPort;
SinOsc sine;

float rawValue = 0;
float smoothedValue = 700;

// Calibration values for the sensor range
float minSensor = 2500;
float maxSensor = 3240;

PrintWriter csv;
int sampleIndex = 0;

void setup() {
  size(800, 400);

  // Print all available serial ports to the console
  printArray(Serial.list());

  // Open serial port
  try {
    myPort = new Serial(this, "/dev/cu.usbmodem101", 115200);
    myPort.clear();
    // Wait until a newline character is received before triggering serialEvent()
    myPort.bufferUntil('\n');
    println("Connected to XIAO RP2040");
  }
  catch (Exception e) {
    println("SERIAL ERROR:");
    println(e);
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
    "stretch_dataset_" +
    timestamp +
    ".csv";

   csv = createWriter(filename);

  // CSV header
  csv.println("sample,time_ms,raw,smoothed,frequency");

  println("Recording to: " + filename);
  
  // Create and start a sine wave oscillator
  sine = new SinOsc(this);
  sine.play();
  // Set oscillator volume (0.0–1.0)
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
  text("RAW: " + rawValue, 20, 30);
  text("SMOOTH: " + smoothedValue, 20, 55);
  text("FREQ: " + freq + " Hz", 20, 80);

  // Draw visual representation of the sound wave
  drawWaveform(freq);
}

//void serialEvent(Serial p) {
//  String incoming = p.readStringUntil('\n');

//  if (incoming != null) {
//    incoming = trim(incoming);

//    String[] values = split(incoming, ',');

//    if (values.length == 2) {
//      rawValue = float(values[0]);
//      smoothedValue = float(values[1]);

//      println("raw: " + rawValue + " smooth: " + smoothedValue);
//    }
//  }
//}


void serialEvent(Serial p) {
  String incoming = p.readStringUntil('\n');

  if (incoming == null) return;

  incoming = trim(incoming);

  println("RX: " + incoming);  // debug: shows every incoming line

  if (incoming.length() == 0) return;
  if (incoming.startsWith("XIAO")) return;
  if (incoming.startsWith("===")) return;

  String[] values = split(incoming, ',');

  if (values.length == 2) {
    try {
      rawValue = float(values[0]);
      smoothedValue = float(values[1]);

      println("raw: " + rawValue + " smooth: " + smoothedValue);
    }
    catch (Exception e) {
      println("Parse error on line: " + incoming);
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
