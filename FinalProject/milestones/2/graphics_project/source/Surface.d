module Surface;

import std.stdio;
// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

struct Surface {

    SDL_Surface* imgSurface;
    this(SDL_Surface* surface) {
        this.imgSurface = surface;
        writeln("imgSurface created");
    }

    ~this() {
        SDL_FreeSurface(this.imgSurface);
    }

    void changePixel(int x, int y, ubyte b, ubyte g, ubyte r) {
        SDL_LockSurface(this.imgSurface);
        scope(exit) SDL_UnlockSurface(this.imgSurface);
        // Retrieve the pixel arraay that we want to modify
        ubyte* pixelArray = cast(ubyte*)this.imgSurface.pixels;
        // Change the 'blue' component of the pixels
        pixelArray[y*this.imgSurface.pitch + x*this.imgSurface.format.BytesPerPixel+0] = b;
        // Change the 'green' component of the pixels
        pixelArray[y*this.imgSurface.pitch + x*this.imgSurface.format.BytesPerPixel+1] = g;
        // Change the 'red' component of the pixels
        pixelArray[y*this.imgSurface.pitch + x*this.imgSurface.format.BytesPerPixel+2] = r;

    }

    ubyte[] PixelAt(int x, int y) {
        ubyte[] pixelColor = new ubyte[3]; 
        ubyte* pixelArray = cast(ubyte*)imgSurface.pixels;
        // Get the 'blue' component of the pixels
        pixelColor[0] = pixelArray[y*imgSurface.pitch + x*imgSurface.format.BytesPerPixel+0];
        // Get the 'green' component of the pixels
        pixelColor[1] = pixelArray[y*imgSurface.pitch + x*imgSurface.format.BytesPerPixel+1];
        // Get the 'red' component of the pixels
        pixelColor[2] = pixelArray[y*imgSurface.pitch + x*imgSurface.format.BytesPerPixel+2];
        return pixelColor;
    }
}
