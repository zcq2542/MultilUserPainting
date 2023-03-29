@("test changePixel on the edge")
import SDLApp;
unittest {
    SDLApp app = new SDLApp();
    app.surface.changePixel(0, 0, 255, 0, 32);
    assert( app.surface.PixelAt(0, 0)[0] == 255);
    assert( app.surface.PixelAt(0, 0)[1] == 0);
    assert( app.surface.PixelAt(0, 0)[2] == 32);
}
    
    
