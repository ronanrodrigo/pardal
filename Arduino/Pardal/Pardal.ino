#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer* server = NULL;
BLECharacteristic* characteristic = NULL;
BLEService* service = NULL;
BLEAdvertising* advertising = NULL;

bool deviceConnected = false;
bool oldDeviceConnected = false;
bool advertisignStarted = false;
bool severStarded = false;

// Lap ────────────────────────────────────────────────────────────────────────────────────────
struct Lap {
  int number;
  long startedAt;
  long finishedAt;
  String duration;

  void setDuration() {
    long calculatedDuration = finishedAt - startedAt;
    int seconds = (calculatedDuration / 1000) % 60;
    int minutes = (calculatedDuration / (1000 * 60)) % 60;
    int milliseconds = calculatedDuration % 1000;
    String formattedSeconds = (seconds < 10 ? "0" : "") + String(seconds);
    String formattedMilliseconds = (milliseconds < 10 ? "00" : "") + String(milliseconds);
    formattedMilliseconds = (milliseconds < 100 ? "0" : "") + String(milliseconds);
    duration = String(minutes) + ":" + formattedSeconds + "." + formattedMilliseconds;
  }

  void finish() {
    finishedAt = millis();
    setDuration();
    characteristic->setValue(toJson());
    characteristic->notify();
  }

  void start() {
    startedAt = millis();
    number++;
  }

  std::string toJson() {
    String lapJson = "{\"number\": %number%, \"started_at\": %started_at%, \"finished_at\": %finished_at%, \"duration\": \"%duration%\"}";
    lapJson.replace("%number%", String(number));
    lapJson.replace("%duration%", duration);
    lapJson.replace("%started_at%", String(startedAt));
    lapJson.replace("%finished_at%", String(finishedAt));
    return lapJson.c_str();
  }
} trackingLap = { 0, 0, 0, "" };
// Lap ────────────────────────────────────────────────────────────────────────────────────────

// Presenter ──────────────────────────────────────────────────────────────────────────────────
class Presenter {
private:
  static const int feedackPin = 2;
public:
  static void setup() {
    pinMode(feedackPin, OUTPUT);
  }

  static void showFeedback() {
    digitalWrite(feedackPin, HIGH);
  }

  static void hideFeedback() {
    digitalWrite(feedackPin, LOW);
  }
};
// Presenter ──────────────────────────────────────────────────────────────────────────────────

// BLECallbacks ───────────────────────────────────────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* server) {
    deviceConnected = true;
  }

  void onDisconnect(BLEServer* server) {
    deviceConnected = false;
  }
};
// BLECallbacks ───────────────────────────────────────────────────────────────────────────────

// Configurator ───────────────────────────────────────────────────────────────────────────────
class Configurator {
private:
  static void setupService(BLEUUID serviceId) {
    BLEDevice::init("LapTimer");
    server = BLEDevice::createServer();
    server->setCallbacks(new ServerCallbacks());
    service = server->createService(serviceId);
  }

  static void setupCharacteristic(BLEUUID characteristicId) {
    characteristic = service->createCharacteristic(
      characteristicId, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    characteristic->addDescriptor(new BLE2902());
  }

  static void setupAdvertising(BLEUUID serviceId) {
    advertising = BLEDevice::getAdvertising();
    advertising->addServiceUUID(serviceId);
  }

public:
  static void configure() {
    BLEUUID serviceId = BLEUUID("8CF071B4-7DF7-41A8-9328-AF9A4051EBC8");
    BLEUUID characteristicId = BLEUUID("beb5483e-36e1-4688-b7f5-ea07361b26a8");
    Serial.begin(115200);
    setupService(serviceId);
    setupCharacteristic(characteristicId);
    setupAdvertising(serviceId);
    Presenter::setup();
  }
};
// Configurator ───────────────────────────────────────────────────────────────────────────────

// Device ─────────────────────────────────────────────────────────────────────────────────────
class Device {
private:
  static void startAdvertising() {
    if (!advertisignStarted) {
      BLEDevice::startAdvertising();
      server->startAdvertising();
      advertisignStarted = true;
    }
  }

  static void startServer() {
    if (!severStarded) {
      service->start();
      severStarded = true;
    }
  }
public:
  static bool connected() {
    return deviceConnected && !oldDeviceConnected;
  }

  static bool disconnected() {
    return !deviceConnected && oldDeviceConnected;
  }

  static void activate() {
    startServer();
    startAdvertising();
  }

  static void deactivate() {
    service->stop();
    server->getAdvertising()->stop();
    advertisignStarted = false;
    severStarded = false;
  }
};
// Device ─────────────────────────────────────────────────────────────────────────────────────

// LapTrigger ─────────────────────────────────────────────────────────────────────────────────
class LapTrigger {
public:
  static const uint8_t PULLUP_TRIGGER = 0;
  static const uint8_t TIMER_TRIGGER = 1;
  virtual bool isTriggered() = 0;
};

class InputPullupLapTrigger : public LapTrigger {
private:
  int triggerLastState = HIGH;
  int feedackPin = 2;
  int triggerState() {
    return digitalRead(InputPullupLapTrigger::feedackPin);
  }
public:
  InputPullupLapTrigger() {
    pinMode(InputPullupLapTrigger::feedackPin, INPUT_PULLUP);
  }
  bool isTriggered() {
    int stateTriggered = triggerState();
    bool changed = triggerLastState != stateTriggered;
    bool didTrigger = triggerLastState == HIGH && stateTriggered == LOW;
    if (changed) {
      triggerLastState = stateTriggered;
    }
    return didTrigger;
  }
};

class TimerLapTrigger : public LapTrigger {
public:
  bool isTriggered() {
    long randomNumber = random(500, 3500);
    delay(randomNumber);
    return true;
  }
};

class LapTriggerFactory {
public:
  static LapTrigger* make(uint8_t triggerType) {
    if (triggerType == LapTrigger::PULLUP_TRIGGER) {
      return new InputPullupLapTrigger();
    } else if (triggerType == LapTrigger::TIMER_TRIGGER) {
      return new TimerLapTrigger();
    }
    return new InputPullupLapTrigger();
  }
};

LapTrigger* lapTrigger = LapTriggerFactory::make(LapTrigger::PULLUP_TRIGGER);
// LapTrigger ─────────────────────────────────────────────────────────────────────────────────


// Pardal ─────────────────────────────────────────────────────────────────────────────────────

class Pardal {
private:
  static void handleDeviceConnectivity() {
    if (Device::connected()) {
      oldDeviceConnected = deviceConnected;
    }
    if (Device::disconnected()) {
      trackingLap.finish();
      delay(500);
      oldDeviceConnected = deviceConnected;
      Device::deactivate();
    }
  }

  static void lapTrack() {
    Presenter::hideFeedback();
    if (!Device::connected()) { return; }
    if (!lapTrigger->isTriggered()) { return; }
    trackingLap.finish();
    Presenter::showFeedback();
    trackingLap.start();
    delay(100);
  }

public:
  static void configure() {
    Configurator::configure();
    Device::activate();
  }

  static void run() {
    Device::activate();
    lapTrack();
    handleDeviceConnectivity();
  }
};
// Pardal ─────────────────────────────────────────────────────────────────────────────────────


// Arduino ────────────────────────────────────────────────────────────────────────────────────
void setup() {
  Pardal::configure();
}

void loop() {
  Pardal::run();
}
// Arduino ────────────────────────────────────────────────────────────────────────────────────
