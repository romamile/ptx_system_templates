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
 
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.Collections;


public enum DIRECTION { EAST, WEST, NORTH, SOUTH };


 /**
* This class defines the core algorithm for drawing recognition and
* optical processing.
*
*
* @author  Roman Miletitch
* @version 0.7
*
**/
 //<>//
public class ptx {

  ArrayList<area> listArea; 

  // RECOG COLORS
  ArrayList<hueInterval> listZone;
  hueInterval backHue;
  boolean hasBackHue;

  float seuilSaturation, seuilValue;

  // Hues
  int[] histHue;
  int[] hueRef;
  int indexHue;

  // OPTICS CAMERA
  float ratioCam;
  float a0, a1;

  // OPTICS PROJECTOR
  float rotX_projo, rotY_projo, rotZ_projo;
  float ecart_projo;
  float transX_projo, transY_projo, transZ_projo;

  // Local but not so local

  int[] ids;
  int[] idsArea;
  ArrayList<vec2i> pixest;
  int inC, outC;

  int ww, hh;
  int rMask;

  ArrayList<Integer> idLabels;

  public float flashLeft, flashRight, flashUp, flashDown;

  // TEMP
  public float seuil_ratioSurfacePerimetre;
  public float seuil_tailleSurface;
  public int seuil_smallArea;

  public ptx() {

    backHue = new hueInterval();
    hasBackHue = false;

    histHue = new int[360];
    hueRef = new int[360];

    listZone = new ArrayList<hueInterval>();
    pixest   = new ArrayList<vec2i>();
    idLabels = new ArrayList<Integer>();
    listArea = new ArrayList<area>();

    inC = 3;
    outC = 3;

    rMask = 270;

    ratioCam = 1;
    indexHue = 0;

    flashLeft = 0;
    flashRight = 0;
    flashUp = 0;
    flashDown = 0;
    //showPince = true;


    // 2) Trapeze
    a0 = a1 = 1;

    // Projo
    rotX_projo = 0; 
    rotY_projo = 0; 
    rotZ_projo = 0;
    ecart_projo =1;
    transX_projo =0; 
    transY_projo =0; 
    transZ_projo = 0;

    listZone.add(new hueInterval(350, 50));
    listZone.add(new hueInterval(90, 150));
    listZone.add(new hueInterval(210, 270));
    listZone.add(new hueInterval(60, 80));

    for (int i = 0; i < 360; ++i) {
      hueRef[i] = -1;
      histHue[i] = 0;
    }

    seuilSaturation = 0.32;
    seuilValue = 255;

    // TEMP
    seuil_ratioSurfacePerimetre = 1.3;
    seuil_tailleSurface = 400;
    seuil_smallArea = 200;
  }

  
  /** 
  * Calculate two parametrs for the geometric correction on the camera picture.
  * @param _ROI          the 4 points defining the region of interest
  */
  public void calcA0A1(vec2f[] _ROI) {

    vec2f o = _ROI[0];
    vec2f a = _ROI[0].subTo(_ROI[0]);
    vec2f b = _ROI[1].subTo(_ROI[0]);
    vec2f c = _ROI[2].subTo(_ROI[0]);
    vec2f d = _ROI[3].subTo(_ROI[0]);

    System.out.println("---");
    System.out.println(a.x + ", " + a.y);
    System.out.println(b.x + ", " + b.y);
    System.out.println(c.x + ", " + c.y);
    System.out.println(d.x + ", " + d.y);

    a0 = (c.x / d.x - c.y / d.y) / (b.x / d.x - b.y / d.y);
    a1 = (c.x / b.x - c.y / b.y) / (d.x / b.x - d.y / b.y);
  }

