import SDLApp:SDLApp;

@("Test pixel value before paint")
unittest{
	SDLApp sdlapp = new SDLApp();
	assert(sdlapp.usableSurface.getPixel(33, 44)[0] == 0 && 
	sdlapp.usableSurface.getPixel(33, 44)[1] == 0 && 
	sdlapp.usableSurface.getPixel(33, 44)[2] == 0, "Error in pixel values before paint");
}

@("Test pixel value after paint")
unittest{
	SDLApp sdlapp = new SDLApp();
	sdlapp.usableSurface.UpdateSurfacePixel(33,44,32,128,255);
	assert(sdlapp.usableSurface.getPixel(33, 44)[0] == 255 && 
	sdlapp.usableSurface.getPixel(33, 44)[1] == 128 && 
	sdlapp.usableSurface.getPixel(33, 44)[2] == 32, "Error in pixel values after paint");
}

@("Test pixel value when invalid paint")
unittest{
	SDLApp sdlapp = new SDLApp();
	sdlapp.usableSurface.UpdateSurfacePixel(-33,-44,32,128,255);
	assert(sdlapp.usableSurface.getPixel(33, 44)[0] == 0 && 
	sdlapp.usableSurface.getPixel(33, 44)[1] == 0 && 
	sdlapp.usableSurface.getPixel(33, 44)[2] == 0, "Error in pixel values when inavlid paint");
}