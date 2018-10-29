/* 
 
  Control an electromagnet over Arduino, using an RFP30N06LE N-Channel MOSFET

  Developed for Arduino Uno and the MOSFET Power Control Kit, COM-12959

  Created 2018
  by Robin van Emden

*/

int led = 13;
int mosfet_control = 10;
int button=2; 
int tone_control = 8;
int key_press = 0;

void setup()
{
  Serial.begin(9600);                                     // Turn the Serial Protocol ON
  pinMode(mosfet_control, OUTPUT);                        // Set control pins to be outputs
  pinMode(button, INPUT_PULLUP);                          // Set button
}

void loop()
{
   if (digitalRead(button) == LOW) {                    // if button press
    digitalWrite(led, HIGH);                            // Turn LED on on Arduino
    for ( int x = 0; x < 10; x++ ) {                    // 10 pulses of 500 ms
      analogWrite(mosfet_control, 255);                 // Full power
      tone( tone_control, 1000, 500);                   // Beep for 500ms (while magnet on) 
      Serial.println("Magnets +++ on  +++");
      delay(500);
      analogWrite(mosfet_control, 0);                   // Power off
      Serial.println("Magnets --- off ---");
      delay(500);
    }
    Serial.println("### ready ###");
    digitalWrite(led, LOW);                             // Turn LED off on Arduino
  }
}

