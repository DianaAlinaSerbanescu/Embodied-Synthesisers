/* Diana A. Serbanescu
 * Stretch sensor → white noise low-pass cutoff + amplitude
 * Silence when relaxed OR silence when stretched
 */

import processing.serial.*;
import processing.sound.*;

Serial myPort;

WhiteNoise noise;
LowPass lowpass;

float rawValue = 0;
float smoothedValue = 0;

// Sensor calibration
float minSensor = 2450;
float maxSensor = 2900;

// Sound range
float minCutoff = 40;
float maxCutoff = 8000;
float maxAmp = 0.25;

// Change this:
// false = relaxed is silent, stretched is loud/bright
// true  = stretched is silent, relaxed is loud/bright
boolean silenceWhenStretched = false;

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
  noise.amp(0.0);

  lowpass.process(noise);
}

void draw() {
  background(0);

  float sensorNorm = map(smoothedValue, minSensor, maxSensor, 0, 1);
  sensorNorm = constrain(sensorNorm, 0, 1);

  float control;

  if (silenceWhenStretched) {
    control = 1.0 - sensorNorm;
  } else {
    control = sensorNorm;
  }

  float cutoff = map(control, 0, 1, minCutoff, maxCutoff);
  float amp = map(control, 0, 1, 0.0, maxAmp);

  cutoff = constrain(cutoff, minCutoff, maxCutoff);
  amp = constrain(amp, 0.0, maxAmp);

  noise.amp(amp);
  lowpass.freq(cutoff);

  fill(255);
  textSize(18);
  text("RAW: " + rawValue, 20, 30);
  text("SMOOTH: " + smoothedValue, 20, 55);
  text("NORM: " + nf(sensorNorm, 1, 3), 20, 80);
  text("CONTROL: " + nf(control, 1, 3), 20, 105);
  text("CUTOFF: " + cutoff + " Hz", 20, 130);
  text("AMP: " + nf(amp, 1, 3), 20, 155);

  drawFilterVisual(cutoff, amp);
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

void drawFilterVisual(float cutoff, float amp) {
  float xCutoff = map(cutoff, minCutoff, maxCutoff, 50, width - 50);

  stroke(100);
  line(50, height / 2, width - 50, height / 2);

  stroke(255);
  noFill();

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

    float y = map(response * amp, 0, maxAmp, height - 60, 190);
    vertex(x, y);
  }

  endShape();

  stroke(255);
  line(xCutoff, 180, xCutoff, height - 50);

  fill(255);
  text("cutoff", xCutoff + 8, 190);
}
