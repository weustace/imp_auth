# Electric Imp authentication

The idea behind this was to provide a simple method of authentication for the [Electric Imp](http://electricimp.com/).  Consider it a cross between a proof of concept and an exercise - rather more the latter! It's been on the back burner for a couple of months, but recently I decided to finish it off. This is only a very basic example, and shows how to use it for switching an LED on and off. One of the non-cryptographic weaknesses which is obvious is that when switching the LED on and off rapidly using the checkbox the session will time out - this is actually because the client hasn't received the new token before sending another request - it is invalid and so the request is refused. Consider this to be a highly advanced system feature intended to stop server overload. **For those not initiated in cryptography, a ['nonce'](http://en.wikipedia.org/wiki/Cryptographic_nonce) refers to a token which is used only once. See linked Wikipedia article.**

**Warning:** this is not intended as a high-security system, and has been implemented by someone with little knowledge of good cryptography and authentication practices. Therefore, security sensitive applications, for instance opening your front door, are probably a very bad idea without correction. For instance, tokens are stored in JavaScript global variables, which I believe is poor practice. The most obvious weakness is the token generator - this uses basic and arbitrary techniques to string together several numbers from the built-in Squirrel random number generator - this is probably not secure. I direct you to http://happybearsoftware.com/you-are-dangerously-bad-at-cryptography.html

# Documentation:


## Electric Imp:

This is programmed in [Squirrel](https://electricimp.com/docs/resources/learningsquirrel/), which is rather like JavaScript or C in syntax. The ending for Squirrel files appears to be `.nut` and 
so I have used that here. The "Agent" is what runs on Electric Imp's servers and handles all of the web communication, before relaying this to the device, which has a separate code body running on it; interestingly, the file called "agent.nut" is the agent code, and "device.nut" is the device code.

### Agent side:

This is where all of the authentication side is done. Points to note overall:

* The auth system expires sessions when no activity has been registered for `session_expiry_time` - this is currently set to 300 s (i.e. 5 minutes.) 
* Anything which you want to be done after authentication goes in the `actionRequest` function. 


Function by function:

* `reAuthenticate(usrtoken,uid)` 
  * This takes a nonce `usrtoken` (these are very long numbers, and so are handled in string form) and a `uid` (an integer) and checks it.
  * This function should only be called, as the name suggests, when client identity has been proven once, and the client has been issued with a token
  * It looks up the user token in an array, and then checks that time elapsed since last communication is not greater than `session_expiry_time`
  * Then it issues a new token and returns it, if all is well. Otherwise it returns `false`

* `userCodeGen()`
  * This generates unique (or very nearly unique) user tokens, which are long strings.
  
* `userIDGen()`
  * This generates a user ID as an integer. It iterates over the array of UIDs/tokens and checks if any have been freed up (i.e. nonce value set to -1).
  * If not, it resizes the array and returns the array's length as UID. 

* `authenticate(username, password)`
  * As the name suggests, this function just checks if the username and password passed in are correct, gets token and UID and returns a JS-like object (key/value pairs) with the nonce and UID, or `false` if authentication failed.
  
* `logout(uid)`
  * Once again, does what it says on the tin. Sets flags in user timing and nonce arrays to -1, marking them for reuse.
  
* `sweep_sessions()`
  * Checks for expired sessions and logs them out.
  
* `actionRequest(req,token,resp)`
  * This is the function where the code you want to be executed after authentication should be placed, or at least called. It is also where the check for 'logout' is made.
  * You need to send a response after you've finished, not forgetting to set the content type. If your function doesn't send the response, you **must** return `false` to  get the rest of the code to do so. 
  
* `handleHTTPRequest(req, resp)`
  * The HTTP request handler, which you can probably work out from the logic flow. 
  * The only thing which is important is that you need to send an index with each request (even after initial auth) containing the key-value pair `{"newClient":"false"}`
  
* `switchLED(led_state)`
 * Once again, does what it says on the tin.
 
### Device side:

This is obvious, and needs little explanation - it just receives the message from the agent regarding LED state, and sets the LED state accordingly. LED pin is currently pin 2.

## Web side:

The login form is currently implemented in HTML and JavaScript, the latter leaning heavily on jQuery. The HTML form has two sections - `auth_block` and `after_auth`. These are contained in divs. 
The login form itself uses jQuery to attach a button handler, since it is not actually contained in a `<form>` object. 

### JavaScript:

All non-library JS for this project (i.e. everything written by me) is in main_auth.js.

* The initial function binds events to actions, and is fairly self-explanatory. It is executed when the DOM has loaded. The only thing of interest which it does is check for an Agent URL/username containing cookie and load these fields from it if one is found.

* The initial login transaction is different to the rest in terms of fields sent - therefore it has its own functions. Once again, the only thing of note is that the login response stores agent URL and username in a cookie. After login, the login form is hidden and the `after_auth` block is shown. At some point, these could probably be slimmed down to use the standard functions defined later, with some tweaks to these.

* `logout()` attempts to log out. Simple, really. NB the system requires a nonce to terminate a user session, but if this is called with an incorrect one, it still sends the request. 

* `checkLEDStatus()` does what the name suggests, and updates the checkbox accordingly. It is called after authentication, to update the box. 
  * When the query body contains `led : ?`, the system will respond with the LED state **without** changing system state. 
  
* `setLED()` gets the LED state from the checkbox and sends it. 

* `sendTransaction(query_object, callback_function)`
 * `query_object` is the current query object, to which nonce etc will be added. 
 * `callback_function` is the function to be registered for the AJAX complete event. This function will have the standard params passed in - see jQuery $.ajax() docs. This can call the next function:
 
* `genericResponseHandler(event)` once it has done whatever it wants with the event object, (short of modifying it), your function can pass the xhr obj to this function and it will do error checking and make a note of the new nonce.



I hope it works well for you!
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
