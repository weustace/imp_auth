/* Authentication servo code - William Eustace 16.1.14.
ALMOST CERTAINLY NOT CRYPTOGRAPHICALLY SECURE - USES OPEN AUTHENTICATION AND CODE DOUBTLESS HAS HOLES. Even worse, it doesn't use any recognised cryptographic algorithm
for its nonces!
USE AT YOUR OWN RISK - NOT FOR IMPORTANT THINGS */

local current_status = 0;
correct_username <- "me";
correct_password <- "password";
current_user_ids <- [];
current_user_timings <- [];
session_expiry_time <- 300;
function reAuthenticate(usrtoken,uid){
    if (usrtoken != 0){
      if (usrtoken != null){
        uid=uid.tointeger();
        if(uid in current_user_ids){
        local time_elapsed = time() - current_user_timings[uid];
        server.log("Session age (s): "+ time_elapsed);
        if(usrtoken == current_user_ids[uid] && time_elapsed < session_expiry_time){//we want to expire sessions after 5 mins (300s)
          //generate new user code
          //assign new user code
          local replacement_user_code = userCodeGen();
          current_user_ids[uid] = replacement_user_code;
          current_user_timings[uid] = time();
          return replacement_user_code 
        }       
        else {
          if(time_elapsed >= session_expiry_time){//session expired
          server.log("Session expired.");
          current_user_ids[uid] = -1;//set the nonce to -1 to invalidate the login and 
          //flag it for future use.
          }
          return false
        }
    }}
  }
}

function userCodeGen(){
  //all integers except 'output' which is a string
  local output = "";
  local x = 0;//random value a
  local y = 0;//random value b
  local b =0;//working variable
  RAND_MAX <- 600
  for(local i=0;i<4;i++){
      b = i + (b* math.rand());
      RAND_MAX <- b;
      x = math.rand();
      b = b % x;
      b = 1000 - b;
      RAND_MAX <- b;
      y = math.rand();
      b = x % y;
      b = b ^ y;
      output += x;
      output += y;    
  }
  return output
}

function userIDGen(){//this needs to find if any lower number ones are unallocated
  local user_id = -1;
  foreach(current_uid,current_nonce in current_user_ids){
    if(current_nonce==-1){
      //user slot is vacant
      user_id = current_uid; //so assign it
      return user_id
    }
  }//otherwise
  user_id = current_user_ids.len();
  if(user_id==1){
    current_user_ids.resize(2);
    current_user_timings.resize(2);
  }
  else{
    current_user_ids.resize(user_id+1);
  }
  return user_id
}

function authenticate(username, password){
  if(username == correct_username && password == correct_password){
    local userData = {"nonce": userCodeGen(), "uid": userIDGen()};
    current_user_timings.insert(userData.uid,time());
    current_user_ids[userData.uid] = userData.nonce;//store user nonce and current time in respective arrays. Minimise danger of failure to log out.
    server.log("authentication successful!");
    return userData
  }
  else {
    return false    
  }
}

function logout(uid){
  current_user_timings[uid] = -1;
  current_user_ids[uid] = -1;//flag both for reuse
}
function sweep_sessions(){
  foreach(uid, time_logged in current_user_timings){
    local time_elapsed = time() - time_logged;
    if(time_elapsed > session_expiry_time){//if sessions older than 10 minutes
      logout(uid);
    }
    server.log("Sessions swept.");
  }
  imp.wakeup(120,sweep_sessions);//sweep sessions every two minutes
}
function actionRequest(req,token,resp){//decoded request, reauth token, response
 if("logout" in req){
   logout(req.uid);
   resp.header("Content-Type", "text/html");//send headers 
   resp.send(250, "Logged out.");//custom code
   server.log("Logged out user "+req.uid)
   return true
 }
 if ("led" in req){
   if(req.led == "?"){
    resp.header("Content-Type", "text/json");
    local response_data = {"nonce":token, "led":current_status};
    response_data = http.jsonencode(response_data);
    resp.send(200,response_data);
   }
   else{
    switchLED(req.led.tointeger());
    resp.header("Content-Type","text/json");
    local response_data = {"nonce":token, "led":current_status};
    response_data = http.jsonencode(response_data);
    resp.send(200, response_data);}
    
 }
}
function handleHTTPRequest(req, resp){
  server.log(http.jsonencode(req.body));
resp.header("Access-Control-Allow-Origin", "*");
if(req.method == "POST"){
  local decoded_request = http.jsondecode(req.body);
    if("newClient" in decoded_request){//if this isn't there, it's a malformed request. I say so.
    if(decoded_request.newClient == "true" && "username" in decoded_request && "password" in decoded_request){//if it's a new user and they haven't sent a username and password... bad request
     local new_user_data = authenticate(decoded_request.username, decoded_request.password);//will return false if validation success, otherwise an array
    //  If it's a new client, we need to authenticate it.
      if(new_user_data){
        local jsonobj = http.jsonencode(new_user_data);
        resp.header("Content-Type","text/json");//parcel up array and send it off
        resp.send(200, jsonobj);
      }
     else {
       resp.header("Content-Type","text/html");//parcel up array and send it off
       resp.header("Access-Control-Allow-Origin", "*");
       resp.send(401, "Wrong username or password");
       server.log("Wrong username/password.")
      }
    }
    else{
      if("newClient" in decoded_request == "true")
        resp.send(400,"No username or password offered");
      else{
        if("uid" in decoded_request && "nonce" in decoded_request){
          local reAuth = reAuthenticate(decoded_request.nonce,decoded_request.uid);
          if(reAuth){
            server.log("reauth success");
            //call function to check for other stuff in the request here
            actionRequest(decoded_request, reAuth, resp);
          }
          else
            resp.send(451, "Session timed out or invalid nonce.");//send a timeout status code - custom. Using 451         
        }
      }
    }
  }
  else {
    resp.send(400,"No newClient index sent");
    server.log("no newclient");
  }
}}

sweep_sessions();//expire sessions which are more than 20 mins old.
http.onrequest(handleHTTPRequest);//bind http request handler

//Auth and HTTP stuff done, now for action code! ===============================

function switchLED(led_state){
  device.send("LED", led_state);
  current_status = led_state;
  if(current_status == 1){
    server.log("On");
  }
  else server.log("Off");
}