// Run your program with: 
// dmd Deque.d -unittest -of=test && ./test
//
// This will execute each of the unit tests telling you if they passed.

import std.stdio;
import std.exception;
import core.exception : AssertError;
import Node:Node;


/*
    The following is an interface for a Deque data structure.
    Generally speaking we call these containers.
    
    Observe how this interface is a templated (i.e. Container(T)),
    where 'T' is a placeholder for a data type.
*/
interface Container(T){
    // Element is on the front of collection
    void push_front(T x);
    // Element is on the back of the collection
    void push_back(T x);
    // Element is removed from front and returned
    // assert size > 0 before operation
    T pop_front();
    // Element is removed from back and returned
    // assert size > 0 before operation
    T pop_back();
    // Retrieve reference to element at position at index
    // assert pos is between [0 .. $] and size > 0
    ref T at(size_t pos);
    // Retrieve reference to element at back of position
    // assert size > 0 before operation
    ref T back();
    // Retrieve element at front of position
    // assert size > 0 before operation
    ref T front();
    // Retrieve number of elements currently in container
    size_t size();
}

/*
    A Deque is a double-ended queue in which we can push and
    pop elements.
    frontPointer     Node            backPointer
    | | -----------> | | ----------> | |
    | | <----------- | | <---------- | |
    Note: Remember we could implement Deque as either a class or
          a struct depending on how we want to extend or use it.
          Either is fine for this assignment.
*/
class Deque(T) : Container!(T){
    // Implement here

	  size_t DequeSize;
	  Node!(T) frontPointer;
	  Node!(T) backPointer;
  
    this() {
      this.frontPointer = new Node!(T);
      this.backPointer = new Node!(T);
      this.frontPointer.next = this.backPointer;
      this.backPointer.prev = this.frontPointer;
      this.DequeSize = 0;
    }

    ~this(){
      Node!(T) cur = frontPointer;
      while(cur !is null) {
        Node!(T) next = cur.next;
        destroy(cur);
        cur = next;
      }
    }
    

    public:
    override void push_front(T x) {
        Node!(T) newNode = new Node!(T)(x);
        newNode.next = this.frontPointer.next;
        newNode.next.prev = newNode;
        this.frontPointer.next = newNode;
        newNode.prev = this.frontPointer;
        ++this.DequeSize;
    }
    override void push_back(T x) {
        Node!(T) newNode = new Node!(T)(x);
        newNode.prev = this.backPointer.prev;
        newNode.prev.next = newNode;
        newNode.next = this.backPointer;
        this.backPointer.prev = newNode;
        ++this.DequeSize;
    }
    override T pop_front() {
        assert(this.DequeSize > 0);
        T res = this.frontPointer.next.val;
        Node!(T) cur = this.frontPointer.next;
        this.frontPointer.next = cur.next;
        this.frontPointer.next.prev = this.frontPointer;
        destroy(cur);
        --this.DequeSize;
        return res;
    }

    override T pop_back() {
        assert(this.DequeSize > 0);
        Node!(T) cur = this.backPointer.prev;
        T res = cur.val;
        this.backPointer.prev = cur.prev;
        this.backPointer.prev.next = this.backPointer;
        destroy(cur);
        --this.DequeSize;
        return res;
    }

    override ref T at(size_t pos) {
        assert(DequeSize > pos);
        Node!(T) cur = this.frontPointer.next;
        for (size_t i = 0; i < pos; ++i) {
            cur = cur.next;
        }
        return cur.val;
    }

    override ref T back() {
        assert(this.DequeSize > 0);
        return (this.backPointer.prev.val);
    }

    override ref T front() {
        assert(this.DequeSize > 0);
        return (this.frontPointer.next.val);
    }

    override size_t size() {
        return this.DequeSize;
    }

}

// An example unit test that you may consider.
// Try writing more unit tests in separate blocks
// and use different data types.
unittest{ // test push_front(), pop_front() 
    auto myDeque = new Deque!(int);
    myDeque.push_front(1);
    myDeque.push_front(2);
    auto element = myDeque.pop_front();
    assert(element == 2);
    assert(myDeque.size() == 1);
}

unittest{ // test push_front(), pop_front() 
    auto myDeque = new Deque!(int);
    myDeque.push_front(1);
    auto element = myDeque.pop_front();
    assert(element == 1);
}

unittest{ // test pop_back when empty
    auto myDeque = new Deque!(int);
    assertThrown!AssertError(myDeque.pop_back());
}

unittest{ // test pop_front when empty
    auto myDeque = new Deque!(int);
    assertThrown!AssertError(myDeque.pop_front());
}

unittest{ // test push_back and pop_back pop_front
    auto myDeque = new Deque!(int);
    myDeque.push_back(1);
    myDeque.push_back(2);
    myDeque.push_back(3);
    auto element = myDeque.pop_back();
    assert(element == 3);
    element = myDeque.pop_front();
    assert(element == 1);
    element = myDeque.pop_front();
    assert(element == 2);
    // assertThrown();
}

unittest{ // test push_back, push_front, at()
    auto myDeque = new Deque!(int);
    myDeque.push_back(1);
    myDeque.push_back(2);
    myDeque.push_back(3);
    myDeque.push_front(-1);
    myDeque.push_front(-2);
    myDeque.push_front(-3);
    assert(myDeque.at(0) == -3);
    assert(myDeque.at(5) == 3);
    myDeque.at(0) = -10;
    assert(myDeque.at(0) == -10);
}

unittest{ // test ref back(), front() 
    auto myDeque = new Deque!(int);
    myDeque.push_back(1);
    myDeque.push_back(2);
    myDeque.push_back(3);
    myDeque.push_front(-1);
    myDeque.push_front(-2);
    myDeque.push_front(-3);
    assert(myDeque.front() == -3);
    assert(myDeque.back() == 3);
    myDeque.front() = -10;
    assert(myDeque.front() == -10);
    myDeque.back() = -10;
    assert(myDeque.back() == -10);
}

unittest{ // test size()
    auto myDeque = new Deque!(int);
    myDeque.push_back(1);
    myDeque.push_back(2);
    assert(myDeque.size() == 2);
    myDeque.pop_front();
    assert(myDeque.size() == 1);
}

unittest{
    auto myDeque = new Deque!(int);
    myDeque.push_back(1);
    myDeque.push_back(2);
    destroy(myDeque);
}

unittest{
    auto myDeque = new Deque!(int);
    destroy(myDeque);
}

void main(){
    // No need for a 'main', use the unit test feature.
    // Note: The D Compiler can generate a 'main' for us automatically
    //       if we are just unit testing, and we'll look at that feature
    //       later on in the course.	
}
