

class Node(T){
	T val;
	Node!(T) next;
    Node!(T) prev;

	this(T val) {
		this.val = val;   
		this.next = null;
        this.prev = null;
    } 
    this() {
      // this.val;
        this.next = null;
        this.prev = null;
    }

    // ~this(){
    //     this.next = null;
    //     this.prev = null;   
    // }
}