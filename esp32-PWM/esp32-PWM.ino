#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TaskScheduler.h>

#define SERVICE_UUID              "6d8f85c9-d8f8-412f-95ff-a5134788caeb"
#define ENABLE_UUID               "df7812b2-372c-4a18-bf23-b3c7bf8d2d1c"
#define FREQ_UUID                 "30d70343-6a3f-450b-8dd1-a927f9f3e4fa"
#define DUTY_UUID                 "f60c9a2b-d01a-4137-be49-1faa2ac098a6"

#define DEVINFO_UUID              (uint16_t)0x180a
#define DEVINFO_MANUFACTURER_UUID (uint16_t)0x2a29
#define DEVINFO_NAME_UUID         (uint16_t)0x2a24
#define DEVINFO_SERIAL_UUID       (uint16_t)0x2a25

#define DEVICE_MANUFACTURER "OOO"
#define DEVICE_NAME         "EyesFit"

#define PIN_BUTTON 0
#define PIN_LED LED_BUILTIN
#define PIN_PWM PIN_LED//16
#define PWM_CHANNEL 0
#define PWM_RESOLUTION 8
#define PWM_MAXRESOLUTION 255.0

Scheduler scheduler;

void buttonCb();

Task taskButton(30, TASK_FOREVER, &buttonCb, &scheduler, true);

uint8_t enable;
uint8_t frequency = 50;
uint8_t duty = PWM_MAXRESOLUTION / 2;

BLECharacteristic *pCharEnable;
BLECharacteristic *pCharFrequency;
BLECharacteristic *pCharDuty;

void setEnable(bool on, bool notify = false) {
  if (enable == on) return;

  enable = on;
  if (enable) {
    Serial.println("Run ON");
    PWMenable(true);
  } else {
    Serial.println("Run OFF");
    PWMenable(false);
  }

  pCharEnable->setValue(&enable, 1);
  if (notify) {
    pCharEnable->notify();
  }
}

void setFrequency(uint8_t v) {
  frequency = v;
  ledcSetup(PWM_CHANNEL, frequency, PWM_RESOLUTION);
  ledcWrite(PWM_CHANNEL, duty);
  Serial.println("Frequency updated");
}

void setDuty(uint8_t v) {
  duty = (uint8_t)(PWM_MAXRESOLUTION * ((double)v / 100));
  ledcWrite(PWM_CHANNEL, duty);
  Serial.print("Duty updated");
}

void buttonCb() {
  uint8_t btn = digitalRead(PIN_BUTTON) != HIGH;
  if (btn) {
    setEnable(!enable, true);
    taskButton.delay(1000);
  }
}

void PWMenable(bool on) {
  if (on) {
    ledcSetup(PWM_CHANNEL, frequency, PWM_RESOLUTION);
    ledcAttachPin(PIN_PWM, PWM_CHANNEL);
    pinMode(PIN_PWM, OUTPUT);
    setFrequency(frequency);
  } else {
    ledcDetachPin(PIN_PWM);
  }
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println("Connected");
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println("Disconnected");
    }
};

class EnableCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length()  == 1) {
        uint8_t v = value[0];
        Serial.print("Got enable value: ");
        Serial.println(v);
        setEnable(v ? true : false);
      } else {
        Serial.println("Invalid data received");
      }
    }
};

class FrequencyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() == 1) {
        uint8_t v = value[0];
        Serial.print("Got frequency value: ");
        Serial.println(v);
        if (v >= 1 && v <= 100) {
          setFrequency(v);
          return;
        }
      }
      pCharFrequency->setValue(&frequency, 1);
      Serial.println("Invalid data received");
    }
};

class DutyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() == 1) {
        uint8_t v = value[0];
        Serial.print("Got duty value: ");
        Serial.println(v);
        if (v >= 1 && v <= 100) {
          setDuty(v);
          return;
        }
      }
      pCharDuty->setValue(&duty, 1);
      Serial.println("Invalid data received");
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");

  pinMode(PIN_BUTTON, INPUT);
  //pinMode(PIN_LED, OUTPUT);

  String devName = DEVICE_NAME;
  String chipId = String((uint32_t)(ESP.getEfuseMac() >> 24), HEX);
  devName += '_';
  devName += chipId;

  BLEDevice::init(devName.c_str());
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());


  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharEnable = pService->createCharacteristic(ENABLE_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE);
  pCharEnable->setCallbacks(new EnableCallbacks());
  pCharEnable->addDescriptor(new BLE2902());

  pCharFrequency = pService->createCharacteristic(FREQ_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pCharFrequency->setCallbacks(new FrequencyCallbacks());
  pCharFrequency->setValue(&frequency, 1);

  pCharDuty = pService->createCharacteristic(DUTY_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pCharDuty->setCallbacks(new DutyCallbacks());
  pCharDuty->setValue(&duty, 1);

  pService->start();

  pService = pServer->createService(DEVINFO_UUID);

  BLECharacteristic *pChar = pService->createCharacteristic(DEVINFO_MANUFACTURER_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_MANUFACTURER);

  pChar = pService->createCharacteristic(DEVINFO_NAME_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_NAME);

  pChar = pService->createCharacteristic(DEVINFO_SERIAL_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(chipId.c_str());

  pService->start();

  // ----- Advertising

  BLEAdvertising *pAdvertising = pServer->getAdvertising();

  BLEAdvertisementData adv;
  adv.setName(devName.c_str());
  //adv.setCompleteServices(BLEUUID(SERVICE_UUID));
  pAdvertising->setAdvertisementData(adv);

  BLEAdvertisementData adv2;
  //adv2.setName(devName.c_str());
  adv2.setCompleteServices(BLEUUID(SERVICE_UUID));
  pAdvertising->setScanResponseData(adv2);

  pAdvertising->start();

  Serial.println("Ready");
  Serial.print("Device name: ");
  Serial.println(devName);
}

void loop() {
  scheduler.execute();
}
