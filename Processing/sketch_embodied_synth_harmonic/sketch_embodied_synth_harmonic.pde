/* Diana A. Serbanescu 
 * This schetch is doing a simple sensor data --> pitch mapping (additive synthesis, amplitude decreases with harmonic number)
 *
 *
**/


import processing.serial.*;
import processing.sound.*;

Serial myPort;
SinOsc[] partials = new SinOsc[12];
float[] amps = {
  0.45,
  0.25,
  0.15,
  0.10,
  0.07,
  0.05,
  0.03,
  0.02,
  0.015,
  0.01,
  0.005,
  0.001
};

float rawValue = 0;
float smoothedValue = 700;

// Calibration values for the sensor range
float minSensor = 2600;
float maxSensor = 2900;

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
 
 // Create and start harmonic sine wave oscillators
 for (int i = 0; i < partials.length; i++) {
    partials[i] = new SinOsc(this);
    partials[i].amp(amps[i]);
    partials[i].play();
  }
}

void draw() {
  background(0);

  // Map sensor values to a frequency range
  float freq = map(smoothedValue, minSensor, maxSensor, 40, 800);
  
  // Prevent frequencies from going outside safe limits
  freq = constrain(freq, 40, 800);

  // Update oscillators frequency
  for (int i = 0; i < partials.length; i++) {
    float harmonic = i + 1;
    partials[i].freq(freq * harmonic);
  }

  // Display sensor and frequency information
  fill(255);
  textSize(18);
  text("RAW: " + rawValue, 20, 30);
  text("SMOOTH: " + smoothedValue, 20, 55);
  text("FREQ: " + freq + " Hz", 20, 80);

  // Draw visual representation of the sound wave
  //drawAdditiveWaveform(freq);
  drawPartials(freq);
}



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

void drawPartials(float freq) {

  float fundamentalCycles = map(freq, 40, 800, 1, 12);

  for (int i = 0; i < partials.length; i++) {

    float harmonic = i + 1;
    float centerY = height/2;
    
    stroke(255, 90);
    noFill();

    beginShape();

    for (int x = 0; x < width; x++) {

      float phase = map(
        x,
        0,
        width,
        0,
        TWO_PI * fundamentalCycles * harmonic
      );

      float y = centerY + sin(phase) * amps[i] * 300;

      vertex(x, y);
    }

    endShape();

    fill(255);
    //text("H" + harmonic + " amp " + nf(amps[i], 1, 3), 10, 100 + i * 18);
  }
}

void drawAdditiveWaveform(float freq) {
  stroke(255);
  noFill();

  beginShape();

  float fundamentalCycles = map(freq, 100, 1000, 1, 20);

  for (int x = 0; x < width; x++) {

    float sum = 0;

    for (int i = 0; i < partials.length; i++) {
      float harmonic = i + 1;
      float phase = map(x, 0, width, 0, TWO_PI * fundamentalCycles * harmonic);

      sum += sin(phase) * amps[i];
    }

    float y = height / 2 + sum * 250;
    vertex(x, y);
  }

  endShape();

  stroke(100);
  line(0, height / 2, width, height / 2);
}
