// Import D standard libraries
module client.SDLApp;

import std.stdio;
import std.string;

import std.socket;
import std.conv;
import std.concurrency;
import std.array;
import core.thread;
import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Button;
import gdk.Event;
import gtk.CssProvider;
import gdk.Display;
import gdk.Screen;
import gtk.StyleContext;
import gtk.Box;
import gtk.Label;
import gtk.TextView;
import gtk.ScrolledWindow;
import gtk.HBox;
import gtk.VBox;
import std.utf;
import glib.MainLoop;
import glib.MainContext;
import glib.Timeout;
import std.algorithm.searching;
// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import client.Surface;
import client.Color;
import common.CommandHistory;

const SDLSupport ret;

shared bool end = false;

/**
 * load the library.
 */
shared static this() {
	version(Windows){
        writeln("Searching for SDL on Windows");
		ret = loadSDL("SDL2.dll");
	}
    version(OSX){
        writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){ 
        writeln("Searching for SDL on Linux");
		ret = loadSDL();
	}

	// Error if SDL cannot be loaded
    if(ret != sdlSupport){
        writeln("error loading SDL library");
        
        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == SDLSupport.noLibrary){
        writeln("error no library found");    
    }
    if(ret == SDLSupport.badLibrary){
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }

    // Initialize SDL
    if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }
	

}

shared static ~this(){
	SDL_Quit();
	writeln("Ending application--good bye!");
}

/** 
 * SDLApp.
 */
class SDLApp{
    private __gshared char[] buffer2;
    int[] buffer = new int[1024];
    static SDL_Window* window;
    __gshared  Color currentColor;
    __gshared  Socket socket1;
    __gshared  Socket socket2;
    __gshared  Surface usableSurface;
    __gshared CommandHistory localCommandHistory;
    __gshared string chatHistoryStr;
    __gshared bool chatUpdated;
    __gshared int ClientId;
	string[] args;
    int port;
    string ip;
    int port2;
    string ip2;


    this(string[] args, string ip, int port, string ip2, int port2){
	 	// Handle initialization...
 		// SDL_Init
        window = SDL_CreateWindow("D SDL Painting",
                                        SDL_WINDOWPOS_UNDEFINED,
                                        SDL_WINDOWPOS_UNDEFINED,
                                        640,
                                        480, 
                                        SDL_WINDOW_SHOWN);
		currentColor = Color(32,128,255);
        usableSurface = Surface(640,480);
        localCommandHistory = new CommandHistory();
		this.args = args;
        this.ip = ip;
        this.port = port;
	this.ip2 = ip2;
	this.port2 = port2;
	    this.buffer2 = new char[1024];
	    this.chatUpdated = false;
	    this.chatHistoryStr = "";

	    writeln("Starting client...attempt to create socket");
        // Create a socket for connecting to a server
        this.socket1 = new Socket(AddressFamily.INET, std.socket.SocketType.STREAM);
	    this.socket2 = new Socket(AddressFamily.INET, std.socket.SocketType.STREAM);
    	// Socket needs an 'endpoint', so we determine where we
    	// are going to connect to.
    	// NOTE: It's possible the port number is in use if you are not
    	//       able to connect. Try another one.
        try {
            socket1.connect(new InternetAddress(this.ip, cast(ushort) this.port));
	    socket2.connect(new InternetAddress(this.ip2, cast(ushort) this.port2));
            writeln("Connected");
            auto received = socket1.receive(buffer);
            this.ClientId = (cast(int[])buffer[0 .. 4])[0];
            writeln("ClientId: ", this.ClientId);
        }
        catch (Exception e) {
            writeln(e.msg);
        }

 	}
    
 	~this(){
        SDL_DestroyWindow(window);
		socket1.close();
		socket2.close();
		destroy(this.buffer2);
 	}

