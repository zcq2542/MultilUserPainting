/** 
 * Clolor struct, restore the pixel color info.
 */
struct Color {
	ubyte r;
	ubyte g;
	ubyte b;

	this(ubyte r, ubyte g, ubyte b) {
		this.r = r;
		this.g = g;
		this.b = b;
	}
}
