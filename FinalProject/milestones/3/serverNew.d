module serverNew;

// @file chat/server.d
//
// Start server first: rdmd server.d
// 
import std.socket;
import std.stdio;
// import Packet : Packet;
import std.algorithm;
import std.array;
import CommandHistory;



// Entry point to Server
void main(){
	writeln("Starting server...");
	writeln("Server must be started before clients may join");
    auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
	scope(exit) listener.close();

	// Set the hostname and port for the socket
    string host = "localhost";
    ushort port = 50001;
	// NOTE: It's possible the port number is in use if you are not able
	//  	 to connect. Try another one.
    listener.bind(new InternetAddress(host,port));
    // Allow 4 connections to be queued up
    listener.listen(2);

	// A SocketSet is equivalent to 'fd_set'
	// https://linux.die.net/man/3/fd_set
	// What SocketSet is used for, is to allow 
	// 'multiplexing' of sockets -- or put another
	// way, the ability for multiple clients
	// to connect a socket to this single server
	// socket.
    auto readSet = new SocketSet();
    Socket[] connectedClientsList;

    // Message buffer will be 1024 bytes 
    int[10240] buffer;
	// byte[1024][1024] buffer3; 
    // byte[Packet.sizeof] buffer2;

    // Main application loop for the server
	writeln("Awaiting client connections");
    bool serverIsRunning=true;
    while(serverIsRunning){
		// Clear the readSet
        readSet.reset();
		// Add the server
        readSet.add(listener);
        foreach(client ; connectedClientsList){
            readSet.add(client);
        }
        
        // Handle each clients message
        if(Socket.select(readSet, null, null)){
            foreach(idx,client; connectedClientsList){
				// Check to ensure that the client
				// is in the readSet before receving
				// a message from the client.
                if(readSet.isSet(client)){
					// Server effectively is blocked
					// until a message is received here.
					// When the message is received, then
					// we send that message from the 
					// server to the client
                    long receivedL = client.receive(buffer);
                    writeln(receivedL);
                    if (receivedL <= 1) {
                        // client.close();
                        //connectedClientsList = connectedClientsList.filter(c => c !is client).array;
                        // break;
                        // writeln("got <= 0");
                        writeln("end connect");
                        client.send([1]);
                        // writeln("sent end");
                        readSet.remove(client);
                        connectedClientsList = remove(connectedClientsList, idx);
                        // Adding +1 to client index to match number of clients.
                        writeln("client", idx+1, "disconnect");
                        continue;
                    }
                    if (receivedL == 4) { // receive an integer. (integer is 4 bytes)
                        if (buffer[0] == -1){
                            writeln("undo");
                            foreach(c;connectedClientsList) {
//                                int[] undoCommand = commandHistory.undo();
//                                undoCommand[1] = 0;
//                                undoCommand[2] = 0;
//                                undoCommand[3] = 0;
//                                c.send(undoCommand);
                            }
                        }
                        else {
                            writeln("redo");
                            foreach(c;connectedClientsList)
//                              c.send(commandHistory.redo());
                        }    
                    }                    
                    else {
                        auto got = buffer[0];
                        writeln("length = ", got);
                        // char[] message = cast(char[])buffer[0 .. receivedL];
                        // writeln(message);
                        // byte[][] received = cast(byte[][]) buffer;
                        int[] receivedCommand = buffer[0 .. got*2 + 4];
                        writeln("client",idx+1,">", receivedCommand);
                        // Send whatever was 'got' from the client.
//                        commandHistory.add(receivedCommand);
                        foreach(c;connectedClientsList)
                            if (c != client)
                                c.send(receivedCommand);
                    }
                }
            }
			// The listener is ready to read
			// Client wants to connect so we accept here.
			if(readSet.isSet(listener)){
				auto newSocket = listener.accept();
				// Based on how our client is setup,
				// we need to send them an 'acceptance'
				// message, so that the client can
				// proceed forward.
				newSocket.send("Welcome from server, you are now in our connectedClientsList");
				// Add a new client to the list
				connectedClientsList ~= newSocket;
				writeln("> client",connectedClientsList.length," added to connectedClientsList");
			}
    	}
	}
}
