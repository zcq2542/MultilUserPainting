import Color:Color;

/** 
 * Spot class has pixel coordinates and color.
 */
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