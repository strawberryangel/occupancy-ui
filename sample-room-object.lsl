integer OCCUPANCY_API_ID = 9283749237;

// API commands.
string COMMAND_LIST_ROOM = "room";
string COMMAND_ADD = "add";
string COMMAND_DELETE = "remove";

vector textColor = <0.5, 0, 0>;
float textAlpha = 0.7;

integer dialogChannel; // This MUST be different for each room.

string getRoomNumber()
{
	// http://wiki.secondlife.com/wiki/LlGetObjectDesc
	// Important: This function does not get the description of the object's rootprim,
	// but the description of the prim containing the script.
	// Please use
	//
	//    llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_DESC ]), 0);
	//
	// instead.
	return llGetObjectDesc();
}

parseBody(string body)
{
	if(body == "") return;

	// This function displays the occupant information. 

	// Header
	string result = "\nRoom " + getRoomNumber() + "\n";

	// Get the list of user names and dates that the server sent.
	list lines = llParseStringKeepNulls(body, ["\n"], []);
	integer count= llGetListLength(lines);
	while(--count >= 0)
	{
		string line = llList2String(lines, count);
		list parts = llParseStringKeepNulls(line, [";"], []);
		if(llGetListLength(parts) == 5)
			result += llList2String(parts, 2) + " " + llList2String(parts, 4) + "\n";
	}

	// Publish the information.
	// This can be any method you wish. 
	
	llWhisper(PUBLIC_CHANNEL, result);
	// If you want to display on the object, this is a simple possibility.
	// llSetText(result, textColor, textAlpha);
}

showDialog(key whoTouched)
{
	string message = "\nRoom Management\n\nDo you want to: \n* Add yourself to this room\n* Remove yourself\n\nOr you just can't keep your fingers to yourself?\n";
	list buttons = ["Add", "Remove", "Nevermind"];

	llDialog(whoTouched, message, buttons, dialogChannel);
}

updateDisplay()
{
	// Request a list of occupants for this room.
	llMessageLinked(LINK_SET, OCCUPANCY_API_ID, COMMAND_LIST_ROOM + " " + getRoomNumber(), NULL_KEY);
}

default
{
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number / 100 == 2) // 200..299 are HTTP success return codes.
		{
			parseBody(llStringTrim(message, STRING_TRIM));
		}
	}

	listen(integer channel, string name, key id, string message)
	{
		if(channel != dialogChannel) return;

		string command = "";
		if(message == "Add")
		{
			command = llDumpList2String([COMMAND_ADD, getRoomNumber(), id], "|");
			llInstantMessage(id, "Attempting to add you to the room. Please wait a moment.");
		}
		if(message == "Remove")
		{
			command = llDumpList2String([COMMAND_DELETE, getRoomNumber(), id], "|");
			llInstantMessage(id, "Attempting to remove you from the room. Please wait a moment.");
		}

		if(command != "")
		{
			llMessageLinked(LINK_SET, OCCUPANCY_API_ID, command, NULL_KEY);
			llSetTimerEvent(4);
		}
		else
			updateDisplay();
	}

	state_entry()
	{
		string objectKey = (string)llGetKey();
		dialogChannel = (integer)("0x" + llGetSubString(objectKey, -8, -1));
		llListen(dialogChannel, "", NULL_KEY, "");
		updateDisplay();
	}

	timer()
	{
		llSetTimerEvent(0);
		updateDisplay();
	}

	touch_end(integer total_number)
	{
		showDialog(llDetectedKey(0));
	}
}