  /** 
  * Apply the geometric correction on the camera picture.
  * @param _in     Origine Image
  * @param _out    Destination Image
  * @param  _wBef  width of the origine image 
  * @param  _hBef  height of the origine image 
  * @param  _wAft  width of the destination image 
  * @param  _hAft  height of the destination image 
  * @param  _ROI   the 4 points defining the region of interest
  */
  public void trapeze(PImage _in, PImage _out, int _wBef, int _hBef, int _wAft, int _hAft, vec2f[] _ROI) {

    ratioCam = ((float)_hAft)/_hBef;

    vec2f o = _ROI[0];
    vec2f a = _ROI[0].subTo(_ROI[0]);
    vec2f b = _ROI[1].subTo(_ROI[0]);
    vec2f c = _ROI[2].subTo(_ROI[0]);
    vec2f d = _ROI[3].subTo(_ROI[0]);

    //CALCULATE A0 A1 in other function

    float x1, y1, det;
    int ii, jj;

    _in.loadPixels();
    _out.loadPixels();

    for (int i = 0; i < _wAft; ++i)
      for (int j = 0; j < _hAft; ++j) {

        // Normaliser sur [0,1]
        float x2 = float(i) / _wAft;
        float y2 = float(j) / _hAft;

        det = a0*a1 + a1*(a1 - 1)*x2 + a0*(a0 - 1)*y2;
        x1 = a1*(a0 + a1 - 1)*x2 / det;
        y1 = a0*(a0 + a1 - 1)*y2 / det;

        ii = int(o.x + b.x*x1 + d.x*y1);
        jj = int(o.y + b.y*x1 + d.y*y1);

        // TEST SI PAS HORS IMAGE  
        if (ii < _wBef && jj < _hBef && ii > 0 && jj > 0) {
          _out.pixels[j*_wAft + i] = _in.pixels[jj*_wBef + ii]; //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
        }
      }

    _in.updatePixels();
    _out.updatePixels();

    //  hasImage = true;
  }

