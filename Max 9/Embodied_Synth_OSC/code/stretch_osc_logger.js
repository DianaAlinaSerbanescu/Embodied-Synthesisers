autowatch = 1;
outlets = 1;

post("stretch_osc_logger.js loaded\n");

var file = null;
var filename = "";
var sample = 0;
var startTime = new Date().getTime();

var minSensor = 2500;
var maxSensor = 3240;
var minFreq = 100;
var maxFreq = 1000;

function loadbang() {
    start();
}

function start() {
    
    sample = 0;
    startTime = new Date().getTime();

    var d = new Date();
    var filename =
        "data/stretch_dataset_osc_" +
        d.getFullYear() +
        pad(d.getMonth() + 1) +
        pad(d.getDate()) + "_" +
        pad(d.getHours()) +
        pad(d.getMinutes()) +
        pad(d.getSeconds()) +
        ".csv";
        
    //filename = "/Users/diana/Desktop/stretch_dataset_osc_" + timestamp + ".csv";    

    file = new File(filename, "write");
    
    if (!file.isopen) {

        post("ERROR: could not create CSV at " + filename + "\n");

        outlet(0, "ERROR could_not_create_csv");

        return;

    }
    

    file.writeline("sample, max_time_ms, sensor_time_ms, raw, smoothed, frequency");
    file.close();

    post("Recording to: " + filename + "\n");
    outlet(0, "recording_to", filename);
}

function list(sensorTime, raw, smoothed) {
    if (file == null) {

        outlet(0, "ERROR no_file");
        return;
    }
    var now = new Date().getTime();
    var processingTime = now - startTime;

    var freq = scale(smoothed, minSensor, maxSensor, minFreq, maxFreq);
    freq = Math.max(minFreq, Math.min(maxFreq, freq));

    var row =
        sample + "," +
        processingTime + "," +
        sensorTime + "," +
        raw + "," +
        smoothed + "," +
        freq;

    file.open("append");
    
    if (!file.isopen) {

        post("ERROR: could not reopen CSV\n");

        outlet(0, "ERROR could_not_reopen_csv");

        return;

    }
    
    file.position = file.eof;
    
    file.writeline(row);
    file.close();
    
    outlet(0, "logged", sample, processingTime, sensorTime, raw, smoothed, freq);

    sample++;
}

function stop() {
    post("CSV saved: " + filename + "\n");

    outlet(0, "saved", filename);
}

function pad(n) {
    return n < 10 ? "0" + n : "" + n;
}

function scale(v, inMin, inMax, outMin, outMax) {
    return outMin + ((v - inMin) * (outMax - outMin)) / (inMax - inMin);
}