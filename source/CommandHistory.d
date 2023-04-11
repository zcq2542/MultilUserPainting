import Deque:Deque;
import Node:Node;

import std.stdio;
import std.exception;
import core.exception : AssertError;

class CommandHistory : Deque!(int[]){
    // private Deque historyArray;
    private Node!(int[]) pointerCur;
    
    this() {
        super();
        pointerCur = this.frontPointer;
    }

    ~this() {
        // destroy(this.historyArray);
    }

    /** 
     * add new command to command history deque.
     * Params:
     *   command = command to be add.
     */
    public void add(int[] command) {
        if (this.backPointer.prev != this.frontPointer && this.pointerCur.next != this.backPointer) { // there are nodes between backPointer and curent pointed node
            this.backPointer.prev.next = null; // break connect form last node to the backPointer node.
            // writeln("current pointed", pointerCur.val);
            // writeln("current next pointed", pointerCur.next is null);
            pointerCur.next.prev = null; // break connect form next node to current pointed node.
        }
        
        pointerCur.next = this.backPointer;
        this.backPointer.prev = pointerCur; // move backPointer to the next of current pointed node.

        this.push_back(command);
        pointerCur = pointerCur.next;
        // writeln(pointerCur.val);
    }

    /** 
     * redo last undo command.
     * Returns: an int array
     */
    public int[] redo() {
        if (pointerCur == this.backPointer.prev) throw new Exception("no command to redo");
        // assert(pointerCur != this.backPointer.prev);

        int[] res = new int[](0);
        res ~= pointerCur.next.val;
        pointerCur = pointerCur.next;
        return res;
    }

    /** 
     * undo last command.
     * Returns: an int array.
     */
    public int[] undo() {
        if (pointerCur == this.frontPointer) throw new Exception("no command to undo");
        // assert(pointerCur != this.frontPointer);
        int[] res = new int[](0);
        res ~= pointerCur.val;
        pointerCur = pointerCur.prev;
        return res;
    }
}

unittest
{
    auto ch = new CommandHistory();
    ch.add([1, 2]);
    ch.add([1,2,3]);
    writeln(ch.undo());
    // assert(ch.undo() == [1,2,3]);
    writeln(ch.undo());
    // assert(ch.undo() == [1, 2]);
    writeln(ch.redo());
    // assert(ch.redo() == [1, 2]);
    writeln(ch.redo());
    int[] res = [1,2,3];
    // assert(ch.redo()[0] == res[0]);
    // assert(ch.redo()[1] == res[1]);
    // assert(ch.redo()[2] == res[2]);
}

unittest
{
    auto ch = new CommandHistory();
    ch.add([1, 2]);
    ch.add([1,2,3]);
    // writeln(ch.undo());
    int[] res = ch.undo();
    assert(res[0] == 1);
    assert(res[1] == 2);
    assert(res[2] == 3);
    // writeln(ch.undo());
    res = ch.undo();
    assert(res[0] == 1);
    assert(res[1] == 2);
    // writeln(ch.redo());
    res = ch.redo();
    assert( res[0]== 1);
    assert( res[1]== 2);
    // writeln(ch.redo());
    res = ch.redo();
    assert( res[0]== 1);
    assert( res[1]== 2);
    assert(res[2] == 3);
    // assert(ch.redo()[1] == res[1]);
    // assert(ch.redo()[2] == res[2]);
}

// unittest
// {
//     auto ch = new CommandHistory();
    
//     writeln(ch.undo());
//     // assert(ch.undo() == [1,2,3]);
//     writeln(ch.undo());
//     // assert(ch.undo() == [1, 2]);
//     writeln(ch.redo());
//     // assert(ch.redo() == [1, 2]);
//     writeln(ch.redo());
//     // assert(ch.redo() == [1,2,3]);
// }
unittest
{
    auto ch = new CommandHistory();
    ch.add([1, 2]);
    ch.add([1,2,3]);
    writeln(ch.undo());
    // assert(ch.undo() == [1,2,3]);
    writeln(ch.undo());
    // assert(ch.undo() == [1, 2]);
    ch.add([4]);
    ch.add([5]);
    writeln(ch.undo()); // [5]
    ch.add([6]);
    writeln(ch.undo()); // [6]
    writeln(ch.undo()); // [4]
    writeln(ch.redo()); // [4]
    // assert(ch.redo() == [1, 2]);
    writeln(ch.redo()); // [6]
    // int[] res = [1,2,3];
    // assert(ch.redo()[0] == res[0]);
    // assert(ch.redo()[1] == res[1]);
    // assert(ch.redo()[2] == res[2]);
}
