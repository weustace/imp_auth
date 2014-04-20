var nonce = ""; //bad practice to store security stuff in global jscript vars...but this is only a proof of concept!
var UID = -1;
var page_state = 0;// 0 = auth setup, 1 = after auth
var agent_url = " "; //make this global so we know where to send the logout and other requests
$(document).ready(function(){
	$("#after_auth").hide();//bind handler for hiding after_auth block on page load
	$("#login_button").click(sendInitialLoginTransaction);//and handler for login button click
	$("#auth_block").keypress(function(event){//and a handler to select 'Login' if enter is pressed - workaround
		if(event.which == 13)
		 sendInitialLoginTransaction();});
	$("#led_checkbox").
	}); 

function sendInitialLoginTransaction(){
	agent_url = $("#agent_url_field").val();
	var entered_username = $("#username_field").val();
	var entered_password = $("#password_field").val();
	var query_object = { newClient:"true", username:entered_username, password:entered_password };
	$.ajax(
	agent_url,//agent url
	//settings
	{
	data:JSON.stringify(query_object),
	type:'POST',
	complete:handleInitialLoginResponse,

	});
}

function handleInitialLoginResponse(event,req){
	if(event.status==200){
		var respObj = JSON.parse(event.responseText);
		UID = respObj[1];
		nonce = respObj[0].toString();//store our response object stuff in global vars
	
		//clear the user interface
		$("#auth_block").slideUp("slow");
		//show a new pane, containing whatever you want to do after auth.
		$("#after_auth").slideDown("slow");
		$("#logout_button").click(logout);//register logout button handler
		$("#password_field").val("");
		//update page status
		page_state = 1;
	}
	else{
		if(event.status == 401)
			alert("Authentication failed - wrong username or password.");
	}
}
function logout(){
	var query_object = {logout:1};
	sendTransaction(query_object, function(){
		console.log("Logged out.");
		$("#after_auth").slideUp("fast");
		$("#auth_block").show();});
	}	


function sendTransaction(query_object, callback_function){
	query_object.newClient = "false";
	query_object.nonce = nonce;
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
