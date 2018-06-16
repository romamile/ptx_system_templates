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
 
import processing.video.*;

 /**
* This class aims at easing the process of capturing image
* from the camera in processing, both in its setup and
* in its usage.
* On top of that, the class hosts all usefull version
* of captured image (whole, croped, filtered and final result)
*
* @author  Roman Miletitch
* @version 0.7
*
**/

public class cam {
  Capture cpt;
  String camStr;
 
  boolean hasImage, isFiltered, isRecognised;
  
  PImage mImg;          // Whole image
  PImage mImgCroped;    // Image with trapeze done
  PImage mImgFilter;
  PImage mImgRez;
  
  int wFbo, hFbo;

  //Selection of ROI in mImg for mImgCroped
  //0 1
  //3 2
  vec2f[] ROI;
  int dotIndex; // 0->3 & -1 == no editing
  float zoomCamera;
  
  cam(int _w, int _h) {
    
    wFbo = _w;
    hFbo = _h;
    
    ROI = new vec2f[4];
    mImg = createImage(wFbo, hFbo, RGB);// HAARRRR

    mImgCroped = createImage(wFbo, hFbo, RGB);
    mImgFilter = createImage(wFbo, hFbo, RGB);
    mImgRez    = createImage(wFbo, hFbo, RGB);

    zoomCamera = 1;
    dotIndex = -1;
    ROI[0] = new vec2f(200, 200);
    ROI[1] = new vec2f(400, 200);
    ROI[2] = new vec2f(400, 400);
    ROI[3] = new vec2f(200, 400);
  
 
    String[] cameras = Capture.list();
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        println(i + ", " + cameras[i]);
      }  
    }

  }
  
  
  /** 
  * Functions that let the user select which camera to use and which
  * mode of camera to use for the image recognision stream. It then
  * launch it.
  * @param _idCam          the identifiant of the selected camera
  * @param _myGrandParent  a reference to the current PApplet, necessary
                           for instancing the Capture class
  */
  void startFromId(int _idCam, PApplet _myGrandParent) {
    
   // 1) Select the camera 
   String[] cameras = Capture.list();
   println();
    
    if(_idCam < cameras.length) {
      println("FOUND GOOD CAM");
      camStr = cameras[_idCam];
    } else {
      println("DEFAULT CAM");
      camStr = cameras[0];
    }
    
    println(_idCam + " / Camera: " + camStr);
    
    
    // 2) Create the capture object
    cpt = new Capture(_myGrandParent, camStr);
    
    // 3) Launch
    cpt.start();
    update();
    
  }

 /** 
  * Get another image from the camera stream if possible
  * @return          <code>true</code> if the camera is availabe. 
  */
  boolean update() {
    if(cpt.available()) {
      cpt.read();
      
      mImg = cpt;
      mImgCroped = createImage(wFbo, hFbo, RGB);
      return true;
    }
    return false;
  }

 /** 
  * Copy the main image into filter Image and rez Image objects for displaying
  * and/or futur processing.
  */
  void updateImg() {
    mImgFilter.copy(mImgCroped, 0, 0, wFbo, hFbo, 0, 0, wFbo, hFbo);
    mImgRez.copy(mImgCroped, 0, 0, wFbo, hFbo, 0, 0, wFbo, hFbo);
  }
  
 /** 
  * Function that test if the camera is availabe
  * @return          <code>true</code> if the camera is availabe. 
  */
  boolean isOn() {
   return cpt.available(); 
  }
}