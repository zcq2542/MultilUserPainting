module server2;

class Server {
    auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    auto readSet = new SocketSet();
    Socket[] connectedClientsList;
}