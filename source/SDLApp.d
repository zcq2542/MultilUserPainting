// Import D standard libraries
import std.stdio;
import std.string;

import std.socket;
import std.conv;
import std.concurrency;
import std.array;
import core.thread;

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
    Color currentColor;
    __gshared  Socket socket;
    __gshared  Surface usableSurface;
    __gshared CommandHistory localCommandHistory;
    __gshared int ClientId;

    this(){
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

		writeln("Starting client...attempt to create socket");
        // Create a socket for connecting to a server
        this.socket = new Socket(AddressFamily.INET, SocketType.STREAM);
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
            int got = buffer[0];
		    int[] array = buffer[1 .. got*2 + 4];
            //int[] array = buffer[1 .. nbytes/4];
            writeln("array:", array);
            int[] cmd = new int[got*2 + 4];
            cmd[] = buffer[0 .. got*2+4];
            writeln("copy ok");
            localCommandHistory.add(cmd);
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

 		
    void MainApplicationLoop(){ 

        // thread to receive and draw 
        auto t = spawn(&receiveThread);
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
                    this.localCommandHistory.add(coordinates);
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
	    		}else if(e.key.keysym.sym == SDLK_r) {
	    			currentColor = Color(255,0,0);
	    		} 
	    		/*else if(e.key.keysym.sym ==SDLK_t){
	    			int[] test = [255, 0, 0, 193, 277, 190, 266, 186, 255, 182, 241, 178, 227, 174, 212, 170, 197, 167, 186, 163, 177, 161, 169, 158, 163, 156, 157, 152, 153, 149, 150, 146, 147, 142, 144, 140, 142, 136, 142, 134, 141, 131, 141, 129, 141, 127, 141, 125, 142, 123, 143, 120, 146, 118, 149, 115, 154, 113, 157, 112, 161, 111, 164, 110, 166, 109, 168, 109, 170, 108, 171, 110, 169, 111, 165, 111, 158, 111, 152, 111, 146, 110, 141, 109, 135, 108, 130, 107, 127, 106, 123, 106, 121, 105, 121, 105, 120, 105, 122, 105, 125, 105, 127, 105, 130, 106, 131, 106, 133, 107, 134, 107, 135, 108, 135, 108, 136, 109, 136, 110, 136, 110, 137, 112, 137, 113, 138, 115, 139, 117, 140, 119, 141, 121, 142, 122, 143, 124, 146, 126, 148, 126, 149, 127, 151, 127, 152, 127, 154, 128, 155, 128, 156, 127, 156, 127, 157, 127, 159, 126, 161, 126, 162, 125, 163, 124, 165, 122, 167, 119, 169, 117, 171, 114, 174, 112, 177, 109, 179, 106, 183, 104, 186, 102, 190, 99, 194, 97, 199, 97, 203, 95, 209, 93, 214, 92, 221, 91, 226, 90, 231, 89, 235, 88, 238, 88, 240, 87, 242, 87, 243];

	    			int brushSize = 4;

	    			for(int i = 3; i < test.length - 1; i+=2){
	    			int newX = test[i];
	    			int newY = test[i+1];
	    			for(int w=-brushSize; w < brushSize; w++){
	    				for(int h=-brushSize; h < brushSize; h++){
	    					usableSurface.UpdateSurfacePixel(newX+w,newY+h,currentColor);
	    				}
	    			}
	    			}
	    		} */
                else if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_z && e.key.keysym.mod & KMOD_CTRL && !ctrlZPressed) {
                    if (socket.isAlive()) {
                        socket.send([-1]); // send undo message to server.
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
                    if (socket.isAlive()) {
                        socket.send([1]); // send redo message to server.
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
