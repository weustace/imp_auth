var nonce = ""; //bad practice to store cryto stuff in global jscript vars...but this is only a proof of concept!
var UID = -1;

function sendInitialLoginTransaction(){
	var agent_url = $("#agent_url_field").val();
	var entered_username = $("#username_field").val();
	var entered_password = $("#password_field").val();
	var query_object = { newClient:"true", username:entered_username, password:entered_password };
	$.ajax(
	agent_url,//agent url
	//settings
	{
	data:JSON.stringify(query_object),
	type:'POST',
	statusCode:
		{
		401:function(){alert("Bad username or password.");},
		
		},
	complete:handleInitialLoginResponse
	}
	);
}
function handleInitialLoginResponse(event,req){
		var respObj = JSON.parse(event.responseText);
		UID = respObj[0];
		nonce = respObj[1];//store our response object stuff in global vars
		
		//clear the user interface
		$("#auth_block").slideUp("slow",function(){$("#auth_block").html("");});
		//draw a new pane.
		
	}