    /** 
     * receive the all message from paint server.
     */
    static void receiveThread() {
        int[10240] buffer;
        while (true) {
            synchronized{ // not work. intend to use this to end thread.
                // writeln("end: ", end);
                if (end) {
                    // writeln("end:", end);
                    break; 
                }
            }
            long nbytes = socket1.receive(buffer);
            //writeln("received nbytes: ", nbytes);
            // If server disconnected, exit thread
            if (nbytes <= 1) {
                writeln("Server disconnected");
                break;
            }

		    int brushSize = 4;
            int type = buffer[0];
            int intL = cast(int)nbytes/4;
		    int[] array = buffer[1 .. intL];
            //int[] array = buffer[1 .. nbytes/4];
            //writeln("array:", array);
            int[] cmd = new int[intL];
            cmd[] = buffer[0 .. intL];
            //writeln("copy ok");
            if (type == 0)
                localCommandHistory.add(cmd);
            else if (type == -1)
                localCommandHistory.undo();
            else if (type == 1){
                // writeln("got here redo");
                localCommandHistory.redo();
            }
		    Color receivedColor = Color(cast(ubyte) array[0],cast(ubyte) array[1],cast(ubyte) array[2]);

            for(int i = 3; i < array.length - 1; i+=2){
				int newX = array[i];
				int newY = array[i+1];
				for(int w=-brushSize; w < brushSize; w++){
					for(int h=-brushSize; h < brushSize; h++){
						usableSurface.UpdateSurfacePixel(newX+w,newY+h,receivedColor);
                        // writeln("draw");
					}
				}
		    }
		    SDL_BlitSurface(this.usableSurface.imgSurface,null,SDL_GetWindowSurface(this.window),null);
		    // Update the window surface
		    SDL_UpdateWindowSurface(this.window);
       }   

        // Close the socket
        if (socket1) socket1.close();
        //writeln("receive thread end");
    }

    /** 
     * receive all message from chat server.
     */
    static void receiveThread2() {
        // Loop to receive message
        //scope(exit) this.socket2.close();
        while (true) {
            long nbytes = socket2.receive(buffer2);
            // If server disconnected, exit thread
            if (nbytes <= 1) {
                writeln("Server disconnected");
                break;
            }

	    string message = to!string(buffer2[0..nbytes]);
	    string message2;
	    auto index = message.indexOf("EOM");
	    if (index > 0) {
		    message2 = message[0..index];
	    }
	    chatHistoryStr ~= message2;
	    chatUpdated = true;
        }

        // Close the socket
        if (socket2) socket2.close();
    }


/** 
 * quit the app.
 */
static void QuitApp(){
	writeln("Terminating application");
	Main.quit();
}

/** 
 * color data used in paint color panel
 */
struct Data {
	Color color;
	string text;

