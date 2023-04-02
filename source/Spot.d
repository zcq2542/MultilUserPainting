import Color:Color;

struct Spot {
     int xPos;
     int yPos;
     Color color;

     this(int xPos, int yPos, Color color){
        this.xPos = xPos;
        this.yPos = yPos;
        this.color = color;
     }
}