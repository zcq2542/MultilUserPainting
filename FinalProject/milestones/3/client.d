// @file chat/client.d
//
// After starting server (rdmd server.d)
// then start as many clients as you like with "rdmd client.d"
//
import std.socket;
import std.stdio;
import std.conv;
import std.concurrency;

void receiveThread(shared Socket socket) {
    // Loop to receive messages
    Socket s = cast(Socket) socket;
    scope(exit) s.close();
    while (true) {
        char[1024] buffer;
        long nbytes = s.receive(buffer);
        // If server disconnected, exit thread
        if (nbytes <= 0) {
            writeln("Server disconnected");
            break;
        }

        // Print out the received message
        writeln("Received message: ", buffer[0..nbytes]);
        writeln(">");
    }

    // Close the socket
    s.close();
}

// Entry point to client
void main(){
	writeln("Starting client...attempt to create socket");
    // Create a socket for connecting to a server
    auto socket = new Socket(AddressFamily.INET, SocketType.STREAM);
	// Socket needs an 'endpoint', so we determine where we
	// are going to connect to.
	// NOTE: It's possible the port number is in use if you are not
	//       able to connect. Try another one.
    socket.connect(new InternetAddress("localhost", 50001));
	scope(exit) socket.close();
	writeln("Connected");

    // Buffer of data to send out
	// Choose '1024' bytes of information to be sent/received
    char[1024] buffer;
    auto received = socket.receive(buffer);

    writeln("(Client connecting) ", buffer[0 .. received]);

    spawn(&receiveThread, cast(shared) socket);
	write(">");
    foreach(line; stdin.byLine){
		// Send the packet of information
        socket.send(line);
		// Now we'll immedietely block and await data from the server
		// auto fromServer = buffer[0 .. socket.receive(buffer)];
        // writeln("Server echos back: ", fromServer);
		write(">");
    }
}
