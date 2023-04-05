// Import D standard libraries
import std.stdio;
import std.string;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import Surface:Surface;

import Color:Color;

const SDLSupport ret;

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
    SDL_Window* window;
    Surface usableSurface;
    Color currentColor;

    this(){
	 	// Handle initialization...
 		// SDL_Init
    window = SDL_CreateWindow("D SDL Painting",
                                        SDL_WINDOWPOS_UNDEFINED,
                                        SDL_WINDOWPOS_UNDEFINED,
                                        640,
                                        480, 
                                        SDL_WINDOW_SHOWN);
		usableSurface = Surface(640,480);
		currentColor = Color(32,128,255);
 	}
    
 	~this(){
        SDL_DestroyWindow(window);
 	}

 		
 	void MainApplicationLoop(){ 

    // Flag for determing if we are running the main application loop
	bool runApplication = true;
	// Flag for determining if we are 'drawing' (i.e. mouse has been pressed
	//                                                but not yet released)
	bool drawing = false;

	int[] coordinates = new int[0];

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
				coordinates ~= currentColor.r;
				coordinates ~= currentColor.g;
				coordinates ~= currentColor.b;
			}else if(e.type == SDL_MOUSEBUTTONUP){
				drawing=false;
				writeln(coordinates); // Send to server
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
		}

		// Blit the surace (i.e. update the window with another surfaces pixels
		//                       by copying those pixels onto the window).
		SDL_BlitSurface(usableSurface.imgSurface,null,SDL_GetWindowSurface(window),null);
		// Update the window surface
		SDL_UpdateWindowSurface(window);
		// Delay for 16 milliseconds
		// Otherwise the program refreshes too quickly
		SDL_Delay(16);
	}
    }
	}
