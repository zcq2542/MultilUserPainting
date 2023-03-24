**TODO for your task:** Edit the Text in italics with your text.

<hr>

# Feature Use Case

<hr>

**Use Case**: entire history of previous command available

**Primary Actor**:  server.

**Goal in Context**: When a client joins later, they should have the entire history of previous commands available to them.

**Preconditions**: Server running well.

**Trigger**: a new client connect to the server.
  
**Scenario**: When a new client connect to the server. Server will send the whole previous command history to the client.
 
**Exceptions**: Server is down. Need to restart server.

**Priority**: High-priority.

**When available**: First release.

**Channel to actor**: TCP connection or UDP datagram.

**Secondary Actor**: Client

**Channels to Secondary Actors**: TCP connection or UDP datagram. For client toi receive the message from server.

**Open Issues**: need build the client-server network and command object.

<hr>



(adapted by Pressman and Maxim, Software Engineering: A Practitioner’s Approach, pp. 151-152, from Cockburn,
A., Writing Effective Use-Cases, Addison-Wesley, 2001)
