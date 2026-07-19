/* Diana A. Serbanescu
 * Embodied Stretch Synth
 *
 * Processing sketch for:
 * - receiving raw and smoothed values from a XIAO ESP32S3
 * - printing incoming values to the console
 * - tracking observed minimum and maximum values
 * - interactive calibration
 * - reporting whether the current value is below or above calibration
 * - mapping stretch to sine-wave pitch
 *
 * Controls:
 * R = calibrate relaxed position
 * S = calibrate stretched position
 * M = mute / unmute
 * C = reset calibration
 * X = reset observed minimum and maximum
 */

import processing.serial.*;
import processing.sound.*;

Serial myPort;
SinOsc sine;

// --------------------------------------------------
// Serial and sensor values
// --------------------------------------------------

float rawValue = 0;
float smoothedValue = 1780;

boolean serialConnected = false;
boolean sensorDataReceived = false;

// --------------------------------------------------
// Calibration
// --------------------------------------------------

// Fallback values based on recent readings.
// Interactive calibration will replace these.
float relaxedSensor = 1750;
float stretchedSensor = 2050;

boolean relaxedCalibrated = false;
boolean stretchedCalibrated = false;

boolean calibratingRelaxed = false;
boolean calibratingStretched = false;

int calibrationStartTime = 0;
int calibrationDuration = 1500; // milliseconds

float calibrationSum = 0;
int calibrationSamples = 0;

// Margin added only during mapping/status checks
float calibrationMargin = 3.0;

// --------------------------------------------------
// Observed range
// --------------------------------------------------

float observedMin = Float.MAX_VALUE;
float observedMax = -Float.MAX_VALUE;

// --------------------------------------------------
// Sound
// --------------------------------------------------

float minFreq = 100.0;
float maxFreq = 1000.0;

float normalized = 0.0;
float freq = minFreq;

float amplitude = 0.2;
boolean muted = false;

// --------------------------------------------------
// Status
// --------------------------------------------------

String sensorStatus = "WAITING";

/*
 * These store how far outside the calibrated
 * range the current smoothed reading is.
 */

float amountBelow = 0;

float amountAbove = 0;
// --------------------------------------------------
// Setup
// --------------------------------------------------

void setup() {
  size(950, 560);
  pixelDensity(1);

  println("Available serial ports:");
  printArray(Serial.list());

  try {
    myPort = new Serial(
      this,
      "/dev/cu.usbmodem101",
      115200
    );
    
    /*
     * Opening the serial port can reset the XIAO.
     * Give it time to restart before clearing data.
     */
    delay(1500);

    myPort.clear();
    myPort.bufferUntil('\n');

    serialConnected = true;

    println("Connected to XIAO ESP32S3");
  }
  catch (Exception e) {
    serialConnected = false;
    
    println("SERIAL ERROR:");
    println(e);
  }

  sine = new SinOsc(this);
  sine.play();
  sine.amp(amplitude);
}

// --------------------------------------------------
// Main loop
// --------------------------------------------------

void draw() {
  background(0);

  updateCalibration();
  updateSensorStatus();
  updatePitch();
  updateSound();

  drawInformation();
  drawWaveform(freq);
}

// --------------------------------------------------
// Pitch mapping
// --------------------------------------------------

void updatePitch() {
  float calibrationRange =
    stretchedSensor - relaxedSensor;

  if (abs(calibrationRange) < 0.001) {
    normalized = 0.0;
  } else {
    normalized =
      (smoothedValue - relaxedSensor) /
      calibrationRange;
  }

  normalized = constrain(
    normalized,
    0.0,
    1.0
  );

  // Exponential pitch mapping
  freq = minFreq * pow(
    maxFreq / minFreq,
    normalized
  );
}

// --------------------------------------------------
// Sound
// --------------------------------------------------

void updateSound() {
  sine.freq(freq);

  if (muted) {
    sine.amp(0.0);
  } else {
    sine.amp(amplitude);
  }
}

// --------------------------------------------------
// Status and range difference
// --------------------------------------------------

void updateSensorStatus() {
  if (!sensorDataReceived) {
    sensorStatus = "WAITING";
    return;
  }

  float calibratedMin =
    min(relaxedSensor, stretchedSensor) -
    calibrationMargin;

  float calibratedMax =
    max(relaxedSensor, stretchedSensor) +
    calibrationMargin;

  if (smoothedValue < calibratedMin) {
    sensorStatus = "BELOW MIN";
    
    amountBelow =
      calibratedMin - smoothedValue;
      
  } else if (smoothedValue > calibratedMax) {
    sensorStatus = "ABOVE MAX";
    
    amountAbove =
      smoothedValue - calibratedMax;
  } else {
    sensorStatus = "OK";
  }
}

// --------------------------------------------------
// Serial input
// --------------------------------------------------

