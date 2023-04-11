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

    public void add(int[] command) {
        pointerCur.next = this.backPointer;
        this.backPointer.prev = pointerCur;
        this.push_back(command);
        pointerCur = pointerCur.next;
    }

    public int[] redo() {
        // if (pointerCur == this.backPointer.prev) return new int[]();
        assert(pointerCur != this.backPointer.prev);

        int[] res = new int[](0);
        res ~= pointerCur.next.val;
        pointerCur = pointerCur.next;
        return res;
    }

    public int[] undo() {
        // if (pointerCur == this.frontPointer) return new int[]();
        assert(pointerCur != this.frontPointer);
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