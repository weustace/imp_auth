var nonce = ""; //bad practice to store security stuff in global jscript vars...but this is only a proof of concept!
var UID = -1;
var page_state = 0;// 0 = auth setup, 1 = after auth
$(document).ready(function(){$("#after_auth").hide();$("#login_button").click(sendInitialLoginTransaction);}); //bind handler for hiding after_auth block on page load
//and handler for login button click

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
	complete:handleInitialLoginResponse,

	});
}
function handleAjaxError(xhr){
	console.log(xhr.status);
	if (xhr.status == 401){
		console.log("error stuff called");
		alert("Authentication Failure. Wrong username or password?");
		if(page_state == 1){
			$('#after_auth').slideUp("fast");
			$('#auth_block').slideDown("slow");//if auth failure, show login page again
			page_state = 0;
		}
	}
}
function handleInitialLoginResponse(event,req){
	
		if(event.status==200){
			var respObj = JSON.parse(event.responseText);
			UID = respObj[0];
			nonce = respObj[1];//store our response object stuff in global vars
		
			//clear the user interface
				$("#auth_block").slideUp("slow",function(){$("#auth_block").html("");});
			//show a new pane, containing whatever you want to do after auth.
			$("#after_auth").slideDown("slow");
			
			//update page status
			page_state = 1;
		}
		else{
			if(event.status == 401)
				alert("Authentication failed - wrong username or password.");
		}
	}
	
