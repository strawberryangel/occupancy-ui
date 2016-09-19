integer LISTEN_CHANNEL = 9283749237;
string COMMAND_LIST_ALL = "all";
string COMMAND_LIST_ROOM = "room";
string COMMAND_ADD = "add";
string COMMAND_DELETE = "remove";

// Copied from server, for reference if the exact numbers are wanted.
// Each API call returns its own 2xx success code.
integer SUCCESS_ALL = 299;
integer SUCCESS_ROOM = 298;
integer SUCCESS_ADD = 297;
integer SUCCESS_DELETE = 296;

string PRODUCTION_URL = "http://162.243.199.109:3001";
string DEVELOPMENT_URL = "http://192.241.153.101:3001";

///////////////////////////////////////////////////////////////////////////////
//
// Configuration Options
//
///////////////////////////////////////////////////////////////////////////////

string baseUrl = PRODUCTION_URL;
integer DEBUG = FALSE; // Set to true to include debugging information.

///////////////////////////////////////////////////////////////////////////////
//
// HTTP Handlers
//
///////////////////////////////////////////////////////////////////////////////

addOccupant(string roomNumber, string agent)
{
	string url = baseUrl + "/api/room";
	list HTTP_PARAMS = [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
		HTTP_BODY_MAXLENGTH, 16384
			];
	string body = "number=" + llEscapeURL(roomNumber) + "&agent=" + llEscapeURL(agent);

	debug("Post " + url + " body:  " + body);
	llHTTPRequest(url, HTTP_PARAMS, body);
}

getFullOccupancyList()
{
	string url = baseUrl + "/api/room";
	list HTTP_PARAMS = [
		HTTP_METHOD, "GET",
		HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
		HTTP_BODY_MAXLENGTH, 16384
			];

	debug("Get " + url);
	llHTTPRequest(url, [], "");
}

getRoomOccupancy(string roomNumber)
{
	string url = baseUrl + "/api/room/" + roomNumber;
	list HTTP_PARAMS = [
		HTTP_METHOD, "GET",
		HTTP_MIMETYPE, "application/x-www-form-urlencoded;charset=utf-8",
		HTTP_BODY_MAXLENGTH, 16384
			];

	debug("Get " + url);
	llHTTPRequest(url, [], "");
}

removeOccupant(string roomNumber, string agent)
{
	string url = baseUrl + "/api/room/" + llEscapeURL(roomNumber) + "/" + llEscapeURL(agent);
	list HTTP_PARAMS = [HTTP_METHOD, "DELETE"];
	
	debug("Delete " + url);
	llHTTPRequest(url, HTTP_PARAMS, "");
}

///////////////////////////////////////////////////////////////////////////////
//
// Helper Functions
//
///////////////////////////////////////////////////////////////////////////////

debug(string message)
{
	if(DEBUG) llOwnerSay(message);
}

processMessage(string  message)
{
	// llSay(PUBLIC_CHANNEL, "processMessage: " + message);
	if(message == COMMAND_LIST_ALL) {
		getFullOccupancyList();
		return;
	}

	if(llGetSubString(message, 0, llStringLength(COMMAND_LIST_ROOM)-1) == COMMAND_LIST_ROOM){
		string room = llGetSubString(message, llStringLength(COMMAND_LIST_ROOM)+1, -1);
		getRoomOccupancy(room);
		return;
	}

	if(llGetSubString(message, 0, llStringLength(COMMAND_ADD)-1) == COMMAND_ADD){
		list values = llParseString2List(llGetSubString(message, llStringLength(COMMAND_ADD)+1, -1), ["|"], []);
		string room = llList2String(values, 0);
		string agent = llList2String(values, 1);
		addOccupant(room, agent);
	}

	if(llGetSubString(message, 0, llStringLength(COMMAND_DELETE)-1) == COMMAND_DELETE){
		list values = llParseString2List(llGetSubString(message, llStringLength(COMMAND_DELETE)+1, -1), ["|"], []);
		string room = llList2String(values, 0);
		string agent = llList2String(values, 1);
		removeOccupant(room, agent);
	}
}

default
{
	http_response(key request_id, integer status, list metadata, string body)
	{
		llMessageLinked(LINK_SET, status, body, NULL_KEY);
	}
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == LISTEN_CHANNEL) processMessage(message);
	}
}
