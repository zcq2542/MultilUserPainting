module chat.ChatServer;

import std.socket;
import std.algorithm;
import std.array;
import std.stdio;
import std.conv;

class ChatServer {
    private Socket listener;
    private SocketSet readSet;
    private Socket[] connectedClientsList;
    private byte[] buffer;
    private string host;
    private int port;
    /**
        Constructor
    */
    this(string host, int port) {
        this.readSet = new SocketSet();
        // Message buffer will be 1024 bytes
        this.buffer = new byte[10240];
	this.host = host;
	this.port = port;
    }

    /**
        Destructor
    */
    ~this() {
        destroy(buffer);
        this.listener.close();
    }


    /**
        Main runner for chat server. Manages connections with the client.
    */
    public void run() {
        this.listener = new Socket(AddressFamily.INET, SocketType.STREAM);
        scope(exit) this.listener.close();
        // Set the hostname and port for the socket
        // NOTE: It's possible the port number is in use if you are not able
        //       to connect. Try another one.
        this.listener.bind(new InternetAddress(this.host,cast(ushort)this.port));
        // Allow 4 connections to be queued up
        this.listener.listen(4);

        // Main application loop for the server
        writeln("Chat Server Awaiting client connections");
	writeln("Chat server IP: ", host);
	writeln("Chat server port: ", port);
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
                        writeln("received bytes: ", receivedL);
                        if (receivedL <= 1) {
                            // client.close();
                                                        
                           writeln("end connect");
                            ubyte[] endMessage = [3]; // 1 byte length message.
                            client.send(endMessage);
                            // writeln("sent end");
                            readSet.remove(client);
                            connectedClientsList = remove(connectedClientsList, idx);
                            // Adding +1 to client index to match number of clients.
                            writeln("client", idx+1, "disconnect");
                            continue;
                        }
                        else {
                            foreach(c;connectedClientsList)
                                if (c != client)
                                    c.send(buffer[0 .. receivedL]);
                        }
                    }
                }
                // The listener is ready to read
                // Client wants to connect so we accept here.
                if(readSet.isSet(listener)){
                    auto newSocket = listener.accept();
                    // Add a new client to the list
                    connectedClientsList ~= newSocket;
                    // Based on how our client is setup,
                    // we need to send them an 'acceptance'
                    // message, so that the client can
                    int ClientId = cast(int)connectedClientsList.length;
                    // newSocket.send("Welcome from server, you are now in our connectedClientsList");
                    newSocket.send([ClientId]);
                    writeln(ClientId);
                    writeln("> client",connectedClientsList.length," added to connectedClientsList");
                }

            }
        }
    }
}
void main(string[] args) {

    int port;
    string ip;
    if (args.length != 3) {
	ip = "0.0.0.0";
        port = 50002;
    } else {
	ip = args[1];
        port = to!int(args[2]);
    }
    ChatServer chatServer = new ChatServer(ip, port);
    chatServer.run();
}

