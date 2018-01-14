// Copyright 2018 Gustav Pettersson, gustavpettersson@live.com
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



#include <ADC.h>            //https://github.com/pedvide/ADC
#include <EEPROM.h>         //https://www.arduino.cc/en/Reference/EEPROM
#include <LiquidCrystal.h>  //https://www.arduino.cc/en/Reference/LiquidCrystal

int DeviceID = EEPROM.read(0); //Keep unique ID in first index of EEPROM

//Lookup tables used to set the IV curve
uint16_t LookupA[4096] = {0};
uint16_t LookupB[4096] = {0};

//Start with active pointer on LookupA
uint16_t* activeLookup = &LookupA[0];
uint16_t* inactiveLookup = &LookupB[0];

uint16_t DACvalue = 0;
uint16_t ADCvoltvalue = 0;
uint16_t ADCcurrvalue = 0;

uint16_t newValue = 0;
bool byteValid = true;
bool arrayValid = true;

bool LEDActive = false;
bool printValues = false;
elapsedMillis sincePrint;

const int ADCvolt = A3;
const int ADCcurr = A4;
ADC *adc = new ADC();

const int DACPin = A14;
IntervalTimer samplingTimer;
IntervalTimer displayTimer;

LiquidCrystal lcd(0, 1, 2, 3, 4, 5, 6, 7, 8, 11);

void setup() {
  Serial2.begin(115200);
  Serial2.setTimeout(10); //String read timeout 10 ms
  pinMode(LED_BUILTIN,OUTPUT);
  analogWriteResolution(12);
  analogReference(INTERNAL); //INTERNAL is 1.195V 0.5%. EXTERNAL is 3.3V.
  pinMode(ADCvolt,INPUT);
  pinMode(ADCcurr,INPUT);
  
  //adc->analogRead(ADCvolt,ADC_1);
  //adc->analogRead(ADCcurr,ADC_0);
  
  adc->setResolution(12,ADC_0);
  adc->setAveraging(16,ADC_0);
  adc->setSamplingSpeed(ADC_SAMPLING_SPEED::LOW_SPEED,ADC_0);
  adc->setReference(ADC_REFERENCE::REF_1V2,ADC_0);
  adc->setResolution(12,ADC_1);
  adc->setAveraging(16,ADC_1);
  adc->setSamplingSpeed(ADC_SAMPLING_SPEED::LOW_SPEED,ADC_1);
  adc->setReference(ADC_REFERENCE::REF_1V2,ADC_1);
  
  pinMode(DACPin,OUTPUT);
  analogWrite(DACPin, 0);

  lcd.begin(8,2);
  lcd.write("U= 0.00V");
  lcd.setCursor(0,1);
  lcd.write("I=0.000A");

  samplingTimer.priority(128);
  samplingTimer.begin(update, 1000); //Update every 1 ms
  displayTimer.priority(255);
  displayTimer.begin(writeLCD, 500000); //Update every 500 ms
}

void writeLCD() {
  char voltage[5];
  sprintf(voltage, "%*.2f", 5, ADCvoltvalue/186.2);
  char current[5];
  sprintf(current, "%*.3f", 5, ADCcurrvalue/1881.3);
  lcd.setCursor(2,0);
  lcd.write(voltage);
  lcd.setCursor(2,1);
  lcd.write(current);
}

void update() {
  ADCvoltvalue = adc->analogRead(ADCvolt,ADC_1);
  ADCcurrvalue = adc->analogRead(ADCcurr,ADC_0);
  //Check that first four bits are zero (i.e. we have 12 bit number in the 16 bit uint)
  if ( !(ADCvoltvalue & 0xF000) ) { 
    DACvalue = *(activeLookup+ADCvoltvalue);
    analogWrite(DACPin, DACvalue);
    if (printValues && sincePrint>100) {
      sincePrint = 0;
      char voltage[5];
      sprintf(voltage, "%*.2f", 5, ADCvoltvalue/186.2);
      char current[5];
      sprintf(current, "%*.3f", 5, ADCcurrvalue/1881.3);
      Serial2.print("ADC volt: ");
      Serial2.print(voltage);
      Serial2.print(" ADC curr: ");
      Serial2.print(current);
      Serial2.print(" DAC: ");
      Serial2.print(DACvalue);
      Serial2.print(" ADC: ");
      Serial2.println(ADCvoltvalue);
    }
  }
}

void loop() {
  if (Serial2.available() > 0) {
    String task = Serial2.readString();
    if (task.substring(0,1).equals("W")) {        //Who
      Serial2.print("SPS\n");
    } else if (task.substring(0,1).equals("V")) { //Verison
      Serial2.print("1\n");
    } else if (task.substring(0,1).equals("P")) { //Print values
      printValues = true;
    } else if (task.substring(0,1).equals("H")) { //Stop printing
      printValues = false;
    } else if (task.substring(0,1).equals("T")) { //Dump tables
      for (int i=0; i<4096; i+=256) {
        Serial2.println(*(activeLookup+i));
        Serial2.println(*(inactiveLookup+i));
      }
    } else if (task.substring(0,1).equals("I")) { //Get ID
      Serial2.print(DeviceID);
      Serial2.print("\n");
    } else if (task.substring(0,1).equals("S")) { //Set ID
      int setID = task.substring(1).toInt();
      if (setID > 0 && setID < 256) {
        EEPROM.write(0,setID);
        DeviceID = setID;
        Serial2.println("ID set!");
      }
    } else if (task.substring(0,1).equals("D")) { //Set lookup table
      // This is where the fun begins, we are getting data!
      LEDActive = true;
      digitalWrite(LED_BUILTIN,HIGH);
      Serial2.print("OK\n"); //Acknowledge we are ready for the transfer
      arrayValid = true;
      //Wait for the buffer to fill with the data
      unsigned long startTime = millis();
      while(Serial2.available() < 8192) {
        if ( (millis() - startTime)>5000 ) {
          arrayValid = false;
          break;
        }
      }
      if (arrayValid) {
        for (int i=0; i<4096; i++) {
          //Clear variable
          newValue = 0;
          byteValid = true;
          //Read MSBs and insert
          uint8_t msb = Serial2.read();
          if ( !(msb>>6 ^ B10) ) { //Check identifier
            msb = msb & B00111111; //Remove identifier
          } else {byteValid = false;}
          //Read LSBs and insert
          uint8_t lsb = Serial2.read();
          if ( !(lsb>>6 ^ B01) ) { //Check identifier
            lsb = lsb & B00111111; //Remove identifier
          } else {byteValid = false;}
          if (byteValid) {
            *(inactiveLookup + i) = msb<<6 | lsb; //Put new value in inactive array
          } else {
            Serial2.println("Read Error");
            arrayValid = false;
            break;
          }
        }
      }
      //Switch the active/inactive pointers if all went as planned
      if (arrayValid) {
        noInterrupts();
        uint16_t* temp = activeLookup;
        activeLookup = inactiveLookup;
        inactiveLookup = temp;
        interrupts();
        Serial2.print("F\n"); //Acknowledge we are done with the transfer
      }
      else {
        Serial2.println("Read Error at End"); //Something failed
      }
    }
  } else {
    //Keep LED at 50% duty cycle with unused CPU time
    if (LEDActive) {
      LEDActive = false;
      digitalWrite(LED_BUILTIN,LOW);
    } else {
      LEDActive = true;
      digitalWrite(LED_BUILTIN,HIGH);
    }
  }
}
