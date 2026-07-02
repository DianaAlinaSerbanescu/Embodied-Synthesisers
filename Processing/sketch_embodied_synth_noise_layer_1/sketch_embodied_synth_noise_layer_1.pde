import processing.serial.*;
import processing.sound.*;

Serial myPort;

// OSCILLATORS
SinOsc sine;
WhiteNoise noise;

// FILTER
BandPass band;

// SENSOR VALUES
float rawValue = 0;
float smoothedValue = 700;

// SENSOR RANGE
float minSensor = 650;
float maxSensor = 820;

// AUDIO VALUES
float freq = 220;
float noiseFreq = 500;
float amp = 0.2;

void setup() {

  size(1000, 500);

  printArray(Serial.list());

  // CHANGE INDEX IF NEEDED
  myPort = new Serial(this, Serial.list()[7], 115200);
  myPort.bufferUntil('\n');

  // --- SINE OSCILLATOR ---
  sine = new SinOsc(this);
  sine.play();
  sine.amp(0.15);

  // --- NOISE ---
  noise = new WhiteNoise(this);
  noise.play();
  noise.amp(0.25);

  // --- FILTER ---
  band = new BandPass(this);

  // Route noise through filter
  band.process(noise);

  background(0);
}

void draw() {

  background(0);

  // ==========================
  // MAP SENSOR TO SOUND
  // ==========================

  // SINE FREQUENCY
  freq = map(smoothedValue,
             minSensor,
             maxSensor,
             80,
             1000);

  freq = constrain(freq, 80, 1200);

  sine.freq(freq);

  // ==========================
  // NOISE FILTER FREQUENCY
  // ==========================

  // Stretch controls brightness
  noiseFreq = map(smoothedValue,
                  minSensor,
                  maxSensor,
                  200,
                  5000);

  noiseFreq = constrain(noiseFreq, 100, 6000);

  // FILTER SETTINGS
  band.freq(noiseFreq);

  // resonance / sharpness
  band.res(8);

  // ==========================
  // AMPLITUDE
  // ==========================

  amp = map(smoothedValue,
            minSensor,
            maxSensor,
            0.05,
            0.4);

  amp = constrain(amp, 0.05, 0.4);

  sine.amp(amp);

  // ==========================
  // VISUALS
  // ==========================

  drawWaveform(freq);

  fill(255);
  textSize(18);

  text("RAW: " + rawValue, 20, 30);
  text("SMOOTH: " + smoothedValue, 20, 60);

  text("SINE FREQ: " + int(freq) + " Hz", 20, 90);

  text("NOISE FILTER: " + int(noiseFreq) + " Hz", 20, 120);

  text("AMPLITUDE: " + nf(amp,1,2), 20, 150);
}


// =======================================
// SERIAL
// =======================================

void serialEvent(Serial p) {

  String incoming = p.readStringUntil('\n');

  if (incoming != null) {

    incoming = trim(incoming);

    String[] values = split(incoming, ',');

    if (values.length == 2) {

      rawValue = float(values[0]);
      smoothedValue = float(values[1]);

      println("raw: " + rawValue +
              " smooth: " + smoothedValue);
    }
  }
}


// =======================================
// WAVEFORM DRAWING
// =======================================

void drawWaveform(float freq) {

  stroke(255);
  noFill();

  beginShape();

  // frequency controls visual density
  float cycles = map(freq,
                     80,
                     1200,
                     1,
                     25);

  for (int x = 0; x < width; x++) {

    float phase = map(x,
                      0,
                      width,
                      0,
                      TWO_PI * cycles);

    // animated waveform
    float y =
      height/2 +
      sin(phase + frameCount * 0.03)
      * 100;

    vertex(x, y);
  }

  endShape();

  // center line
  stroke(80);
  line(0, height/2, width, height/2);
}
