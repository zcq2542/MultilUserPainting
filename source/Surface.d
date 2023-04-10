// Import D standard libraries
import std.string;

// Load the SDL2 library
import bindbc.sdl;

import Color:Color;

struct Surface{
	SDL_Surface* imgSurface;
	int width;
	int height;

  	this(int width, int height) {
    // Load the bitmap surface
	this.width = width;
	this.height = height;
    imgSurface = SDL_CreateRGBSurface(0,width,height,32,0,0,0,0);
  	}

  	~this(){
  		SDL_FreeSurface(imgSurface);
  	}
  	
  	// Update a pixel ...
  	// SomeFunction()
    /// Function for updating the pixels in a surface to a 'blue-ish' color.
    void UpdateSurfacePixel(int xPos, int yPos, Color color){
	    if(xPos < 0 || yPos < 0 || xPos > width || yPos > height){
		    return;
	    }

	    // When we modify pixels, we need to lock the surface first
	    SDL_LockSurface(imgSurface);
	    // Make sure to unlock the surface when we are done.
	    scope(exit) SDL_UnlockSurface(imgSurface);

	    // Retrieve the pixel arraay that we want to modify
	    ubyte* pixelArray = cast(ubyte*)imgSurface.pixels;
	    // Change the 'blue' component of the pixels
	    pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+0] = color.b;
	    // Change the 'green' component of the pixels
	    pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+1] = color.g;
	    // Change the 'red' component of the pixels
	    pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+2] = color.r;
}

  	
  	// Check a pixel color
  	// Some OtherFunction()

	ubyte[] getPixel(int xPos, int yPos){
	    ubyte* pixelArray = cast(ubyte*)imgSurface.pixels;
	    ubyte[] res = new ubyte[3];
	    res[0] = pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel + 0];
	    res[1] = pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel + 1];
	    res[2] = pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel + 2];

	    return res;
    }
  	
}
