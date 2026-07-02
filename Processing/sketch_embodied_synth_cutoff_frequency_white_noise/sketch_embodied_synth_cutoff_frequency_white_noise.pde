/* Diana A. Serbanescu
 * Stretch sensor → white noise low-pass cutoff
 */

import processing.serial.*;
import processing.sound.*;

Serial myPort;

WhiteNoise noise;
LowPass lowpass;

float rawValue = 0;
float smoothedValue = 0;

// Sensor calibration
float minSensor = 2300;
float maxSensor = 2900;

// Cutoff frequency range
float minCutoff = 100;
float maxCutoff = 8000;

void setup() {
  size(800, 400);

  printArray(Serial.list());

  try {
    myPort = new Serial(this, "/dev/cu.usbmodem101", 115200);
    myPort.clear();
    myPort.bufferUntil('\n');
    println("Connected to XIAO RP2040");
  }
  catch (Exception e) {
    println("SERIAL ERROR:");
    println(e);
  }

  noise = new WhiteNoise(this);
  lowpass = new LowPass(this);

  noise.play();
  noise.amp(0.2);

  lowpass.process(noise);
}

void draw() {
  background(0);

  // Direct mapping:
  // low sensor value  -> dark noise
  // high sensor value -> bright noise
  float cutoff = map(smoothedValue, minSensor, maxSensor, minCutoff, maxCutoff);
  cutoff = constrain(cutoff, minCutoff, maxCutoff);

  lowpass.freq(cutoff);

  fill(255);
  textSize(18);
  text("RAW: " + rawValue, 20, 30);
  text("SMOOTH: " + smoothedValue, 20, 55);
  text("CUTOFF: " + cutoff + " Hz", 20, 80);

  drawFilterVisual(cutoff);
}

void serialEvent(Serial p) {
  String incoming = p.readStringUntil('\n');

  if (incoming == null) return;

  incoming = trim(incoming);

  if (incoming.length() == 0) return;
  if (incoming.startsWith("XIAO")) return;
  if (incoming.startsWith("===")) return;

  String[] values = split(incoming, ',');

  if (values.length == 2) {
    try {
      rawValue = float(values[0]);
      smoothedValue = float(values[1]);
    }
    catch (Exception e) {
      println("Parse error: " + incoming);
    }
  }
}

void drawFilterVisual(float cutoff) {
  stroke(255);
  noFill();

  float xCutoff = map(cutoff, minCutoff, maxCutoff, 50, width - 50);

  // Frequency axis
  stroke(100);
  line(50, height / 2, width - 50, height / 2);

  // Low-pass response curve
  stroke(255);
  beginShape();

  for (int x = 50; x < width - 50; x++) {
    float freqPos = map(x, 50, width - 50, minCutoff, maxCutoff);

    float response;
    if (freqPos <= cutoff) {
      response = 1.0;
    } else {
      response = map(freqPos, cutoff, maxCutoff, 1.0, 0.0);
      response = constrain(response, 0.0, 1.0);
    }

    float y = map(response, 0, 1, height - 60, 140);
    vertex(x, y);
  }

  endShape();

  // Cutoff marker
  stroke(255);
  line(xCutoff, 120, xCutoff, height - 50);

  fill(255);
  text("cutoff", xCutoff + 8, 130);
}
