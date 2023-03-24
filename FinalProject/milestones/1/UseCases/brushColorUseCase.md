**TODO for your task:** Edit the Text in italics with your text.

<hr>

# Feature Use Case

<hr>

**Use Case**: brush color change

**Primary Actor**: user

**Goal in Context**: Selecting a new paint brush color to paint with.

**Preconditions**: The program must be running and in a responsive state.

**Trigger**: input the R B G or click to choose color
  
**Scenario**: A user will drag their mouse to the top of titlebar and select a color and right click to choose or input R G B .

**Exceptions**: The program may be potentially unresponsive and can't change the brush color. In this case, the program should be restart.

**Priority**: Medium-priority.

**When available**: Second release.

**Channel to actor**: The primary actor communicates through I/O devices (mouse). The system or GUI is responsible for maintaining focus of the window when the user clicks and should response within 0.5 second.

**Secondary Actor**: GUI

**Channels to Secondary Actors**: GUI may pass the argument to Canvas through functions.

**Open Issues**: Implement GUI.

<hr>



(adapted by Pressman and Maxim, Software Engineering: A Practitioner’s Approach, pp. 151-152, from Cockburn,
A., Writing Effective Use-Cases, Addison-Wesley, 2001)
