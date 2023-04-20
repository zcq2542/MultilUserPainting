module server.app;

import server.ServerApp;
import std.stdio;
import std.conv;


void main(string[] args) {
    int port;
    string ip;
    if (args.length != 3) {
	ip = "0.0.0.0";
        port = 50001;
    } else {
	ip = args[1];
        port = to!int(args[2]);
    } 

    ServerApp serverApp = new ServerApp(ip, port);
    writeln("Running the server on IP and on port ");
    writeln("IP: ", ip);
    writeln("Port: ", port);
    serverApp.run();
}
