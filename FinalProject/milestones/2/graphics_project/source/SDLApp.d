/// Run with: 'dub'

// Import D standard libraries
import std.stdio;
import std.string;

// import Surface
import Surface;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

    // global variable for sdl;
    const SDLSupport ret;

    shared static this() {

        // Load the SDL libraries from bindbc-sdl
	    // on the appropriate operating system
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

class SDLApp {
    // surface attribute 
    Surface surface;
    // window attribute
    SDL_Window* window;

    /// At the module level we perform any initialization before our program
    /// executes. Effectively, what I want to do here is make sure that the SDL
    /// library successfully initializes.
    this(){ 
        // Load the bitmap surface
        this.surface.imgSurface = SDL_CreateRGBSurface(0,640,480,32,0,0,0,0);
       
        // Create an SDL window 
        this.window= SDL_CreateWindow("D SDL Painting",
                                            SDL_WINDOWPOS_UNDEFINED,
                                            SDL_WINDOWPOS_UNDEFINED,
                                            640,
                                            480, 
                                            SDL_WINDOW_SHOWN);
    }


    /// At the module level, when we terminate, we make sure to 
    /// terminate SDL, which is initialized at the start of the application.
    ~this(){
        // Quit the SDL Application 
        SDL_Quit();
	    writeln("Ending application--good bye!");
    }

    /// Function for updating the pixels in a surface to a 'blue-ish' color.
    void UpdateSurfacePixel(SDL_Surface* surface, int xPos, int yPos){
	    // When we modify pixels, we need to lock the surface first
	    SDL_LockSurface(surface);
	    // Make sure to unlock the surface when we are done.
	    scope(exit) SDL_UnlockSurface(surface);

	    // Retrieve the pixel arraay that we want to modify
	    ubyte* pixelArray = cast(ubyte*)surface.pixels;
	    // Change the 'blue' component of the pixels
	    pixelArray[yPos*surface.pitch + xPos*surface.format.BytesPerPixel+0] = 255;
	    // Change the 'green' component of the pixels
	    pixelArray[yPos*surface.pitch + xPos*surface.format.BytesPerPixel+1] = 128;
	    // Change the 'red' component of the pixels
	    pixelArray[yPos*surface.pitch + xPos*surface.format.BytesPerPixel+2] = 32;
    }


    // Entry point to program
    void MainApplicationLoop()
    {

        // Flag for determing if we are running the main application loop
        bool runApplication = true;
        // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
        //                                                but not yet released)
        bool drawing = false;

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
                    runApplication= false;
                }
                else if(e.type == SDL_MOUSEBUTTONDOWN){
                    drawing=true;
                }else if(e.type == SDL_MOUSEBUTTONUP){
                    drawing=false;
                }else if(e.type == SDL_MOUSEMOTION && drawing){
                    // retrieve the position
                    int xPos = e.button.x;
                    int yPos = e.button.y;
                    // Loop through and update specific pixels
                    // NOTE: No bounds checking performed --
                    //       think about how you might fix this :)
                    // Fixed
                    int brushSize=4;
                    for(int w=-brushSize; w < brushSize; w++){
                        for(int h=-brushSize; h < brushSize; h++){
                            int BxPos = xPos + w;
                            int ByPos = yPos + h;
                            // incase brush out of window.
                            if (BxPos < 0) BxPos = 0;
                            if (BxPos > 640) BxPos = 640;
                            if (ByPos < 0) ByPos = 0;
                            if (ByPos > 480) ByPos = 480;
                            surface.changePixel(BxPos, ByPos, 255, 0, 32);
                        }
                    }
                }
            }

            // Blit the surace (i.e. update the window with another surfaces pixels
            //                       by copying those pixels onto the window).
            SDL_BlitSurface(surface.imgSurface,null,SDL_GetWindowSurface(window),null);
            // Update the window surface
            SDL_UpdateWindowSurface(window);
            // Delay for 16 milliseconds
            // Otherwise the program refreshes too quickly
            SDL_Delay(16);
        }

        // Destroy our window
        SDL_DestroyWindow(window);
    }
}