	this(Color color, string text){
		this.color = color;
		this.text = text;
	}
}

/** 
 * create color button for color panel.
 * Params:
 *   r = red color 0-255
 *   g = green color 0-255
 *   b = blue color 0-255
 *   text = test of color
 *   hbox = box in panel
 */
static void createButton(ubyte r, ubyte g, ubyte b, string text, Box hbox){
	Button myButton = new Button("");
	myButton.setName(text);

	// Action for when we click a button
	myButton.addOnClicked(delegate void(Button bt) {
							currentColor = Color(r,g,b);
						});

	hbox.packStart(myButton, true, true, 0);
}	

/** 
 * run the color panel GUI
 * Params:
 *   args = used to init GTK
 */
static void RunGUI(immutable string[] args)
{
	string[] args2 = args.dup;

	string cssPath = "source/button.css";

    CssProvider provider = new CssProvider();
    provider.loadFromPath(cssPath);

	// Initialize GTK
	Main.init(args2);
	// Setup our window
	MainWindow myWindow = new MainWindow("Colors");
	// Position our window
	myWindow.setDefaultSize(0,0);
	int w,h;
	myWindow.getSize(w,h);
	//writeln("width   : ",w);
	//writeln("height  : ",h);
	myWindow.move(100,120);
	
	// Delegate to call when we destroy our application
	myWindow.addOnDestroy(delegate void(Widget w) { QuitApp(); });

	 auto vbox = new Box(Orientation.VERTICAL, 0);

	 Data[] allColors = new Data[0];
	 allColors ~= Data(Color(255,0,0), "redbutton");
	 allColors ~= Data(Color(0,255,0), "greenbutton");
	 allColors ~= Data(Color(32,128,255), "bluebutton");
	 allColors ~= Data(Color(255,255,255), "whitebutton");
	 allColors ~= Data(Color(180,180,180), "greybutton");
	 allColors ~= Data(Color(255,194,14), "yellowbutton");
	 allColors ~= Data(Color(111,49,152), "purplebutton");
	 allColors ~= Data(Color(153,217,234), "skybutton");
	 allColors ~= Data(Color(181,165,213), "lightpurpbutton");
	 allColors ~= Data(Color(153,0,48), "maroonbutton");

	 int numOfCol = 5;
	 auto numOfRows = 2;

		for(int i = 0; i < numOfRows; i++){
			auto hbox = new Box(Orientation.HORIZONTAL, 0);
			for(int j = 0; j < numOfCol; j++){
						createButton(allColors[i*numOfCol + j].color.r, allColors[i*numOfCol + j].color.g, allColors[i*numOfCol + j].color.b, allColors[i*numOfCol + j].text, hbox );
			}
			vbox.add(hbox);
	}
	Display display = Display.getDefault();
    Screen screen = display.getDefaultScreen();
    StyleContext.addProviderForScreen(screen, provider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    TextView chatHistory = new TextView();
    	chatHistory.setEditable(false);
    	chatHistory.setWrapMode(WrapMode.WORD);
    	ScrolledWindow chatHistoryScroll = new ScrolledWindow(chatHistory);

	TextView messageBox = new TextView();
    	messageBox.setWrapMode(WrapMode.WORD);
    	ScrolledWindow messageBoxScroll = new ScrolledWindow(messageBox);
    	messageBoxScroll.setPolicy(PolicyType.NEVER, PolicyType.AUTOMATIC);

    	Button sendButton = new Button("Send");

    	HBox messageBoxContainer = new HBox(false, 10);
    	messageBoxContainer.packStart(messageBoxScroll, true, true, 0);
    	messageBoxContainer.packEnd(sendButton, false, true, 0);

    	VBox mainContainer = new VBox(false, 10);

        auto label = new Label("Chat");
        mainContainer.packStart(label, false, false, 5);

    	mainContainer.packStart(chatHistoryScroll, true, true, 0);
    	mainContainer.packEnd(messageBoxContainer, false, true, 0);

        mainContainer.setSizeRequest(-1, 200);

    	vbox.add(mainContainer);

    	sendButton.addOnClicked(delegate void(Button bt) {
        	string message = messageBox.getBuffer().getText();
		string MyId = to!string(this.ClientId);
		messageBox.getBuffer().setText("");
		chatHistoryStr ~= "Client"~MyId~" : " ~ message ~ "\n";
		chatUpdated = true;
		socket2.send("Client"~MyId~" : " ~ message ~ "\n" ~ "EOM");
    	});

    	// Create a new timeout and attach the update function to it
    	auto timeout = new Timeout(cast(uint)1000, delegate bool() {
			if (chatUpdated && chatHistoryStr != null && chatHistoryStr.length > 0) {
				chatHistory.getBuffer().setText(toUTF8(chatHistoryStr ~ "\n"));
				chatUpdated = false;
			}
			return true;});


	// Add our button as a child of our window
	myWindow.add(vbox);

	// Show our window
	myWindow.showAll();

	// Run our main loop
	Main.run();
}

    /** 
     * draw on the surface with coordinates array.
     * Params:
     *   array = coordinates array
     *   brushSize = drawing brush size
     */
    void draw(int[] array, int brushSize){
        Color receivedColor = Color(cast(ubyte) array[0],cast(ubyte) array[1],cast(ubyte) array[2]);

        for(int i = 3; i < array.length - 1; i+=2){
				int newX = array[i];
				int newY = array[i+1];
				for(int w=-brushSize; w < brushSize; w++){
					for(int h=-brushSize; h < brushSize; h++){
						usableSurface.UpdateSurfacePixel(newX+w,newY+h,receivedColor);
					}
				}
		}
    }

    /** 
     * receive all command in the server command history whenclient connect to server.
     */
    void receiveAllCommand() {
        int commandReceived = 0;
        int curPos = -1;
        while(true) {
            writeln("start to receive command history");
            auto receivedL = this.socket1.receive(this.buffer); // num of bytes received
            //writeln(receivedL);
            if (receivedL <= 1) break;
            int l = cast(int) receivedL / 4; // num of integer received.
            //writeln("buffer: ", buffer[0 .. l]);
            if (commandReceived == 0) {
                
                curPos = this.buffer[0 .. l][0];
                //writeln("curPos: ", curPos);
            }
            else {
                int[] command = this.buffer[0 .. l].dup; // deep copy.
                this.localCommandHistory.add(command);
                if (commandReceived-1 <= curPos)
                    draw(command[1 ..$], 4);
            }
            ++commandReceived;
        }
        this.localCommandHistory.setCurPos(curPos);
    }



    public void pollEvents(ref Socket skt, ref Socket skt2, ref bool runApplication,
        ref bool drawing, ref bool ctrlZPressed,
        ref bool ctrlYPressed, ref int[] coordinates,
        ref SDL_Event e) {

        while(SDL_PollEvent(&e) !=0){
            if(e.type == SDL_QUIT){
                synchronized{
                    QuitApp();
                    end = true;
                    //writeln("main end:", end);
                }
                ubyte[] emptyMsg = [1];
                long bytesSent = skt.send(emptyMsg);
                //writeln("Sent ", bytesSent, " bytes");
		long bytesSent2 = skt2.send("e");
                //writeln("Sent ", bytesSent2, " bytes to server 2");
                // socket.close();
                writeln("waiting all thread finish");
                // thread_suspendAll();
                // thread_term();
                thread_joinAll();
                runApplication= false;
                // send(t.id, "terminate"); // ask receiveThread to stop.
                // t.terminate;
            }
            else if(e.type == SDL_MOUSEBUTTONDOWN){
                drawing=true;
                coordinates ~= -1;
                coordinates ~= currentColor.r;
                coordinates ~= currentColor.g;
                coordinates ~= currentColor.b;
            }else if(e.type == SDL_MOUSEBUTTONUP){
                drawing=false;
                coordinates[0] = 0; // mark command type as client draw.
                //writeln(coordinates);
                skt.send(coordinates);
                this.localCommandHistory.add(coordinates);
                coordinates.length = 0;
            }else if(e.type == SDL_MOUSEMOTION && drawing){
                // retrieve the position
                int xPos = e.button.x;
                int yPos = e.button.y;

                int brushSize=4;
                coordinates ~= xPos;
                coordinates ~= yPos;
                for(int w=-brushSize; w < brushSize; w++){
                    for(int h=-brushSize; h < brushSize; h++){
                        usableSurface.UpdateSurfacePixel(xPos+w,yPos+h,currentColor);
                    }
                }
            }
            else if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_z && e.key.keysym.mod & KMOD_CTRL && !ctrlZPressed) {
                    if (skt.isAlive()) {
                        skt.send([-1]); // send undo message to server.
                    }
                    else {
                        try {
                            int[] cmd = localCommandHistory.undo();
                            cmd[1] = 0;
                            cmd[2] = 0;
                            cmd[3] = 0;
                            draw(cmd[1 .. $], 4);
                            // writeln("undo");
                        }
                        catch (Exception e) {
                            writeln(e.msg);
                        }
                    }
                    ctrlZPressed = true;
                }
                else if (e.type == SDL_KEYUP && e.key.keysym.sym == SDLK_z && e.key.keysym.mod & KMOD_CTRL) {
                        ctrlZPressed = false;
                    }
                    else if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_y && e.key.keysym.mod & KMOD_CTRL && !ctrlYPressed) {
                            if (skt.isAlive()) {
                                skt.send([1]); // send redo message to server.
                            }
                            else {
                                try {
                                    int[] cmd = localCommandHistory.redo();
                                    draw(cmd[1 .. $], 4);
                                }
                                catch (Exception e) {
                                    writeln(e.msg);
                                }
                            }
                            ctrlYPressed = true;
                        }
                        else if (e.type == SDL_KEYUP && e.key.keysym.sym == SDLK_y && e.key.keysym.mod & KMOD_CTRL) {
                                ctrlYPressed = false;
                            }
        }
    }
 
    /**
     * main loop. capture user mouse and keyboard actions. drawing on surface or redo/undo.
     */    
    void MainApplicationLoop(){ 

        receiveAllCommand();
        auto t = spawn(&receiveThread); // thread to receive and draw
	auto t2 = spawn(&receiveThread2);
        immutable string[] args2 = this.args.dup;
        spawn(&RunGUI,args2);

        bool runApplication = true;
        bool drawing = false;
        bool ctrlZPressed = false;
        bool ctrlYPressed = false;
        int[] coordinates = new int[0];

	    while(runApplication){
            SDL_Event e;
            pollEvents(this.socket1, this.socket2, runApplication, drawing, ctrlZPressed, ctrlYPressed, coordinates, e);

	    	SDL_BlitSurface(usableSurface.imgSurface,null,SDL_GetWindowSurface(window),null);
	    	SDL_UpdateWindowSurface(window);
	    	SDL_Delay(100);
	    }
    }
}
