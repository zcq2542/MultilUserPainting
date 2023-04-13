// Import D standard libraries
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

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import Surface:Surface;
import Color:Color;
import CommandHistory:CommandHistory;

const SDLSupport ret;

shared bool end = false;

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

class SDLApp{
    int[] buffer = new int[1024];
    static SDL_Window* window;
    __gshared  Color currentColor;
    __gshared  Socket socket;
    __gshared  Surface usableSurface;
    __gshared CommandHistory localCommandHistory;
    __gshared int ClientId;
	string[] args;

    this(string[] args){
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

		writeln("Starting client...attempt to create socket");
        // Create a socket for connecting to a server
        this.socket = new Socket(AddressFamily.INET, std.socket.SocketType.STREAM);
    	// Socket needs an 'endpoint', so we determine where we
    	// are going to connect to.
    	// NOTE: It's possible the port number is in use if you are not
    	//       able to connect. Try another one.
        try {
            socket.connect(new InternetAddress("localhost", 50001));
            // scope(exit) socket.close();
            writeln("Connected");

            // char[1024] buffer;
            // auto received = socket.receive(buffer);
            // writeln("(Client connecting) ", buffer[0 .. received]);
            auto received = socket.receive(buffer);
            // writeln("rece: ", received);
            this.ClientId = (cast(int[])buffer[0 .. 4])[0];
            writeln("ClientId: ", this.ClientId);
            // connectToServer("localhost", 50001);
        }
        catch (Exception e) {
            writeln(e.msg);
        }

 	}
    
 	~this(){
        SDL_DestroyWindow(window);
		socket.close();
 	}

    // void connectToServer(string IP, int portNum) {

    // }
    
    static void testThread() {
        writeln("11test thread");
    }

    static void receiveThread() {
        // Loop to receive messages
        // Socket s = this.socket;
        //scope(exit) s.close();
        int[10240] buffer;
        // long n = this.socket.receive(buffer2);
        // scope(exit) destroy(buffer);
        while (true) {
            synchronized{ // not work. intend to use this to end thread.
                writeln("end: ", end);
                if (end) {
                    writeln("end:", end);
                    break; 
                }
            }
            long nbytes = socket.receive(buffer);
            writeln("received nbytes: ", nbytes);
            // If server disconnected, exit thread
            if (nbytes <= 1) {
                writeln("Server disconnected");
                break;
            }
            // Print out the received message
            // writeln("Received message: ", buffer[0 ..nbytes]);
           
		// draw(buffer[0 ..nbytes], 4); // draw the array.
            // char[] rec = cast(char[])buffer[0 .. nbytes];
		    int brushSize = 4;
            int type = buffer[0];
            int intL = cast(int)nbytes/4;
		    int[] array = buffer[1 .. intL];
            //int[] array = buffer[1 .. nbytes/4];
            writeln("array:", array);
            int[] cmd = new int[intL];
            cmd[] = buffer[0 .. intL];
            writeln("copy ok");
            if (type == 0)
                localCommandHistory.add(cmd);
            else if (type == -1)
                localCommandHistory.undo();
            else if (type == 1){
                writeln("got here");
                localCommandHistory.redo();
            }
            // int [] array = [255, 0, 0, 153, 244, 155, 255, 156, 266];
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
                // ubyte[] col = this.usableSurface.getPixel(newX, newY);
                // writeln("get");
		    }
		    SDL_BlitSurface(this.usableSurface.imgSurface,null,SDL_GetWindowSurface(this.window),null);
		    // Update the window surface
		    SDL_UpdateWindowSurface(this.window);

            // write(">");
       }   

        // Close the socket
        if (socket) socket.close();
        writeln("receive thread end");
    }

static void QuitApp(){
	writeln("Terminating application");
	Main.quit();
}

struct Data {
	Color color;
	string text;

	this(Color color, string text){
		this.color = color;
		this.text = text;
	}
}

static void createButton(ubyte r, ubyte g, ubyte b, string text, Box hbox){
	Button myButton = new Button("");
	myButton.setName(text);

	// Action for when we click a button
	myButton.addOnClicked(delegate void(Button bt) {
							currentColor = Color(r,g,b);
						});

	hbox.packStart(myButton, true, true, 0);
}

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
	writeln("width   : ",w);
	writeln("height  : ",h);
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


	// Add our button as a child of our window
	myWindow.add(vbox);

	// Show our window
	myWindow.showAll();

	// Run our main loop
	Main.run();
}


 		
    void MainApplicationLoop(){ 

        // thread to receive and draw 
        auto t = spawn(&receiveThread);
        immutable string[] args2 = this.args.dup;
        spawn(&RunGUI,args2);
        // spawn(&testThread);
        // t.join();

        // Flag for determing if we are running the main application loop
	    bool runApplication = true;
	    // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
	    //                                                but not yet released)
	    bool drawing = false;

        bool ctrlZPressed = false;
        bool ctrlYPressed = false;

	    int[] coordinates = new int[0];

        writeln(this.usableSurface.getPixel(153, 244));
    
        int totalPoints = 0;
	    // Main application loop that will run until a quit event has occurred.
	    // This is the 'main graphics loop'
	    while(runApplication){
	    	SDL_Event e;
	    	// Handle events
	    	// Events are pushed into an 'event queue' internally in SDL, and then
	    	// handled one at a time within this loop for as many events have
	    	// been pushed into the internal SDL queue. Thus, we poll until there
	    	// are '0' events or a NULL event is returned.
	    	while(SDL_PollEvent(&e) !=0){
	    		if(e.type == SDL_QUIT){
                    synchronized{
					QuitApp();
    					QuitApp();
                    end = true;
                        writeln("main end:", end);
                    }
                    // t.thread_term();
                    ubyte[] emptyMsg = [1];
                    long bytesSent = socket.send(emptyMsg);
                    // long bytesSent = socket.send([1]);
                    writeln("Sent ", bytesSent, " bytes");
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
				// writeln(coordinates); // Send to server
				coordinates[0] = totalPoints;
				writeln(coordinates);
                this.socket.send(coordinates);
				totalPoints = 0;
 				coordinates.length = 0;
			}else if(e.type == SDL_MOUSEMOTION && drawing){
				// retrieve the position
				int xPos = e.button.x;
				int yPos = e.button.y;
				// Loop through and update specific pixels
				// NOTE: No bounds checking performed --
				//       think about how you might fix this :)
				int brushSize=4;
				coordinates ~= xPos;
				coordinates ~= yPos;
				totalPoints +=1;
				for(int w=-brushSize; w < brushSize; w++){
					for(int h=-brushSize; h < brushSize; h++){
						usableSurface.UpdateSurfacePixel(xPos+w,yPos+h,currentColor);
					}
				}
			}
		}

	    	// Blit the surace (i.e. update the window with another surfaces pixels
	    	//                       by copying those pixels onto the window).
	    	// Delay for 16 milliseconds
	    	SDL_BlitSurface(usableSurface.imgSurface,null,SDL_GetWindowSurface(window),null);
	    	// Update the window surface
	    	SDL_UpdateWindowSurface(window);
	    	// Otherwise the program refreshes too quickly
	    	SDL_Delay(100);
	    }
    }
}
