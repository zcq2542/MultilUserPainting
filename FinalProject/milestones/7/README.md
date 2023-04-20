# Building Software

- [ ] Instructions on how to build your software should be written in this file
	- This is especially important if you have added additional dependencies.
	- Assume someone who has not taken this class (i.e. you on the first day) would have read, build, and run your software from scratch.
- You should have at a minimum in your project
	- [ ] A dub.json in a root directory
    	- [ ] This should generate a 'release' version of your software
  - [ ] Run your code with the latest version of d-scanner before commiting your code (could be a github action)
  - [ ] (Optional) Run your code with the latest version of clang-tidy  (could be a github action)

*Modify this file to include instructions on how to build and run your software. Specify which platform you are running on. Running your software involves launching a server and connecting at least 2 clients to the server.*

We build the App on Ubuntu platform.
1. Installing SDL if you don't have. (https://wiki.libsdl.org/SDL2/Installation)
2. Installing GTKD. with command apt-get install libgtkd-3-dev
3. go to the dir FinalProject-AURORA/source/  run the server as rdmd -I./common server/app.d 0.0.0.0 50003
4. go to the dir FinalProject-AURORA/source/chat  run the chat server as rdmd -I./common chat/ChatServer 0.0.0.0 50004
4. go to root dir. FinalProject-AURORA. dub run -- 0.0.0.0 50003 0.0.0.0 50004
then the SDLApp should be running along with chat.
