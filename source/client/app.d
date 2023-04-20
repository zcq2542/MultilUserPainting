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
	int port2;
	string ip2;

    if (args.length != 5) {
        writeln("Mention ip address and port of chat server and server app to connect to...");
		return;
    } else {
    try {
        port = to!int(args[2]);
		ip = args[1];
	port2 = to!int(args[4]);
	ip2 = args[3];
    } catch (Exception e) {
        writeln("Error parsing port number, the command should be of the form: dun run -- <ip-address> <port-number> <chat-server-ip> <chat-server-port>");
		return;
    }
    }

 	SDLApp myApp = new SDLApp(args, ip, port, ip2, port2);
  	myApp.MainApplicationLoop();
}
