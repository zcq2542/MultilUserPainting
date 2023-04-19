module client.test;

import client.SDLApp;
import client.Surface;
import client.Color;
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
import std.socket;
import std.string;
import std.algorithm;


class MockSocket : Socket {
	public string* log;
	this(ref string log) {
		this.log = &log;
	}
	override public long send(scope const(void)[] data) {
		*log ~= "send called";
		return 0;
	}
}

@("Check sdl is initialized properly")
unittest {
	assert(SDL_Init(SDL_INIT_EVERYTHING) ==0, "SDL not initialized properly");
}

@("Test pixel value before paint")
unittest{
	Surface s = Surface(500, 500);
	assert(s.getPixel(33, 44)[0] == 0 &&
	s.getPixel(33, 44)[1] == 0 &&
	s.getPixel(33, 44)[2] == 0, "Error in pixel values before paint");
}

@("Test pixel value after paint")
unittest{
	Surface s = Surface(500, 500);
	s.UpdateSurfacePixel(33,44, Color(32,128,255));
	assert(s.getPixel(33, 44)[0] == 255 &&
	s.getPixel(33, 44)[1] == 128 &&
	s.getPixel(33, 44)[2] == 32, "Error in pixel values after paint");
}


@("Test poll event method")
unittest{
	string[] args = [];
	SDLApp sdlapp = new SDLApp(args ,"0.0.0.0", 49494);
	string log = "";
	Socket skt = new MockSocket(log);
	Socket skt2 = new MockSocket(log);
	bool runApplication = true;
	bool drawing = false;
	bool ctrlZPressed = false;
	bool ctrlYPressed = false;
	int[] coordinates = new int[0];
	coordinates ~= -1;
	SDL_Event e;
	e.type = SDL_MOUSEBUTTONUP;
	SDL_PushEvent(&e);
	sdlapp.pollEvents(skt, skt2, runApplication, drawing, ctrlZPressed, ctrlYPressed, coordinates, e);
	assert(log.equal("send called") == true);
	assert(drawing == false);
	assert(coordinates.length == 0);
}
