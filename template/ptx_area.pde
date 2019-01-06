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
  
  import java.util.*;

  public enum area_shape {DOT, LINE, GAP, FILL};

 /**
* This class describe what an area of proximity is in the context of the ptx library.
* Area of proximity are a simplification of an area,
* and used to list the proximities of areas with one another
*
* @author  Roman Miletitch
* @version 0.7
*
**/

public class proxArea {
  proxArea(int _id, vec2i _center, vec2i _pos, vec2i _from, vec2i _to) {
    id =_id;
    pos = _pos;
    from = _from;
    center = _center;
    to = _to;
  }

  int id;
  vec2i pos;
  vec2i center;
  vec2i from, to;
};

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

  // Relation to other areas
  ArrayList<proxArea> listProx; // relative positions of other areas
  ArrayList<Integer> listOverMe; // Areas that contains me
  ArrayList<Integer> listInsideMe; // Areas that I contain
  ArrayList<proxArea> listContact; // relative positions of touched areas
  
  public area() {
    center = new vec2i();
    posXY = new ArrayList<vec2i>(); 
    listContour = new ArrayList< ArrayList<vec2i> >(); 
    listProx = new ArrayList<proxArea>();
    listContact  = new ArrayList<proxArea>();
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
    listProx = new ArrayList<proxArea>();
    listContact  = new ArrayList<proxArea>();
  }
  
}