  /** 
  * Main function that calls other sub function in order to
  * parse the selected image and get the list of areas.
  * @param   in           Origine image
  * @param   outFilter    Filtered image
  * @param   outRez       End result image 
  * @param   _w           width of the image
  * @param   _h           height of the image
  */
  public boolean parseImage(PImage in, PImage outFilter, PImage outRez, int _w, int _h) {

    System.out.println("----------------------------------");
    System.out.println("--- PARSE IMAGE ---");

    long globStart = System.currentTimeMillis();
    long locStart  = System.currentTimeMillis();

    // 0) RESET & CLEAR
    ww = _w;
    hh = _h;
    ids = new int[_w*_h];
    idsArea = new int[_w*_h];

    reset(_w, _h);
    System.out.println("0) Reset, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 1) ISOLATE PIXELS OF INTEREST
    if ( ! isolateForeground(in, outFilter, outRez, _w, _h))
      return false;
    System.out.println("1) Isolate foreground, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 2) SMOOTH
    smooth(_w, _h, outFilter);
    System.out.println("2) Smooth, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 3) AGREGATE IN REGIONS
    extractRegions(_w, _h);
    System.out.println("3) Create Areas, in: " + (System.currentTimeMillis()-locStart) );

    // 4-1) ERASE SMALL AREAS
    removeSmallAreas(_w, _h);
    System.out.println("6) Remove small areas, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 4) CONTOUR
    detectContour(_w, _h);
    System.out.println("4) Create & Organise Contour, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    /*  std::cout << "=== CONTOUR DEBUG ===" << std::endl;
     for (auto it = listArea.begin(); it != listArea.end(); ++it) {  
     std::cout << "--- contour --- dis: " << it->disContour.size() << std::endl;
     for (auto itC = it->listContour.begin(); itC != it->listContour.end(); ++itC) 
     std::cout << itC->size() << std::endl;
     }*/

    // 6) ERASE SMALL COUNTOUR
    removeAeraWithSmallContour(_w, _h);
    System.out.println("6) Remove areas sith small, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();
    System.out.println("Final nbr Area: " + listArea.size() );

    /*
    System.out.println("Filtered");
     for (auto it = listArea.begin(); it != listArea.end(); ++it) {  
     System.out.println("---");
     for (auto itC = it->listContour.begin(); itC != it->listContour.end(); ++itC) 
     System.out.println(itC->size());
     }
     */

    // 7) DESCRIBE SHAPE
    describeShape();
    System.out.println("7) Describe shape, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // A l'arrache, idArea


    for (area it : listArea)
      for (vec2i itPos : it.posXY)
        idsArea[itPos.y * _w + itPos.x] = it.id; 


    System.out.println("------------------------" );
    System.out.println("---- TOTAL, in: " + (System.currentTimeMillis()-globStart) );

    System.out.println("Post nbr Area: " + listArea.size() );

    return true;
  }

  /** 
  * Reset all information from previous scans, allowing for a fresh new one.
  * @param  _w    width of the image
  * @param  _h    height of the image
  */
  public void reset(int _w, int _h) {
    pixest.clear();
    listArea.clear();

    for (int i = 0; i < _w*_h; ++i) {
      ids[i] = -1;
    }

    for (int i = 0; i < 360; ++i) {
      hueRef[i] = -1;
      histHue[i] = 0;
    }

    for (hueInterval myZone : listZone)
      for (int hue : myZone.getRange())
        hueRef[hue % 360] = myZone.getRef();
  }

  /** 
  * Isolate the color part of the image, mainly based on saturation
  * @param  in          Source Image
  * @param  outFilter   Destination Image Filtered
  * @param  outRez      Destination Image Result
  * @param  _w          width of the image
  * @param  _h          height of the image
  */
  //  public boolean isolateForeground(uint8_t* in, uint8_t* outFilter, uint8_t* outRez, int _w, int _h) {
  public boolean isolateForeground(PImage in, PImage outFilter, PImage outRez, int _w, int _h) {
    int sizeDrawing = 0;
    int hue;

    in.loadPixels();
    outFilter.loadPixels();
    outRez.loadPixels();

    // temp
    int marge = 7;
    ptx_color cTN, cT;
    cTN = new ptx_color();

    for (int i = 0; i < _w*_h; i++) {
      cT = new ptx_color(red(in.pixels[i]), green(in.pixels[i]), blue(in.pixels[i])); // use the "++" on pointer.

      if (
        // == Enough Color and not too bright
        cT.getS() >= seuilSaturation && cT.getV() <= seuilValue
        // == Not on the surface of the pince
        //&& (!showPince || (i / _w > heightPince + marge || i%_w < _w/2 - widthPince/2 - marge || i%_w > _w/2 + widthPince/2 + marge ))
        // == Not touching the edge (because of potential issue wiwth the turtle algo for contour)
        &&  i/ _w != 0 && i/ _w != _h-1 && i%_w != 0 && i%_w != _w-1 // FOR NOW
        // == Matching hue
        // && hueRef[ int(360 * cT.getH()) ] != -1
        // == Not the color of the "background"
                && ( !hasBackHue || !backHue.contains( floor(360*cT.getH()) ))
        // == Mask Disk
        //        && (i%_w-_w*0.5)*(i%_w-_w*0.5) + (i/_w-_h*0.5)*(i/_w-_h*0.5) < rMask*rMask 
        ) {

        hue = int(360 * cT.getH());
        histHue[hue]++;

        // Non Matching hue
        if (hueRef[int(360 * cT.getH())] == -1) {
          // OUT OF BONDS
          outFilter.pixels[i] = color(60);
          outRez.pixels[i] = color(60);
        } else {
          // GOOD
          sizeDrawing++;
          ids[i] = hueRef[hue];

          pixest.add(new vec2i(i%_w, i / _w));

          cTN.fromHSV(ids[i], 1, 1);
          outRez.pixels[i] = color(int(cTN.r * 255), int(cTN.g * 255), int(cTN.b * 255));
        }
        idsArea[i] = -1;
      } else {
        // BAD
        ids[i] = -1;
        idsArea[i] = -1;
        outFilter.pixels[i] = color(0);
        outRez.pixels[i] = 0;
      }
    }

    System.out.println("SIZE drawing: " + (sizeDrawing * 1.f / (_w*_h)) );
    if (sizeDrawing  * 1.f / (_w*_h) > 0.75) {
      System.out.println("TOO BIG DRAWING!");
      return false;
    }

    // Weight the color hues
    for (int i = 0; i < 360; ++i)
      histHue[i] /= 1;

    outFilter.updatePixels();
    outRez.updatePixels();

    return true;
  }

  /** 
  * Smoothing the resulting information (blur algo, black & white)
  * @param  _w          width of the image
  * @param  _h          height of the image
  * @param  outFilter   Image to process
  */
  public void smooth(int _w, int _h, PImage outFilter) {

    System.out.println("size: " + pixest.size());
    outFilter.loadPixels();

    int dense = 0, i=0, j=0;

    Iterator<vec2i> myVec = pixest.iterator();

    while (myVec.hasNext()) {
      vec2i s = myVec.next(); // must be called before you can call i.remove()

      i = s.x; 
      j = s.y;

      dense = 0;
      if (ids[(j + 1)*_w + (i - 1)] != -1) dense++;
      if (ids[(j)*_w + (i - 1)] != -1) dense++;
      if (ids[(j - 1)*_w + (i - 1)] != -1) dense++;

      if (ids[(j + 1)*_w + (i)] != -1) dense++;
      //
      if (ids[(j - 1)*_w + (i)] != -1) dense++;

      if (ids[(j + 1)*_w + (i + 1)] != -1) dense++;
      if (ids[(j)*_w + (i + 1)] != -1) dense++;
      if (ids[(j - 1)*_w + (i + 1)] != -1) dense++;

      if (dense <= 3) {
        // BAD
        ids[j*_w + i] = -1;
        outFilter.pixels[i] = color(0);

        myVec.remove();
      }
    }

    System.out.println("size: " + pixest.size());
    outFilter.updatePixels();
  }


  private int find(ArrayList<Integer> parents, int x) {
    //  return (parents[x]==x) ? x : find(parents,parents[x]);
    if (parents.get(x)==x) {
      return x;
    } else {
      return find(parents, parents.get(x));
    }
  }

  private void unionCC(ArrayList<Integer> parents, int x, int y) {
    int xRoot = find(parents, x);
    int yRoot = find(parents, y);
    parents.set(xRoot, yRoot);
  }

  /** 
  * Extract region as group of pixels for each colors.
  * This functions generate the areas that we will then process further.
  * @param  _w          width of the image
  * @param  _h          height of the image
  */
  public void extractRegions(int _w, int _h) {

    int[] data = ids.clone();
    //TODO chgeck    idLabels = std::vector<unsigned int>(_w*_h,0);
    idLabels = new ArrayList<Integer>( Collections.nCopies(_w*_h, 0) );

    int mark = 1; //0 is for background pixels

    //to store equivalence between neighboring labels
    ArrayList<Integer> equivalences = new ArrayList<Integer>();
    equivalences.add(0);//to label background

    ArrayList<Integer> neighborsIndex = new ArrayList<Integer>();
    neighborsIndex.add(-1-_w);//north west neighbor
    neighborsIndex.add(-_w);//north neighbor
    neighborsIndex.add(-_w+1);//north-east neighbor
    neighborsIndex.add(-1);//west neighbor

    // Check what is a set, what is a map, and possible stuff in Java.

    //-----------
    // First Pass
    for (int i=0; i<_w*_h; ++i) {
      if (data[i]!=-1) {//is not background

        //get the neighboring elements of the current element
        //  std::set<unsigned int> neighborsLabels;
        //  LinkedHashSet<E> OR HashSet ... ?
        LinkedHashSet<Integer> neighborsLabels = new LinkedHashSet<Integer>();
        for (int j=0; j<neighborsIndex.size(); ++j) {  // Parse through all interesting neighbors
          int neighborsIdx=i+neighborsIndex.get(j);
          if (neighborsIdx>=0 && neighborsIdx<_w*_h) {   // Neighbor is inside range
            if (data[neighborsIdx]==data[i]) {         // Neighbor is not background
              neighborsLabels.add(idLabels.get(neighborsIdx));
            }
          }
        }

        if (neighborsLabels.size()==0) { // No neighbors
          equivalences.add(mark);
          idLabels.set(i, mark);
          mark++;
        } else {

          //find the neighbors with the smallest label & assign it to current label
          int minLabel = Integer.MAX_VALUE;
          for (int it : neighborsLabels)
            minLabel = (it < minLabel) ? it : minLabel;
          idLabels.set(i, minLabel);

          //update equivalences
          for (int it1 : neighborsLabels)
            for (int it2 : neighborsLabels)
              unionCC(equivalences, equivalences.get(it1), it2);
        }
      }
    }


    //second pass
    LinkedHashMap<Integer, Integer> continiousLabel = new LinkedHashMap<Integer, Integer>();
    int nextLabel=1;
    for (int i=0; i<idLabels.size(); ++i) {
      if (idLabels.get(i)>0) {
        int ccId = find(equivalences, idLabels.get(i));
        if (! continiousLabel.containsKey(ccId)) {
          continiousLabel.put(ccId, nextLabel);
          nextLabel++;
        }
        idLabels.set(i, continiousLabel.get(ccId));
      }
    }

    // Create areas
    LinkedHashMap<Integer, Integer> labelToArea = new LinkedHashMap<Integer, Integer>();
    for (int i = 0; i < idLabels.size(); ++i) {
      if (idLabels.get(i) != 0) // We're on foreground
        if (! labelToArea.containsKey(idLabels.get(i))) { // Not known label => add a new area
          labelToArea.put(idLabels.get(i), listArea.size());
          listArea.add( new area(listArea.size(), new vec2i(i%_w, i / _w), ids[i]) );
        } else {
          listArea.get( labelToArea.get(idLabels.get(i)) ).posXY.add( new vec2i(i%_w, i / _w) );
        }
    }

    //associateAreasWithColorId
    for (area it : listArea)
      for (int i = 0; i < listZone.size(); ++i)
        if ( listZone.get(i).contains(it.hue) )
          it.colId = i;
          
    System.out.println("First nbr Area: " + listArea.size() );
  }
  
  
  /** 
  * Removes area which size (surface) is under a threshold
  * @param  _w          width of the image
  * @param  _h          height of the image
  */
  public void removeSmallAreas(int _w, int _h) {

    Iterator<area> myArea = listArea.iterator();
    while (myArea.hasNext()) {
      area it = myArea.next(); // must be called before you can call i.remove()

      if (it.posXY.size() <= 40) {
        for (vec2i itPos : it.posXY) {
          ids[itPos.y * _w + itPos.x] = -1; // reset ids
          idsArea[itPos.y * _w + itPos.x] = -1; // reset ids
        }
        myArea.remove();
      }
    }
  }

  /** 
  * Extract controur from the regions previously extracted.
  * Both information is available in the area class.
  * @param  _w          width of the image
  * @param  _h          height of the image
  */
  public void detectContour(int _w, int _h) {
    
    // 0 === Compute Center by averaging
    for (area it : listArea) {
      for (vec2i itPx : it.posXY)
        it.center.addMe(itPx);
      it.center.x /= it.posXY.size();
      it.center.y /= it.posXY.size();
    }
    
    
    for (area it : listArea) {

      ArrayList<vec2i> disContour = new ArrayList<vec2i>();

      // 1 === Isolate all pixels of contour
      for (vec2i itPx : it.posXY) {

        // If pixel on the boundary of the image => CONTOUR
        if (itPx.x == 0 || itPx.x == _w - 1 || itPx.y == 0 || itPx.y == _h - 1) {
          disContour.add(itPx);
        } else {

          // If one of the neighbor of the pixel has different label => CONTOUR
          int idPx = itPx.y*_w + itPx.x;
          if ((idLabels.get(idPx)
            & idLabels.get(idPx - 1)  & idLabels.get(idPx + 1) //weast and east neighbors
            & idLabels.get(idPx + _w) & idLabels.get(idPx - _w) //south and north neighbors
            ) != idLabels.get(idPx)) {
            disContour.add(itPx);
          }
        }
      }

      // 2 === Orientate and define the sub contours (i.e. holes)
      //uses paper turtle algorithm to find all point on each boundary
      //assertion : pixel is never on image edges...

      while (disContour.size() > 0) {
        ArrayList<vec2i> boundary = new ArrayList<vec2i>(); // aimed oriented boundary

        //get first boundary point
        vec2i firstPoint = disContour.get(0);

        boundary.add(firstPoint);
        disContour.remove(firstPoint);

        DIRECTION dir=DIRECTION.NORTH;

        vec2i currPoint = updateIndex(firstPoint, dir, _w);

        while (currPoint.diffFrom(firstPoint)) { 
          if (idLabels.get(currPoint.y*_w + currPoint.x) == idLabels.get(firstPoint.y*_w + firstPoint.x)) {
            // Pixel on the area's boundary, remove for non oriented & add to oriented.
            if (boundary.get(boundary.size() - 1).diffFrom(currPoint)) //store boundary point (if not just previously stored already) // TODO: CHECK IF ITS EVER TRIGGERED
              boundary.add(currPoint);
            // Get rid of the point in boundariesPoints

            // Remove elements that are same as currPoint from boundariesPoints.
            // No idea why, but issue with ".remove()" so hand coded
            Iterator<vec2i> myVec = disContour.iterator();
            while (myVec.hasNext()) {
              vec2i itV = myVec.next(); // must be called before you can call i.remove()

              if (itV.x == currPoint.x && itV.y == currPoint.y) {
                myVec.remove();
              }
            }

            dir = toTheLeft(dir);
          } else {
            // Pixel NOT on the area's boundary
            dir=toTheRight(dir);
          }
          currPoint = updateIndex(currPoint, dir, _w);
        }

        it.listContour.add(boundary);
      }
    }
  }


  /** 
  * Removes area which perimeter (contour) is under a threshold
  * @param  _w          width of the image
  * @param  _h          height of the image
  */
  public void removeAeraWithSmallContour(int _w, int _h) {

    for (area it : listArea) {
      Iterator<ArrayList<vec2i>> itContour = it.listContour.iterator();

      while (itContour.hasNext()) {
        ArrayList<vec2i> presContour = itContour.next(); // must be called before you can call i.remove()
        if (presContour.size() < 33) { //not enough to create a real 2D shape
          itContour.remove();
        }
      }
    }


    Iterator<area> myArea = listArea.iterator();
    while (myArea.hasNext()) {
      area it = myArea.next(); // must be called before you can call i.remove()

      if (it.listContour.isEmpty()) {
        for (vec2i itPos : it.posXY) {
          ids[itPos.y * _w + itPos.x] = -1; // reset ids
          idsArea[itPos.y * _w + itPos.x] = -1; // reset ids
        }
        myArea.remove();
      }
    }
  }

  /** 
  * Adding spacial descriptors to all area extracted from the drawing.
  */
  public void describeShape() {

    for (area it : listArea) {

      if (it.listContour.size() > 1) {
        it.myShape = area_shape.GAP;
      } else {
        
        if (it.posXY.size() < seuil_tailleSurface) {
            it.myShape = area_shape.DOT;           
        } else {
          
          //      if (it->disContour.size() > 1.3 * std::sqrt(4 * 3 * it->posXY.size())) {
          if (it.listContour.get(0).size() > seuil_ratioSurfacePerimetre * Math.sqrt(4 * 3 * it.posXY.size())) {
            it.myShape = area_shape.LINE;
          } else {
              it.myShape = area_shape.FILL;
         
          
          }
        
        }
      }
    }
  }

  


  DIRECTION toTheLeft(DIRECTION currentDir) {
    switch (currentDir) {
    case EAST:  return DIRECTION.NORTH;
    case NORTH: return DIRECTION.WEST;
    case WEST:  return DIRECTION.SOUTH;
    case SOUTH: return DIRECTION.EAST;
    }
    System.out.println("WARNING, ISSUE!!! in DrawPlay.toTheLeft");
    return DIRECTION.NORTH;
  }

  DIRECTION toTheRight(DIRECTION  currentDir) {
    switch(currentDir) {
    case EAST:  return DIRECTION.SOUTH;
    case SOUTH: return DIRECTION.WEST;
    case WEST:  return DIRECTION.NORTH;
    case NORTH: return DIRECTION.EAST;
    }
    System.out.println("WARNING, ISSUE!!! in ptx.toTheRight");
    return DIRECTION.NORTH;
  }

  int updateIndex(int idx, DIRECTION dir, int width) {
    switch(dir) {
    case EAST:  return idx+1;
    case SOUTH: return idx+width;
    case WEST:  return idx-1;
    case NORTH: return idx-width;
    }
    System.out.println("WARNING, ISSUE!!! in ptx.updateIndex");
    return -2;
  }

  vec2i updateIndex(vec2i _v, DIRECTION dir, int width) {
    vec2i _vT = new vec2i();
    _vT.x = _v.x; 
    _vT.y = _v.y;

    switch(dir) {
    case EAST:  _vT.x+=1; break;
    case SOUTH: _vT.y+=1; break;
    case WEST:  _vT.x-=1; break;
    case NORTH: _vT.y-=1; break;
    }
    return _vT;
  }


  
}