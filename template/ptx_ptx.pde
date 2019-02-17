/* //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
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

import java.util.Arrays;
import java.util.Comparator;

// In for a penny...
import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;

import org.opencv.core.Mat;
import org.opencv.core.CvType;
import org.opencv.core.Core;


public enum DIRECTION { EAST, WEST, NORTH, SOUTH };
class vertex_t { double u, v, x, y; public vertex_t( double _u, double _v, double _x, double _y) {x=_x; y=_y; u=_u; v=_v;} }

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
  double[][] xform = new double[3][3];
//  ProjectiveTransform _keystoneMatrix;
  float ratioCam;
  float a0, a1;
  OpenCV opencv;
  Mat hMat;
  

  // Local but not so local

  int[] ids;
  int[] idsArea;
  ArrayList<vec2i> pixest;

  int ww, hh;
  int rMask;

  ArrayList<Integer> idLabels;

  public float flashLeft, flashRight, flashUp, flashDown;

  public int tooSmallThreshold;
  public int tooSmallContourThreshold;

  public boolean verboseImg;

  // TEMP
  public float seuil_ratioSurfacePerimetre;
  public float seuil_tailleSurface;
  public int seuil_smallArea;

  public ptx() {

    tooSmallThreshold = 40;
    tooSmallContourThreshold = 33;
    
    backHue = new hueInterval();
    hasBackHue = false;

    histHue = new int[360];
    hueRef = new int[360];

    listZone = new ArrayList<hueInterval>();
    pixest   = new ArrayList<vec2i>();
    idLabels = new ArrayList<Integer>();
    listArea = new ArrayList<area>();

    verboseImg = false;

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

  void refreshKeystone(final vec2f[] ROI, int _width, int _height) {
/*
    // bottom left, top left, top right, bottom right
    vec2f[] dst = new vec2f[] {
      new vec2f(ROI[0].x, ROI[0].y), new vec2f(ROI[1].x, ROI[1].y), new vec2f(ROI[2].x, ROI[2].y), new vec2f(ROI[3].x, ROI[3].y)
    };
    vec2f[] src = new vec2f[] {
      new vec2f(0., 0.), new vec2f(0., _height), new vec2f(_width, _height), new vec2f(_width, 0.)  
    };

    // refresh keystone
    _keystoneMatrix = new ProjectiveTransform(src, dst);
    */
    
    // TESTING
    
    // 1) prev test
/*      vec2f[] orig = new vec2f[] {
        new vec2f(200,200),
        new vec2f(200,400),
        new vec2f(400,400),
        new vec2f(400,200),
      };
      vec2f[] dest = new vec2f[] {
        new vec2f(0,0),
        new vec2f(0,600),
        new vec2f(800,600),
        new vec2f(800,0),
      };
   */           
    // 2) test

      /*
      println(dst[0]);
      println(dst[1]);
      println(dst[2]);
      println(dst[3]);
      
      
      println(src[0].toString() + "-->" + _keystoneMatrix.transform(src[0]).toString());
      println(src[1].toString() + "-->" + _keystoneMatrix.transform(src[1]).toString());
      println(src[2].toString() + "-->" + _keystoneMatrix.transform(src[2]).toString());
      println(src[3].toString() + "-->" + _keystoneMatrix.transform(src[3]).toString());
*/

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

    /*
    vertex_t[] vert = new vertex_t[4];
    
    vert[0] = new vertex_t(_ROI[0].x, _ROI[0].y, 0, 0);
    vert[1] = new vertex_t(_ROI[1].x, _ROI[1].y, _wAft, 0);
    vert[2] = new vertex_t(_ROI[2].x, _ROI[2].y, _wAft, _hAft);
    vert[3] = new vertex_t(_ROI[3].x, _ROI[3].y, 0, _hAft);
  
    double[][] xform = new double[3][3];
  
    // Calculate the transform needed. 
    quad_to_quad(vert, xform);
    
    
    for (int i = 0; i < 3; ++i)
      for (int j = 0; j < 3; ++j)
        println(xform[i][j]);
    
    _in.loadPixels();
    _out.loadPixels();

    for (int i = 0; i < _wAft; ++i)
      for (int j = 0; j < _hAft; ++j) {
        
        vec2f source = getSourcePoint( new vec2i(i, j) );
          
        // TEST SI PAS HORS IMAGE  
        if (floor(source.x) < _wBef && floor(source.y) < _hBef && floor(source.x) > 0 && floor(source.y) > 0) {
          _out.pixels[j*_wAft + i] = _in.pixels[floor(source.y)*_wBef + floor(source.x)];
        }
        
      }

    _in.updatePixels();
    _out.updatePixels();
*/

    /*
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
          _out.pixels[j*_wAft + i] = _in.pixels[jj*_wBef + ii]; //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
        }
      }

    _in.updatePixels();
    _out.updatePixels();

    //  hasImage = true;
    */
    

