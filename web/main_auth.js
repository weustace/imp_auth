var nonce = ""; //bad practice to store security stuff in global jscript vars...but this is only a proof of concept!
var UID = -1;
var led_state = 0;
var agent_url = " "; //make this global so we know where to send the logout and other requests
$(document).ready(function(){
	$("#after_auth").hide();//bind handler for hiding after_auth block on page load
	$("#login_button").click(sendInitialLoginTransaction);//and handler for login button click
	$("#auth_block").keypress(function(event){//and a handler to select 'Login' if enter is pressed - workaround
		if(event.which == 13)
		 sendInitialLoginTransaction();});
	$("#led_checkbox").change(setLED);
	$("#update_led_button").click(checkLEDStatus);
	var usr_cookie = $.cookie('eimp_auth_url+uname');//check for a user cookie storing username+password
	if(typeof usr_cookie != undefined){
		var usr_data = JSON.parse(usr_cookie);
		$("#agent_url_field").val(usr_data.url);
		$("#username_field").val(usr_data.user);
	}//if it's there, put the values in.
	}); 

function sendInitialLoginTransaction(){
	agent_url = $("#agent_url_field").val();
	var entered_username = $("#username_field").val();
	var entered_password = $("#password_field").val();
	//store a cookie with username and url
	var cookie_obj = {"url":agent_url,"user":entered_username};
	cookie_obj = JSON.stringify(cookie_obj);
	$.cookie('eimp_auth_url+uname', cookie_obj);
	var query_object = { newClient:"true", username:entered_username, password:entered_password };
	$.ajax(
	agent_url,//agent url
	//settings
	{
	data:JSON.stringify(query_object),
	type:'POST',
	complete:handleInitialLoginResponse,
	timeout:2000
	});
}

function handleInitialLoginResponse(event,desc){
	if(event.status==200){
		var respObj = JSON.parse(event.responseText);
		if(typeof respObj.uid != undefined){
			UID = respObj.uid;
			nonce = respObj.nonce.toString();//store our response object stuff in global vars
		
			//clear the user interface
			$("#auth_block").slideUp("slow");
			//show a new pane, containing whatever you want to do after auth.
			$("#after_auth").slideDown("slow");
			$("#logout_button").click(logout);//register logout button handler
			$("#password_field").val("");
			//update led state
			checkLEDStatus();
		}
		else alert("Valid response but bad data returned. Wrong URL?");
	}
	else{
		if(event.status == 401){
			alert("Authentication failed - wrong username or password.");}
		else alert("Failure. Try other URL?");
	}
}
function logout(){
	var query_object = {logout:1};
	sendTransaction(query_object, function(){
		console.log("Logged out.");
		$("#after_auth").slideUp("fast");
		$("#auth_block").show();});
}	
	
function checkLEDStatus(){
	var qo = {"led":"?"};
	sendTransaction(qo, function(event){
	var respObj = {};
	if(event.status == 200){//if the request went alright
		respObj = JSON.parse(event.responseText);//parse it out, then update the nonce and update the checkbox
		nonce = respObj.nonce;
		if(respObj.led==1) {$("#led_checkbox").prop("checked",true);}
		else $("#led_checkbox").prop("checked",false);
	}
	else{//otherwise, auth is clearly a problem, so let's reauthenticate!
		alert("Authentication problem. Please log in again.");
		logout();
	}
	});
}

function setLED(){
		var led_status = 0;
		if($("#led_checkbox").prop("checked")) led_status = 1;
		var qo = {"led":led_status};
		sendTransaction(qo, genericResponseHandler);
}

function sendTransaction(query_object, callback_function){
	query_object.newClient = "false";
	query_object.nonce = nonce;//responsibility for updating the nonce falls on the callback function.
	query_object.uid = UID;	
	
	$.ajax(
	agent_url,//agent url
	//settings
	{
	data:JSON.stringify(query_object),
	type:'POST',
	complete:callback_function
	});
}	

function genericResponseHandler(event){
	if(event.status == 200){//if all went well
		var rp = JSON.parse(event.responseText);
		nonce = rp.nonce;
	}
	if (event.status == 451){//session timeout (or invalid nonce)
		alert("Session timeout");
		logout();
	}
	else if (event.status != 200 && event.status != 451){
		alert("Unknown issue - " + event.status + ". Please try again. If it still does not work, contact admin.");
		logout();
	}
}
