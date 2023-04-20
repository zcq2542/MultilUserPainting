module server.app;

import server.ServerApp;
import std.stdio;


void main(string[] args) {
    int port;

    if (args.length != 2) {
        port = 50001;
    } else {
    try {
        port = to!int(args[1]);
    } catch (Exception e) {
        port = 50001;
    }
    }


    ServerApp serverApp = new ServerApp(port);
    write("Running the server on localhost and on port ");
    writeln(port);
    serverApp.run();
}