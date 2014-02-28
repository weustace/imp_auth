servo <- hardware.pin1;
servo.configure(PWM_OUT, 0.02, 0.1);
function getDutySetting(angle){
    //function to find the correct duty setting
  

   local duty = angle * (1.0/180.0);//scale to a number between 0 and 1
    duty = duty / (9000.0/800);//scale further
    duty = duty + 0.019;
   return duty
}

function setServo(setting){
    local duty = 0;
    duty = getDutySetting(setting);
   server.log("Duty cycle:");
    server.log(duty)
    servo.configure(PWM_OUT, 0.02, duty);
  }
agent.on("angle",setServo);//listener function
