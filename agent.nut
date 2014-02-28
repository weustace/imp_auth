/* Authentication servo code - William Eustace 16.1.14.
ALMOST CERTAINLY NOT CRYPTOGRAPHICALLY SECURE - USES OPEN AUTHENTICATION AND CODE DOUBTLESS HAS HOLES. Even worse, it doesn't use any recognised cryptographic algorithm
for its nonces!
USE AT YOUR OWN RISK - NOT FOR IMPORTANT THINGS */

local current_status = 0;
correct_username <- "me";
correct_password <- "password";
current_user_ids <- [];
current_user_timings <- [];
function reAuthenticate(usrtoken,uid){
    if (usrtoken != 0){
      if (usrtoken != null){
        uid=uid.tointeger();
        if(uid in current_user_ids){
        local time_elapsed = clock() - current_user_timings[uid];
        if(usrtoken == current_user_ids[uid] && time_elapsed < 1200){//we want to expire sessions after 20 mins (1200 secs)
          //generate new user code
          //assign new user code
          local replacement_user_code = userCodeGen();
          current_user_ids[uid] = replacement_user_code;
          current_user_timings[uid] = time();
          return replacement_user_code 
        }       
        else {
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

function userIDGen(){
  local user_id = current_user_ids.len();
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
  server.log(username + " and "+password)
  if(username == correct_username && password == correct_password){
    local userData = [userCodeGen(),userIDGen()];
    current_user_timings.insert(userData[1],time());
    current_user_ids[userData[1]] = userData[0];//store user nonce and current time in respective arrays. Minimise danger of failure to log out.
    server.log("authentication successful!");
    return userData
  }
  else {
    return false    
  }
}

function handleHTTPRequest(req, resp){
  server.log(http.jsonencode(req.query));
//if(req.method == "POST"){
server.log("Request received.")
  if("newClient" in req.query){//if this isn't there, it's a malformed request. I say so.
    if(req.query.newClient == "true" && "username" in req.query && "password" in req.query){//if it's a new user and they haven't sent a username and password... bad request
     local new_user_data = authenticate(req.query.username, req.query.password);//will return false if validation success, otherwise an array
    //  If it's a new client, we need to authenticate it.
      if(new_user_data){
        local jsonobj = http.jsonencode(new_user_data);
        resp.header("content-type","text/json");//parcel up array and send it off
        resp.send(200, jsonobj);
      }
     else {
       resp.send(401, "Wrong username or password");
      }
    }
    else{
      if("newClient" in req.query == "true")
        resp.send(400,"No username or password offered");
      else{
        if("uid" in req.query && "nonce" in req.query){
          local reAuth = reAuthenticate(req.query.nonce,req.query.uid);
          if(reAuth){
            //call function to check for other stuff in the request here
            server.log("You have reached Nirvana, or the incredibly amateur cryptographer's equivalent.")
            //now, just send a response saying all is well
            resp.header("content-type","text/json");
            resp.send(200,http.jsonencode(reAuth));//issue a 200 and a new nonce.
          }
          else
            resp.send(419, "Hard cheese.");//send a timeout status code          
        }
      }
    }
  }
  else {
    resp.send(400,"No newClient index sent");
    
  }
}//}


http.onrequest(handleHTTPRequest);
