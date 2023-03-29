@("test create SDLApp (window and surface)")
import SDLApp;
import std.stdio;
import bindbc.sdl;
unittest {
    SDLApp app = new SDLApp();
    //Surface s;
    //writeln("111");
    //s.imgSurface = SDL_CreateRGBSurface(0,640,480,32,0,0,0,0);
    //writeln("surface created");
    //.changePixel(100, 100, 255, 0, 32);
    //assert( s.PixelAt(100, 100)[0] == 255);
}
