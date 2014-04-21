led <- hardware.pin2

function switchLED(led_state){
  led.write(led_state);//done!
  
}
led.configure(DIGITAL_OUT);
//Listener function
agent.on("LED", switchLED);