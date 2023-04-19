module ServerApp;

// @file source/APPServer.d
//
// Start server first: rdmd server.d
// 
import std.socket;
import std.stdio;
import std.algorithm;
import std.array;
import common.CommandHistory;

import std.datetime;
import std.typecons;
import core.thread;
import std.conv;

class ServerApp {
    private Socket listener;
    private SocketSet readSet;
    private Socket[] connectedClientsList;
    private int[] buffer;
    private CommandHistory commandHistory;
    private int port;


    /**
        Constructor. Takes in the port and initializes command history
    */
    this(int port) {

        // A SocketSet is equivalent to 'fd_set'
        // https://linux.die.net/man/3/fd_set
        // What SocketSet is used for, is to allow
        // 'multiplexing' of sockets -- or put another
        // way, the ability for multiple clients
        // to connect a socket to this single server
        // socket.
        this.readSet = new SocketSet();

        // Message buffer will be 1024 bytes
        this.buffer = new int[10240];

        this.commandHistory = new CommandHistory();
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
        Sends the complete command history to the respective clientId.
    */
    void sendAllCommandHistory(int ClientId, Socket clientSock) {
        // auto clientSock = this.connectedClientsList[ClientId-1];
        // clientSock.setOption(SocketOptionLevel.TCP, SocketOption.SNDTIMEO, dur!"seconds"(1));
        if (this.commandHistory.size() > 0) {
            writeln("send history");
            int curPos = this.commandHistory.getCurPos();
            Thread.sleep(dur!"msecs"(100));
            auto sP = clientSock.send([curPos]); // sent the position of currentPointer
            writeln("sent curPointer: ", sP, " bytes");
            size_t l = this.commandHistory.size();
            for (int i = 0; i < l; ++i ) {
                int[] command = this.commandHistory.at(i);
                Thread.sleep(dur!"msecs"(100));
                auto sC = clientSock.send(command);
                writeln("sent Command: ", sC, " bytes");
            }
        }
        Thread.sleep(dur!"msecs"(100));
        ubyte[] end = [1];

        auto sL = clientSock.send(end); // make sure message received
        writeln("sent end length: ", sL);
    }

    void run() {
        this.listener = new Socket(AddressFamily.INET, SocketType.STREAM);
        scope(exit) this.listener.close();
        // Set the hostname and port for the socket
        string host = "localhost";
        ushort portCur = cast(ushort) port;
        // NOTE: It's possible the port number is in use if you are not able
        //       to connect. Try another one.
        this.listener.bind(new InternetAddress(host,portCur));
        // Allow 4 connections to be queued up
        this.listener.listen(4);
        
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
                        writeln("received bytes: ", receivedL);
                        if (receivedL <= 1) {
                            // client.close();
                            //connectedClientsList = connectedClientsList.filter(c => c !is client).array;
                            // break;
                            // writeln("got <= 0");
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
                        if (receivedL == 4) { // receive an integer. (integer is 4 bytes)
                            if (buffer[0] == -1){
                                try {
                                    writeln("undo");
                                    int[] undoCommand = commandHistory.undo();
                                    undoCommand[0] = -1; // mark this command type as undo.
                                    undoCommand[1] = 0;
                                    undoCommand[2] = 0;
                                    undoCommand[3] = 0;
                                    writeln(undoCommand);
                                    foreach(c;connectedClientsList) {
                                        c.send(undoCommand);
                                    }
                                }
                                catch(Exception e) {
                                    writeln(e.msg);
                                }
                            }
                            else {
                                try {
                                    writeln("redo");
                                    int[] redoCommand = commandHistory.redo();
                                    redoCommand[0] = 1; // mark command type as redo;
                                    foreach(c;connectedClientsList)
                                        c.send(redoCommand);
                                }
                                catch(Exception e) {
                                    writeln(e.msg);
                                }
                            }
                        }
                        else {
                            auto got = buffer[0];
                            writeln("length = ", got);
                            // char[] message = cast(char[])buffer[0 .. receivedL];
                            // writeln(message);
                            // byte[][] received = cast(byte[][]) buffer;
                            writeln(receivedL/4);
                            // int[]receivedCommand = new int[got*2 + 4];
                            // receivedCommand[] = buffer[0 .. got*2 + 4];
                            int intL = cast(int)receivedL/4;
                            writeln("intL: ", intL);
                            int[]receivedCommand = new int[intL];
                            receivedCommand[] = buffer[0 .. intL];
                            writeln("client",idx+1,">", receivedCommand);
                            // Send whatever was 'got' from the client.
                            commandHistory.add(receivedCommand);
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
                    // Add a new client to the list
                    connectedClientsList ~= newSocket;
                    // Based on how our client is setup,
                    // we need to send them an 'acceptance'
                    // message, so that the client can
                    // proceed forward.
                    int ClientId = cast(int)connectedClientsList.length; 
                    // newSocket.send("Welcome from server, you are now in our connectedClientsList");
                    newSocket.send([ClientId]);
                    writeln("> client",connectedClientsList.length," added to connectedClientsList");
                    // if(this.commandHistory.size() > 0)
                    sendAllCommandHistory(ClientId, newSocket);
                }

            }
        }
    }
}

class MockSocket : Socket {
    public string* log;
    this(ref string log) {
        this.log = &log;
    }
    override public long send(scope const(void)[] data) {
        *log ~= "send called";
        return 0;
    }
}

@("Check if send is called as expected when command history is empty")
unittest {
    ServerApp serverApp = new ServerApp(49493);
    string log = "";
    Socket skt = new MockSocket(log);
    serverApp.sendAllCommandHistory(0, skt);
    assert(log.equal("send called") == true);
}

/**
    Main method
*/
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