/*
    _in.loadPixels();
    _out.loadPixels();


    refreshKeystone(_ROI, _wAft, _hAft);
    if (null != _keystoneMatrix) {

      vec2f coords;
      for (int i = 0; i < _wAft; ++i) {
        for (int j = 0; j < _hAft; ++j) {

          coords = _keystoneMatrix.transform(new vec2f(i, j));

          int x = (int) Math.round(coords.x);
          int y = (int) Math.round(coords.y);

          // check point is in trapezoid
          if (0 <= x && x < _wBef && 0 <= y && y < _hBef) {
            _out.pixels[j*_wAft + i] = _in.pixels[y*_wBef + x]; //<>//
          }
        }
      }
    }

    _in.updatePixels();
    _out.updatePixels();
*/
    //  hasImage = true;
    
    
    // OPENCV
      
    // 2) Apply Homography  
    //opencv.loadImage(myPtxInter.myCam.mImg);
    //Mat unWarpedMarker = new Mat(myPtxInter.wFrameFbo, myPtxInter.hFrameFbo, CvType.CV_8U);    
    //Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, hMat, new Size(myPtxInter.wFrameFbo, myPtxInter.hFrameFbo));  
    //opencv.toPImage(unWarpedMarker, myPtxInter.myCam.mImgCroped);
    
    
    opencv.loadImage(_in);
    Mat unWarpedMarker = new Mat(_wAft, _hAft, CvType.CV_8U);    
    Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, hMat, new Size(_wAft, _hAft));  
    opencv.toPImage(unWarpedMarker, _out);

  }
  
  public void calculateHomographyMatrice(int _wAft, int _hAft, vec2f[] _ROI) {    
    Point[] canonicalPoints = new Point[4];
    canonicalPoints[0] = new Point(_wAft, 0);
    canonicalPoints[1] = new Point(0, 0);
    canonicalPoints[2] = new Point(0, _hAft);
    canonicalPoints[3] = new Point(_wAft, _hAft);
    MatOfPoint2f canonicalMarker = new MatOfPoint2f(canonicalPoints);
  
    Point[] points = new Point[4];
    for (int i = 0; i < 4; i++)
      points[i] = new Point(_ROI[i].x, _ROI[i].y);
    MatOfPoint2f marker = new MatOfPoint2f(points);
      
    hMat = Imgproc.getPerspectiveTransform(marker, canonicalMarker);     
  }
  
  /*
  Mat getPerspectiveTransformation(ArrayList<PVector> inputPoints, int w, int h) {
    Point[] canonicalPoints = new Point[4];
    canonicalPoints[0] = new Point(w, 0);
    canonicalPoints[1] = new Point(0, 0);
    canonicalPoints[2] = new Point(0, h);
    canonicalPoints[3] = new Point(w, h);
  
    MatOfPoint2f canonicalMarker = new MatOfPoint2f();
    canonicalMarker.fromArray(canonicalPoints);
  
    Point[] points = new Point[4];
    for (int i = 0; i < 4; i++) {
      points[i] = new Point(inputPoints.get(i).x, inputPoints.get(i).y);
    }
    MatOfPoint2f marker = new MatOfPoint2f(points);
    return Imgproc.getPerspectiveTransform(marker, canonicalMarker);
  }
  
  Mat warpPerspective(ArrayList<PVector> inputPoints, int w, int h) {
    Mat transform = getPerspectiveTransformation(inputPoints, w, h);
    Mat unWarpedMarker = new Mat(w, h, CvType.CV_8UC1);    
    Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, transform, new Size(w, h));
    return unWarpedMarker;
  }
*/
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
    smooth(_w, _h, outFilter, outRez);
    System.out.println("2) Smooth, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 3) AGREGATE IN REGIONS
    extractRegions(_w, _h);
    System.out.println("3) Create Areas, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

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

    // A l'arrache, idArea ids (colId);
    for (area it : listArea)
      for (vec2i itPos : it.posXY) {
        idsArea[itPos.y * _w + itPos.x] = it.id;
        ids[itPos.y * _w + itPos.x] = it.colId;
      }
    System.out.println("7.5) update ids & idAreas, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

    // 8) PROXIMITY SHAPES
    proximityArea();
    System.out.println("8) List proximity shape, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();
    
    // 9) Create PSHAPE SHAPES
    for (area it : listArea)
      it.createPShape();
      
    System.out.println("9) Create PShape, in: " + (System.currentTimeMillis()-locStart) );
    locStart = System.currentTimeMillis();

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

    if(verboseImg) {
      outFilter.loadPixels();
      outRez.loadPixels();
    }
    
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
          if(verboseImg) {
            outFilter.pixels[i] = color(60);
            outRez.pixels[i] = color(60);
          }
        } else {
          // GOOD
          sizeDrawing++;
          ids[i] = hueRef[hue];

          pixest.add(new vec2i(i%_w, i / _w));

          if(verboseImg) {
            cTN.fromHSV(ids[i], 1, 1);
            outRez.pixels[i] = color(int(cTN.r * 255), int(cTN.g * 255), int(cTN.b * 255));
          }
        }
        idsArea[i] = -1;
      } else {
        // BAD
        ids[i] = -1;
        idsArea[i] = -1;

        if(verboseImg) {
          outFilter.pixels[i] = color(0);
          outRez.pixels[i] = 0;
        }
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

    if(verboseImg) {
      outFilter.updatePixels();
      outRez.updatePixels();
    }
    
    return true;
  }

  /** 
   * Smoothing the resulting information (blur algo, black & white)
   * @param  _w          width of the image
   * @param  _h          height of the image
   * @param  outFilter   Image to process
   */
  public void smooth(int _w, int _h, PImage _outFilter, PImage _outRez) {

    System.out.println("size: " + pixest.size());
    
    if(verboseImg) {
      _outFilter.loadPixels();
      _outRez.loadPixels();
    }
    
    
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
    
        if(verboseImg) {
          _outFilter.pixels[i] = color(0);
          _outRez.pixels[i] = color(0);
        }
        
        myVec.remove();
      }
    }
   
    
    System.out.println("size: " + pixest.size());
    
    if(verboseImg) {
      _outFilter.updatePixels();
      _outRez.updatePixels();
    }
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

      if (it.posXY.size() <= tooSmallThreshold) {
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
        if (presContour.size() < tooSmallContourThreshold) { //not enough to create a real 2D shape
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


  void proximityArea() {

    int k = 3;
    ArrayList<vec2i> contA = new ArrayList<vec2i>(), contB = new ArrayList<vec2i>();
    vec2i dist = new vec2i(), temp = new vec2i(), from = new vec2i(), to = new vec2i();

    for (int i = 0; i < listArea.size(); ++i)
      for (int j = i + 1; j < listArea.size(); ++j) {

        contA = listArea.get(i).listContour.get(0);
        contB = listArea.get(j).listContour.get(0);
        dist = contB.get(0).subTo( contA.get(0) );

        from = contA.get(0);
        to = contB.get(0);

        for (int ii = 0; ii < contA.size(); ii+=k)
          for (int jj = 0; jj < contB.size(); jj+=k) {
            temp = contB.get(jj).subTo( contA.get(ii) );
            if (temp.squaredLength() < dist.squaredLength()) {
              dist = temp;
              from = contA.get(ii);
              to = contB.get(jj);
            }
          }

        listArea.get(i).listProx.add(new proxArea(listArea.get(j).id, listArea.get(j).center, dist, from, to));
        listArea.get(j).listProx.add(new proxArea(listArea.get(i).id, listArea.get(i).center, dist.multBy(-1), to, from));
      }


    // Sort by proximity
    //    for (area itA : listArea)
    //      Arrays.sort(itA.listProx, new SortbyDist()); 
    ////      std::sort(itA->listProx.begin(), itA->listProx.end(), &compareDist);


    for (area itA : listArea)
      Collections.sort(itA.listProx, new Comparator<proxArea>() {
        @Override
          public int compare(proxArea _a, proxArea _b) {
          return (_a.pos.x*_a.pos.x + _a.pos.y*_a.pos.y) - (_b.pos.x*_b.pos.x + _b.pos.y*_b.pos.y);
        }
      }
    );
  }


  DIRECTION toTheLeft(DIRECTION currentDir) {
    switch (currentDir) {
    case EAST:  
      return DIRECTION.NORTH;
    case NORTH: 
      return DIRECTION.WEST;
    case WEST:  
      return DIRECTION.SOUTH;
    case SOUTH: 
      return DIRECTION.EAST;
    }
    System.out.println("WARNING, ISSUE!!! in DrawPlay.toTheLeft");
    return DIRECTION.NORTH;
  }

  DIRECTION toTheRight(DIRECTION  currentDir) {
    switch(currentDir) {
    case EAST:  
      return DIRECTION.SOUTH;
    case SOUTH: 
      return DIRECTION.WEST;
    case WEST:  
      return DIRECTION.NORTH;
    case NORTH: 
      return DIRECTION.EAST;
    }
    System.out.println("WARNING, ISSUE!!! in ptx.toTheRight");
    return DIRECTION.NORTH;
  }

  int updateIndex(int idx, DIRECTION dir, int width) {
    switch(dir) {
    case EAST:  
      return idx+1;
    case SOUTH: 
      return idx+width;
    case WEST:  
      return idx-1;
    case NORTH: 
      return idx-width;
    }
    System.out.println("WARNING, ISSUE!!! in ptx.updateIndex");
    return -2;
  }

  vec2i updateIndex(vec2i _v, DIRECTION dir, int width) {
    vec2i _vT = new vec2i();
    _vT.x = _v.x; 
    _vT.y = _v.y;

    switch(dir) {
    case EAST:  
      _vT.x+=1; 
      break;
    case SOUTH: 
      _vT.y+=1; 
      break;
    case WEST:  
      _vT.x-=1; 
      break;
    case NORTH: 
      _vT.y-=1; 
      break;
    }
    return _vT;
  }

// New geometrie camera


  /*
   * Calculate a _reverse_ perspective transform matrix (perspective
   * transform, projective transform, homography, etc...).
   *
   *     Ax + By + C      Dx + Ev + F
   * u = -----------  v = -----------
   *     Gx + Hy + I      Gx + Hv + I
   *
   * Basically, a reverse mapping says: given the destination
   * coordinates (x,y) give me the cooresponding source coordinates.  A
   * forward mapping is also possible but there will be more "holes" in
   * the destination image and thus more information must be
   * interpolated.
   *
   * Homogeneous coordinate notation is used in these equations to
   * provide depth.  In Euclidean geometry there is no concept of
   * infinity, all 2D points are represented as (x,y).  In projective
   * geometry we need infinity to introduce depth.  Thus, a 2D point is
   * represented as a 3-vector (x',y',w).  Let x' = x/w where x is a
   * fixed value and x/0 is infinity.  The smaller w gets the larger the
   * value of x' becomes.  As w approaches 0, x' approaches infinity.
   * The homogeneous vector V = (x',y',w) = (x*w,y*w,w) represents the
   * actual point (x,y) = (x'/w,y'/w).  In practice, any non-zero number
   * can be used as w, but using w = 1 makes things simpler.
   *
   * For the mappings discussed, source point Ps = (u',v',q) and
   * destination point Pd = (x',y',w).  The forward projection matrix
   * will be shown as Msd and the reverse mapping shown as the adjoint
   * Mds.
   *
   * To transform any destination point to it's cooresponding source
   * point all you need to do is multiple the point by the inverse
   * mapping matrix:
   *
   * Ps = Pd * Mds
   *
   *                           /A D G\
   * (u',v',q)  =  (x',y',w) * |B E H|
   *                           \C F I/
   *
   * To solve the equation above we must solve 8 simultanious equations
   * for the coefficents used: A - H (I is always 1).  As descibed in
   * [Heckbert89] (pages 19-21) there is a quicker way when going from a
   * quadrilateral to a quadrilateral.
   *
   * First we compute the transform for a quadrilateral to a unit square
   * mapping (see Heckbert's paper for the simplified equations used
   * when we know it's a quad to square mapping).  Second, we compute
   * the adjoint (inverse) transform.  This adjoint transform is
   * actually a unit square to quadrilateral transform.  If we mulitply
   * the two matrices together (quad to square * square to quad) we get
   * a general quadilateral to quadrilateral transform matrix.
   *
   * This matrix becomes our Mds from above.  We then multiple each
   * homogenized destination point (homogenized == add a 1 on the end)
   * by the transform.  This gives us our homogeneous source point which
   * we must then normalize.
   *
   * The resulting point is then assigned a pixel color through linear
   * interpolation (area re-sampling).  This our anti-alias function
   * which gives the new image smoother lines and transitions.
   *
   * See Paul Heckbert's Master's thesis (sections 1 and 2):
   *   http://www.cs.cmu.edu/~ph/texfund/texfund.pdf
   *
   * Leptonica's affine transform page:
   *   http://www.leptonica.com/affine.html#RELATED-TRANSFORMS
   *
   * and this post on Stack Overflow:
   *   http://bit.ly/vxnpI5
   */
  
   
//  void perspective_transform(image_t *src_image, image_t *dst_image, vertex_t *v) {
    public void perspective_transform() {
    /*
     * Four pairs of vertices for the transformation operation.  Points
     * (u,v) denote the original quadrilateral.  Points (x,y) are the
     * new locations for the transformed quadrilateral.
     */
    vertex_t[] vert = new vertex_t[4];
    vert[0].u = 148;
    vert[0].v =  75;
    vert[0].x =   0;
    vert[0].y =   0;
  
    vert[1].u = 615;
    vert[1].v =  34;
    vert[1].x = 639;
    vert[1].y =   0;
  
    vert[2].u = 585;
    vert[2].v = 356;
    vert[2].x = 639;
    vert[2].y = 399;
  
    vert[3].u =  70;
    vert[3].v = 325;
    vert[3].x =   0;
    vert[3].y = 399;
  
    double[][] xform = new double[3][3];
  
    /* Calculate the transform needed. */
    quad_to_quad(vert, xform);
  
  /*
    int x, y;
    pixel_t *ptr;
    pixel_t pval;
    double svec[3], dvec[3];
  
    
    //  For each point in dest space, find the cooresponding source space
    //  point and then find a pixel color to assign.
     
    for (y = 0; y < dst_image->height; y++) {
      ptr = dst_image->pixels + (y * dst_image->stride);
      for (x = 0; x < dst_image->width; x++) {
        // Make homogeneous.
        dvec[0] = x;
        dvec[1] = y;
        dvec[2] = 1.;
  
        // Do the transform.
        transform_point(dvec, xform, svec);
  
        // Normalize, i.e., (u,v) = (u'/q,v'/q)
        svec[0] /= svec[2];
        svec[1] /= svec[2];
  
        linear_interpolate(src_image->pixels, src_image->stride,
            dst_image->width, dst_image->height, svec[0], svec[1], &pval);
  
        *(ptr + x) = pval;
      }
    }
    */
    
  }
  
  /*
   * Interpolate an color based on weighted area values.  Adapted from
   * Leptonica.
   */
  /*void linear_interpolate(pixel_t *pixels, size_t stride, size_t width, size_t height,
      double x, double y, pixel_t *pval) {
    int32_t xpm, ypm, xp, yp, xf, yf;
    int32_t rval, gval, bval;
    uint32_t word00, word01, word10, word11;
    pixel_t *lines;
    pixel_t colorval = FILL;
  
    *pval = colorval;
  
    // Skip if off the edge
    if (x < 0.0 || y < 0.0 || x > width - 2.0 || y > height - 2.0)
      return;
  
    xpm = (int32_t)(16.0 * x + 0.5);
    ypm = (int32_t)(16.0 * y + 0.5);
    xp = xpm >> 4;
    yp = ypm >> 4;
    xf = xpm & 0x0f;
    yf = ypm & 0x0f;
  
    lines = pixels + (yp * stride);
  
    word00 = *(lines + xp);
    word10 = *(lines + xp + 1);
    word01 = *(lines + stride + xp);
    word11 = *(lines + stride + xp + 1);
  
  #define L_RED_SHIFT  16
  #define L_GREEN_SHIFT 8
  #define L_BLUE_SHIFT  0
  
    rval = ((16 - xf) * (16 - yf) * ((word00 >> L_RED_SHIFT) & 0xff) +
        xf * (16 - yf) * ((word10 >> L_RED_SHIFT) & 0xff) +
        (16 - xf) * yf * ((word01 >> L_RED_SHIFT) & 0xff) +
        xf * yf * ((word11 >> L_RED_SHIFT) & 0xff) + 128) / 256;
  
    gval = ((16 - xf) * (16 - yf) * ((word00 >> L_GREEN_SHIFT) & 0xff) +
        xf * (16 - yf) * ((word10 >> L_GREEN_SHIFT) & 0xff) +
        (16 - xf) * yf * ((word01 >> L_GREEN_SHIFT) & 0xff) +
        xf * yf * ((word11 >> L_GREEN_SHIFT) & 0xff) + 128) / 256;
  
    bval = ((16 - xf) * (16 - yf) * ((word00 >> L_BLUE_SHIFT) & 0xff) +
        xf * (16 - yf) * ((word10 >> L_BLUE_SHIFT) & 0xff) +
        (16 - xf) * yf * ((word01 >> L_BLUE_SHIFT) & 0xff) +
        xf * yf * ((word11 >> L_BLUE_SHIFT) & 0xff) + 128) / 256;
  
    *pval = (rval << L_RED_SHIFT) | (gval << L_GREEN_SHIFT) | (bval << L_BLUE_SHIFT);
  }
  */
  
  /*
   * Compute a square to quad transform matrix for the four vertices
   * given.
   */
  void square_to_quad(double[][] p, double[][] sx) {
    double lx, ly;
  
    lx = p[0][0] - p[1][0] + p[2][0] - p[3][0];
    ly = p[0][1] - p[1][1] + p[2][1] - p[3][1];
  
    // If true, this is an affine mapping which is much quicker to
    // compute.
    if ((lx == 0) && (ly == 0)) {
      sx[0][0] = p[1][0] - p[0][0];
      sx[1][0] = p[2][0] - p[1][0];
      sx[2][0] = p[0][0];
      sx[0][1] = p[1][1] - p[0][1];
      sx[1][1] = p[2][1] - p[1][1];
      sx[2][1] = p[0][1];
      sx[0][2] = 0.;
      sx[1][2] = 0.;
      sx[2][2] = 1.;
      return;
    }
  
    double dx1, dx2, dy1, dy2, den;
  
    dx1 = p[1][0] - p[2][0];
    dx2 = p[3][0] - p[2][0];
    dy1 = p[1][1] - p[2][1];
    dy2 = p[3][1] - p[2][1];
    den = DET(dx1, dx2, dy1, dy2);
  
    double a, b, c, d, e, f, g, h;
  
    g = DET(lx,dx2,ly,dy2) / den;
    h = DET(dx1,lx,dy1,ly) / den;
  
    a = p[1][0] - p[0][0] + g * p[1][0];
    b = p[3][0] - p[0][0] + h * p[3][0];
    c = p[0][0];
  
    d = p[1][1] - p[0][1] + g * p[1][1];
    e = p[3][1] - p[0][1] + h * p[3][1];
    f = p[0][1];
  
    sx[0][0] = a; sx[0][1] = d; sx[0][2] = g;
    sx[1][0] = b; sx[1][1] = e; sx[1][2] = h;
    sx[2][0] = c; sx[2][1] = f; sx[2][2] = 1.;
  }
  
  /*
   * Using Heckbert's technique, find a quad to quad transform for the
   * vertices given.
   */
  void quad_to_quad(vertex_t[] v, double[][] xform) {
    double[][] md = new double[3][3], dm = new double[3][3], sm = new double[3][3];
    md[0] =  new double[3]; md[1] =  new double[3]; md[2] =  new double[3];
    dm[0] =  new double[3]; dm[1] =  new double[3]; dm[2] =  new double[3];
    sm[0] =  new double[3]; sm[1] =  new double[3]; sm[2] =  new double[3];
    
    double[][] s_pts = new double[4][2];
    s_pts[0] = new double[2]; s_pts[1] = new double[2]; s_pts[2] = new double[2]; s_pts[3] = new double[2];
    double[][] d_pts = new double[4][2];
    d_pts[0] = new double[2]; d_pts[1] = new double[2]; d_pts[2] = new double[2]; d_pts[3] = new double[2];
    int n;
  
    // Make the vertices easier to use.
    for (n = 0; n < 4; n++) { 
      s_pts[n][0] = v[n].u;
      s_pts[n][1] = v[n].v;
      d_pts[n][0] = v[n].x;
      d_pts[n][1] = v[n].y;
    }
  
    // Find square to quad transform for the dst points.
    square_to_quad(d_pts, dm);
  
    // Invert for a quad to square transform.
    if (find_adjoint(dm, md) == 0.)
      // TODO:  Handle this
  //    printf("Error: det == 0\n");
      ;
  
    // Find square to quad transform for the src points.
    square_to_quad(s_pts, sm);
  
    // Combined them for the quad to quad transform.
    mmult(md, sm, xform);
  }
  
  
  double DET(double a, double b, double c, double d) {
      return ((a)*(d)-(b)*(c));
  }
  
  /*
   * Finds a's adjoint matrix b.
   */
  double find_adjoint(double[][] a, double[][] b) {
    b[0][0] = DET(a[1][1], a[1][2], a[2][1], a[2][2]);
    b[1][0] = DET(a[1][2], a[1][0], a[2][2], a[2][0]);
    b[2][0] = DET(a[1][0], a[1][1], a[2][0], a[2][1]);
    b[0][1] = DET(a[2][1], a[2][2], a[0][1], a[0][2]);
    b[1][1] = DET(a[2][2], a[2][0], a[0][2], a[0][0]);
    b[2][1] = DET(a[2][0], a[2][1], a[0][0], a[0][1]);
    b[0][2] = DET(a[0][1], a[0][2], a[1][1], a[1][2]);
    b[1][2] = DET(a[0][2], a[0][0], a[1][2], a[1][0]);
    b[2][2] = DET(a[0][0], a[0][1], a[1][0], a[1][1]);
    return a[0][0]*b[0][0] + a[0][1]*b[0][1] + a[0][2]*b[0][2];
  }
  
  /*
   * Multiple two matrices.  (a * b = c)
   */
  void mmult(double[][] a, double[][] b, double[][] c) {
    c[0][0] = a[0][0]*b[0][0] + a[0][1]*b[1][0] + a[0][2]*b[2][0];
    c[0][1] = a[0][0]*b[0][1] + a[0][1]*b[1][1] + a[0][2]*b[2][1];
    c[0][2] = a[0][0]*b[0][2] + a[0][1]*b[1][2] + a[0][2]*b[2][2];
    c[1][0] = a[1][0]*b[0][0] + a[1][1]*b[1][0] + a[1][2]*b[2][0];
    c[1][1] = a[1][0]*b[0][1] + a[1][1]*b[1][1] + a[1][2]*b[2][1];
    c[1][2] = a[1][0]*b[0][2] + a[1][1]*b[1][2] + a[1][2]*b[2][2];
    c[2][0] = a[2][0]*b[0][0] + a[2][1]*b[1][0] + a[2][2]*b[2][0];
    c[2][1] = a[2][0]*b[0][1] + a[2][1]*b[1][1] + a[2][2]*b[2][1];
    c[2][2] = a[2][0]*b[0][2] + a[2][1]*b[1][2] + a[2][2]*b[2][2];
  }
  
  /*
   * Do the actual point transform.  Homogeneous coords.
   */
  void transform_point(double[] dv, double[][] h, double[] sv) {
    sv[0] = dv[0]*h[0][0] + dv[1]*h[1][0] + dv[2]*h[2][0];
    sv[1] = dv[0]*h[0][1] + dv[1]*h[1][1] + dv[2]*h[2][1];
    sv[2] = dv[0]*h[0][2] + dv[1]*h[1][2] + dv[2]*h[2][2];
  }
  
  vec2f getSourcePoint(vec2i dv) {
    vec2f sv = new vec2f();
    
    double a = dv.x*xform[0][0] + dv.y*xform[1][0] + xform[2][0];
    double b = dv.x*xform[0][1] + dv.y*xform[1][1] + xform[2][1];
    double c = dv.x*xform[0][2] + dv.y*xform[1][2] + xform[2][2];
    
    return new vec2f((float)(a/c), (float)(b/c));
  }


}