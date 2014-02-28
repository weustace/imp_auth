
function sendInitialLoginTransaction(){
	var agent_url = $("#agent_url_field").val();
	var entered_username = $("#username_field").val();
	var entered_password = $("#password_field").val();
	$.post(agent_url, newClient=true&username=entered_username&password=entered_password,handleInitialLoginResponse(data),"json");
}
function handleInitialLoginResponse(data){}
