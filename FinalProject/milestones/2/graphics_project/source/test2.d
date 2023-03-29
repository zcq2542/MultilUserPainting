@("test changePixel")
import SDLApp;
unittest {
    SDLApp app = new SDLApp();
    app.surface.changePixel(100, 100, 255, 0, 32);
    assert( app.surface.PixelAt(100, 100)[0] == 255);
    assert( app.surface.PixelAt(100, 100)[1] == 0);
    assert( app.surface.PixelAt(100, 100)[2] == 32);
}
    
    