void serialEvent(Serial p) {
  String incoming =
    p.readStringUntil('\n');

  if (incoming == null) {
    return;
  }

  incoming = trim(incoming);

  // Log every complete incoming line
  println("RX: " + incoming);

  if (incoming.length() == 0) {
    return;
  }

  // Ignore Arduino status lines
  if (incoming.startsWith("XIAO")) {
    return;
  }

  if (incoming.startsWith("===")) {
    return;
  }

  String[] values =
    split(incoming, ',');

  if (values.length != 2) {
    println(
      "Unexpected serial line: " +
      incoming
    );
    return;
  }

  try {
    float newRaw =
      float(trim(values[0]));

    float newSmoothed =
      float(trim(values[1]));

    // Reject obvious ADC saturation/disconnection
    if (newRaw <= 1 || newRaw >= 4095) {
      println(
        "Ignored ADC glitch: " +
        incoming
      );
      return;
    }

    rawValue = newRaw;
    smoothedValue = newSmoothed;

    sensorDataReceived = true;

    updateObservedRange();
    updateSensorStatus();

    // Collect calibration samples
    if (calibratingRelaxed ||
        calibratingStretched) {

      calibrationSum +=
        smoothedValue;

      calibrationSamples++;
    }

    printSensorLog();
  }
  catch (Exception e) {
    println(
      "Parse error on line: " +
      incoming
    );
    println(e);
  }
}

// --------------------------------------------------
// Console logging
// --------------------------------------------------

void printSensorLog() {
  float calibratedMin =
    min(relaxedSensor, stretchedSensor) -
    calibrationMargin;

  float calibratedMax =
    max(relaxedSensor, stretchedSensor) +
    calibrationMargin;

  println(
    "RAW: " +
    nf(rawValue, 0, 1) +

    " | SMOOTH: " +
    nf(smoothedValue, 0, 2) +

    " | OBS MIN: " +
    formatObservedValue(observedMin) +

    " | OBS MAX: " +
    formatObservedValue(observedMax) +

    " | CAL MIN: " +
    nf(calibratedMin, 0, 2) +

    " | CAL MAX: " +
    nf(calibratedMax, 0, 2) +

    " | STATUS: " +
    sensorStatus
  );
}

// --------------------------------------------------
// Observed minimum and maximum
// --------------------------------------------------

void updateObservedRange() {
  if (smoothedValue < observedMin) {
    observedMin = smoothedValue;
  }

  if (smoothedValue > observedMax) {
    observedMax = smoothedValue;
  }
}

void resetObservedRange() {
  if (sensorDataReceived) {
    observedMin = smoothedValue;
    observedMax = smoothedValue;

    println(
      "Observed range reset at: " +
      nf(smoothedValue, 0, 2)
    );
  } else {
    observedMin = Float.MAX_VALUE;
    observedMax = -Float.MAX_VALUE;

    println(
      "Observed range reset. Waiting for sensor data."
    );
  }
}

// --------------------------------------------------
// Keyboard controls
// --------------------------------------------------

void keyPressed() {
  if (key == 'r' || key == 'R') {
    startRelaxedCalibration();
  }

  if (key == 's' || key == 'S') {
    startStretchedCalibration();
  }

  if (key == 'm' || key == 'M') {
    muted = !muted;

    println(
      muted ? "Muted" : "Unmuted"
    );
  }

  if (key == 'c' || key == 'C') {
    clearCalibration();
  }

  if (key == 'x' || key == 'X') {
    resetObservedRange();
  }
}

// --------------------------------------------------
// Interactive calibration
// --------------------------------------------------

void startRelaxedCalibration() {
  if (!sensorDataReceived) {
    println(
      "Cannot calibrate: no sensor data received."
    );
    return;
  }

  if (calibratingRelaxed ||
      calibratingStretched) {
    return;
  }

  calibratingRelaxed = true;
  calibrationStartTime = millis();
  calibrationSum = 0;
  calibrationSamples = 0;

  println(
    "Calibrating relaxed position..."
  );
}

void startStretchedCalibration() {
  if (!sensorDataReceived) {
    println(
      "Cannot calibrate: no sensor data received."
    );
    return;
  }

  if (calibratingRelaxed ||
      calibratingStretched) {
    return;
  }

  calibratingStretched = true;
  calibrationStartTime = millis();
  calibrationSum = 0;
  calibrationSamples = 0;

  println(
    "Calibrating stretched position..."
  );
}

