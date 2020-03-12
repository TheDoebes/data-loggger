#include <Wire.h>

// A4 (SDA), A5 (SCL)
// 5v VCC, GND to Vss

void setup()  // Read one page
{
  Serial.begin(9600);
  Wire.begin();

  //set the device internal pointer to zero
  Wire.beginTransmission(80); // transmit to device #80 (7'b1010000)
                             // device address is specified in datasheet
  Wire.write(0);             // sends hi byte
  Wire.write(0);            //  sends lo byte
  Wire.endTransmission();     // stop transmitting

  delay(500);

  //pull the first half of the page
  Wire.requestFrom(80, 32);

  while(Wire.available())
  {
    Serial.println(Wire.read());
  }

  delay(500);
  //pull the second half of the page
  Wire.requestFrom(80, 32);

  while(Wire.available())
  {
    Serial.println(Wire.read());
  }

}

void loop() //don't do anything 
{


}
