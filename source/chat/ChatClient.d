module client.ChatClient;

import std.socket;
import std.stdio;
import std.conv;
import std.concurrency;


class ChatClient{
    private __gshared Socket socket;
    private __gshared char[] buffer;
    private int ClientId;


    /**
        Constructor. Initializes socket.
    */
    this() {
        this.socket = new Socket(AddressFamily.INET, SocketType.STREAM);
        this.buffer = new char[1024];
    }

    ~this() {
        this.socket.close();
        destroy(this.buffer);
    }

    /**
        Initializes socket and connects with the client.
    */
    public void connect() {
        writeln("Starting client...attempt to create socket");
        socket.connect(new InternetAddress("localhost", 50002));
        // auto L = socket.receive(buffer);
        // writeln(buffer[0 .. L]);
        writeln("Connected");
        auto received = this.socket.receive(buffer);
        // writeln("received length: ", received);
        this.ClientId = (cast(int[])this.buffer[0 .. received])[0];
        writeln("Client connecting as Client", this.ClientId);
    }
    
    static void testThread() {
        writeln("test thread ok");
    }

    /**
        Thread to receive and print messages.
    */
    public static void receiveThread() {
        // Loop to receive message
        scope(exit) this.socket.close();
        while (true) {
            long nbytes = this.socket.receive(buffer);
            // If server disconnected, exit thread
            if (nbytes <= 0) {
                writeln("Server disconnected");
                break;
            }

            // Print out the received message
            writeln(buffer[0..nbytes]);
            //writeln(">");
        }

        // Close the socket
        this.socket.close();
    }

    /**
        Main run method.
    */
    public void run() {
        this.connect();
        // spawn(&receiveThread, cast(shared) this.socket);
        spawn(&receiveThread);
        string MyId = to!string(this.ClientId);
        foreach(line; stdin.byLine){
            write("Client"~MyId~"(self): ");
            // Send the packet of information
            socket.send("Client"~MyId~": "~line);
            // Now we'll immedietely block and await data from the server
            // auto fromServer = buffer[0 .. socket.receive(buffer)];
            // writeln("Server echos back: ", fromServer);
        }
    }
}


// Entry point to client
void main(){
    ChatClient chatClient = new ChatClient();
    chatClient.run();
}
   