void updateCalibration() {
  if (!calibratingRelaxed &&
      !calibratingStretched) {
    return;
  }

  int elapsed =
    millis() - calibrationStartTime;

  if (elapsed < calibrationDuration) {
    return;
  }

  if (calibrationSamples == 0) {
    println(
      "Calibration failed: no samples received."
    );

    calibratingRelaxed = false;
    calibratingStretched = false;

    return;
  }

  float measuredValue =
    calibrationSum /
    calibrationSamples;

  if (calibratingRelaxed) {
    relaxedSensor = measuredValue;
    relaxedCalibrated = true;

    println(
      "Relaxed value recorded: " +
      nf(relaxedSensor, 0, 2)
    );
  }

  if (calibratingStretched) {
    stretchedSensor = measuredValue;
    stretchedCalibrated = true;

    println(
      "Stretched value recorded: " +
      nf(stretchedSensor, 0, 2)
    );
  }

  calibratingRelaxed = false;
  calibratingStretched = false;

  println(
    "Current calibration: relaxed=" +
    nf(relaxedSensor, 0, 2) +
    ", stretched=" +
    nf(stretchedSensor, 0, 2)
  );
}

void clearCalibration() {
  relaxedSensor = 615;
  stretchedSensor = 650;

  relaxedCalibrated = false;
  stretchedCalibrated = false;

  calibratingRelaxed = false;
  calibratingStretched = false;

  calibrationSum = 0;
  calibrationSamples = 0;

  println(
    "Calibration reset to default values."
  );
}

// --------------------------------------------------
// Display
// --------------------------------------------------

void drawInformation() {
  fill(255);
  textSize(18);

  int x = 20;
  int y = 30;
  int lineHeight = 25;

  text(
    "SERIAL: " +
    (serialConnected ? "CONNECTED" : "DISCONNECTED"),
    x,
    y
  );

  y += lineHeight;

  text(
    "RAW: " +
    nf(rawValue, 0, 1),
    x,
    y
  );

  y += lineHeight;

  text(
    "SMOOTH: " +
    nf(smoothedValue, 0, 2),
    x,
    y
  );

  y += lineHeight;

  text(
    "OBSERVED MIN: " +
    formatObservedValue(observedMin),
    x,
    y
  );

  y += lineHeight;

  text(
    "OBSERVED MAX: " +
    formatObservedValue(observedMax),
    x,
    y
  );

  y += lineHeight;

  text(
    "RELAXED: " +
    nf(relaxedSensor, 0, 2),
    x,
    y
  );

  y += lineHeight;

  text(
    "STRETCHED: " +
    nf(stretchedSensor, 0, 2),
    x,
    y
  );

  y += lineHeight;

  text(
    "CALIBRATED MIN: " +
    nf(
      min(relaxedSensor, stretchedSensor) -
      calibrationMargin,
      0,
      2
    ),
    x,
    y
  );

  y += lineHeight;

  text(
    "CALIBRATED MAX: " +
    nf(
      max(relaxedSensor, stretchedSensor) +
      calibrationMargin,
      0,
      2
    ),
    x,
    y
  );

  y += lineHeight;

  text(
    "STATUS: " +
    sensorStatus,
    x,
    y
  );

  y += lineHeight;

  text(
    "NORMALIZED: " +
    nf(normalized, 0, 3),
    x,
    y
  );

  y += lineHeight;

  text(
    "FREQ: " +
    nf(freq, 0, 1) +
    " Hz",
    x,
    y
  );

  // Controls
  fill(190);
  textSize(16);

  text(
    "R = calibrate relaxed",
    520,
    30
  );

  text(
    "S = calibrate stretched",
    520,
    55
  );

  text(
    "M = mute / unmute",
    520,
    80
  );

  text(
    "C = reset calibration",
    520,
    105
  );

  text(
    "X = reset observed range",
    520,
    130
  );

  // Calibration state
  if (calibratingRelaxed) {
    fill(255, 220, 0);

    text(
      "Hold sensor relaxed...",
      520,
      180
    );
  }

  if (calibratingStretched) {
    fill(255, 220, 0);

    text(
      "Hold sensor at maximum stretch...",
      520,
      180
    );
  }

  // Status warning
  if (sensorStatus.equals("BELOW MIN")) {
    fill(255, 170, 0);

    text(
      "Current value is below calibrated range",
      520,
      220
    );
  }

  if (sensorStatus.equals("ABOVE MAX")) {
    fill(255, 100, 100);

    text(
      "Current value is above calibrated range",
      520,
      220
    );
  }

  if (muted) {
    fill(255, 100, 100);

    text(
      "MUTED",
      520,
      260
    );
  }
}

String formatObservedValue(float value) {
  if (value == Float.MAX_VALUE ||
      value == -Float.MAX_VALUE) {
    return "waiting";
  }

  return nf(value, 0, 2);
}

// --------------------------------------------------
// Waveform
// --------------------------------------------------

void drawWaveform(float frequency) {
  stroke(255);
  noFill();

  beginShape();

  float cycles = map(
    frequency,
    minFreq,
    maxFreq,
    1,
    30
  );

  for (int x = 0; x < width; x++) {
    float phase = map(
      x,
      0,
      width,
      0,
      TWO_PI * cycles
    );

    float y =
      height * 0.82 +
      sin(phase) * 55;

    vertex(x, y);
  }

  endShape();

  stroke(100);

  line(
    0,
    height * 0.82,
    width,
    height * 0.82
  );
}
