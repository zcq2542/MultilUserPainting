import Deque:Deque;

class CommandHistory {
    private Deque historyArray;
    
    this() {
        this.historyArray = new Deque(!int[]);
    }

    ~this() {
        destroy(this.historyArray);
    }

    public void add(int[] command) {
        historyArray.
    }
}

