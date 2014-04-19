
function sendInitialLoginTransaction(){
	var agent_url = $("#agent_url_field").val();
	var entered_username = $("#username_field").val();
	var entered_password = $("#password_field").val();
	var query_string = "newClient=true&username=" + entered_username + "&password=" + entered_password;
	$.ajax(
	agent_url,//agent url
	//settings
	{
	data:query_string,
	type:'POST',
	traditional:'true'
	}
	);
}
function handleInitialLoginResponse(data){}
