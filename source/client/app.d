/// Run with: 'dub'
module client.app;

import client.SDLApp;
import std.stdio;
import std.conv;

/// Entry point to program 
void main(string[] args)
{
	int port;
	string ip;

    if (args.length != 3) {
        writeln("Mention ip address and port to connect to...");
		return;
    } else {
    try {
        port = to!int(args[2]);
		ip = args[1];
    } catch (Exception e) {
        writeln("Error parsing port number, the command should be of the form: dun run -- <ip-address> <port-number>");
		return;
    }
    }

 	SDLApp myApp = new SDLApp(args, ip, port);
  	myApp.MainApplicationLoop();
}
