#include <FlexiTimer2.h>
#include <Wire.h>
#include "digitalWriteFast.h"

int address = 114;
int pinA = 9;
int pinB = 8;
byte pinAS = 1;
byte pinBS = 0;
int errcnt;
word countersprev[4];
word counters[4];

void setup()
{
    pinModeFast(pinA, OUTPUT);
    pinModeFast(pinB, OUTPUT);
    digitalWriteFast(pinA, HIGH);
    digitalWriteFast(pinB, LOW);
  
    Wire.begin();
    TWBR = 12;
  
    Serial.begin(115200);
    Serial.println("Verilog I2C Test\n\n");
  
    reset();
    delay(100);
  
    FlexiTimer2::set(1, 1.0/16, callback); 
    FlexiTimer2::start();
}

void callback()
{
    if ((pinAS == 1) && (pinBS==0))
    {
        pinBS = 1;
        digitalWriteFast(pinB, HIGH);
    }  
    else if ((pinAS == 1) && (pinBS==1))
    {
        pinAS = 0;
        digitalWriteFast(pinA, LOW);
    }
    else if ((pinAS == 0) && (pinBS==1))
    {
        pinBS = 0;
        digitalWriteFast(pinB, LOW);
    }
    else if ((pinAS == 0) && (pinBS==0))
    {
        pinAS = 1;
        digitalWriteFast(pinA, HIGH);
    }
}

void reset()
{
    for (int i = 0; i < 4; i++)
    {
        countersprev[i] = 0;
        counters[i] = 0;
    }
  
    errcnt = 0;
  
    for (int i = 0; i < 4; i++)
    {
        countersprev[i] = 0;
        counters[i] = 0;
    }
  
    Wire.beginTransmission(address);
    Wire.write(1);
    int error = Wire.endTransmission(); 
}

bool readCounters()
{
    byte valuesread[8];
    word countersread[4];
    byte readcnt = 0;
    bool rslt = false;
  
    Wire.beginTransmission(address);
    Wire.write(0);
    int error = Wire.endTransmission();   
  
    //Read values    
    if (error == 0)
    {
        byte count = Wire.requestFrom(address, 8);
        
        if (count == 8)
        {
            for (int i = 0; i < 8; i++)
                valuesread[i] = Wire.read();
          
            rslt = true;
        }
        else rslt = false;
    }
    else rslt = false;
  
    if (rslt)
    {
        //Assemble values
        for (int i = 0; i < 8; i++)
        {
          byte readv = Wire.read();
          
          if (i % 2 == 1) 
              countersread[(byte)floor(i / 2)] = countersread[(byte)floor(i / 2)] + valuesread[i];
          else countersread[(byte)floor(i / 2)] = valuesread[i] << 8;
      }
  
      //Validate values
//      for (int i = 0; i < 4; i++)
//      {
//          long iprediff = counters[i] - countersprev[i];
//          word prediff = 0;
//          
//          if (iprediff < 0)
//            prediff = 65535 + iprediff;
//          else prediff = iprediff;
//          
//          long idiff = countersread[i] - counters[i];
//          word diff = 0;
//          
//          if (idiff < 0)
//            diff = 65535 + idiff;
//          else diff = idiff;
//          
//          double diffweight = abs(diff / prediff);
//        
//          if (diffweight > 2)
//            rslt = false; 
//      }
    
      //Copy values across
      //if (rslt)
      //{
          for (int i = 0; i < 4; i++)
          {
            countersprev[i] = counters[i];
            counters[i] = countersread[i];  
          }
        
      //}
    }
  
    if (!rslt)
       errcnt++;
  
    return rslt;
}

void loop()
{
    unsigned long time = millis();
    readCounters();
  
    Serial.print("Counts:\t");
    Serial.print(counters[0]);
    Serial.print("\t");
    Serial.print(counters[1]);
    Serial.print("\t");
    Serial.print(counters[2]);
    Serial.print("\t");
    Serial.print(counters[3]);
    Serial.print("\t");
    Serial.println(errcnt);
   
    unsigned long time2 = millis();
  
    delay(50 - (time2 - time));
}

