module server.test;

import server.ServerApp;
import std.socket;
import std.string;
import std.algorithm;

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