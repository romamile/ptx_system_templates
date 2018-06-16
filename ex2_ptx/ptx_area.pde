/*
 *  This file is part of the PTX library.
 *
 *  The PTX library is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  the PTX library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with the PTX library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
  
public enum area_shape {DOT, LINE, GAP, FILL};

 /**
* This class describe what an area is in the context of the ptx library.
* Area are generated when a picture is scanned, and are defined by 
* descriptors, center, perimetrs, colorId, and other useful graphical
* vocabulary.
*
*
* @author  Roman Miletitch
* @version 0.7
*
**/

public class area {

  int id;
  int hue;
  int colId;
  area_shape myShape;

  vec2i center;
  ArrayList<vec2i> posXY;
  ArrayList< ArrayList<vec2i> > listContour;

  public area() {
    center = new vec2i();
    posXY = new ArrayList<vec2i>(); 
    listContour = new ArrayList< ArrayList<vec2i> >(); 
  }
  
  public area(int _id, vec2i _pos, int _hue) {
    id = _id;
    hue = _hue;
    colId = -1;
    myShape = area_shape.LINE;

    center = new vec2i();
    posXY = new ArrayList<vec2i>(); 
    posXY.add(_pos);
    listContour = new ArrayList< ArrayList<vec2i> >(); 
  }
  
}