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

import java.lang.System.*;
import java.awt.event.KeyEvent;

import deadpixel.keystone.*;

public enum globState { MIRE, CAMERA, RECOG };
public enum recogState { RECOG_GRAY, RECOG_ROI, RECOG_BACK, RECOG_COL, RECOG_AREA, RECOG_CONTOUR, RECOG_ORIENTED };
public enum cameraState { CAMERA_WHOLE, CAMERA_ZOOM }; 

/**
 * This class is the main one in the PTX library. It helps you
 * setting up the whole system, diagnosing what goes wrong,
 * and display helpful calibrating GUI. It's also the class that
 * returns the list of all color area recognised.
 *
 * @author  Roman Miletitch
 * @version 0.7
 *
 **/


public class ptx_inter {


  // The states
  globState myGlobState;  
  recogState myRecogState;
  cameraState myCamState;

  // debug
  PFont fDef;
  int debugType; // 0 - 1 - 2 - 3
  
  toggle togUI;
  String strUI;

  cam myCam;
  ptx myPtx;


  // Scan
  int grayLevelUp, grayLevelDown;
  int whiteCtp;
  int idCam;


  // Frame Buffer Object
  int wFrameFbo, hFrameFbo;
  PGraphics mFbo;
  
  
  Keystone ks;
  CornerPinSurface surface;
  
  vec2f[] ROIproj;
  int dotIndex;


  ptx_inter(PApplet _myParent) {

    myGlobState = globState.MIRE;
    myRecogState = recogState.RECOG_GRAY;
    myCamState =  cameraState.CAMERA_WHOLE;

    fDef = createFont(PFont.list()[0], 32);
    debugType = 1;
    togUI = new toggle();
    togUI.setSpanS(1);
    strUI = "";
    
    hFrameFbo = 757;
    float ratioFbo = (width*1.0)/height; // = 37.f / 50;
    wFrameFbo = int(hFrameFbo * ratioFbo);

    myPtx = new ptx();
    //myPtx = new ptx(); myPtx.opencv = new OpenCV(_myParent, loadImage("./cards.png"));
    myCam = new cam();

    grayLevelUp   = 126;
    grayLevelDown = 126;

    // SCAN
    whiteCtp = 0;

    ks = new Keystone(_myParent);
    surface = ks.createCornerPinSurface(wFrameFbo, hFrameFbo, 20);
    
    // Load configuration file
    File f = new File(dataPath("config.json"));
    if (!f.exists()) saveConfig();
    else             loadConfig();

    mFbo = createGraphics(wFrameFbo, hFrameFbo, P3D);
    myCam.resize(wFrameFbo, hFrameFbo);
    
    myCam.startFromId(idCam, _myParent);
    myPtx.opencv = new OpenCV(_myParent, createImage(myCam.wCam, myCam.hCam, ARGB));
    myPtx.calculateHomographyMatrice(wFrameFbo, hFrameFbo, myCam.ROI);

    // First scan (check if not over kill, already one update in file)
    //    myCam.update(); myCam.update(); myCam.update(); myCam.update(); myCam.update();
    scanCam();
    scanClr();
  }


  /** 
   * Helper functions to access all the scanned areas.
   * @return              <code>ArrayList<area></code> corresponding to the list of all Areas
   */
  ArrayList<area> getListArea() {
    return myPtx.listArea;
  }

  area getAreaById(int _id) {
    for (area tmpArea : myPtx.listArea)
      if (tmpArea.id == _id)
        return tmpArea;
    return new area();
  }


  /** 
   * Get another image from the camera, apply geometric correction
   * and update the subsecant images (while not parsing the picture)
   * A full scan would be scanCam + scanClr
   */
  void scanCam() {

    myCam.mImgCroped = createImage(wFrameFbo, hFrameFbo, RGB);

    myPtx.trapeze(myCam.mImg, myCam.mImgCroped, 
      myCam.mImg.width, myCam.mImg.height, 
      myCam.mImgCroped.width, myCam.mImgCroped.height, myCam.ROI);

    myCam.updateImg();

    // TEMP DEBUG
    //myCam.mImgCroped.save("./data/drawings/img_"+millis()+".png");
  }

  /** 
   * Update the subsecant images of the camera and parse the
   * image (while not asking for a new camera picture before that)
   * A full scan would be scanCam + scanClr
   */
  void scanClr() {

    myCam.updateImg();
    myPtx.parseImage(myCam.mImgCroped, myCam.mImgFilter, myCam.mImgRez, wFrameFbo, hFrameFbo);
//    atScan();
  }

  /** 
   * Display the Frame Buffer Object where everything is drawn,
   * following the determined keystone. 
   */
  void displayFBO() {
/*
    pushMatrix();
    translate(myPtx.transX_projo - mFbo.width/2, myPtx.transY_projo - mFbo.height/2, myPtx.transZ_projo);
    rotateX(myPtx.rotX_projo);
    rotateY(myPtx.rotY_projo);
    rotateZ(myPtx.rotZ_projo);
    image(mFbo, 0, 0);   
    popMatrix();
*/
    surface.render(mFbo);
  }
  
  /** 
   * Main rendering function, that dispatch to the other renderers.
   * Scan, Mire, Camera, Recogintion.
   */
  void generalRender() {

    mFbo.beginDraw();
    mFbo.textFont(fDef);
    mFbo.textSize(32);
    mFbo.fill(255);
    mFbo.textAlign(LEFT);

    myPtxInter.mFbo.imageMode(CORNER);
    myPtxInter.mFbo.rectMode(CORNER);

    mFbo.background(30);

    if (isScanning) {
      renderScan();
    } else {
      switch (myGlobState) {
      case MIRE:
        renderMire();
        if (debugType != 0) mFbo.text("F2; MIRE", 10, 100); 
        break;
      case CAMERA:
        renderCamera(); 
        if (debugType != 0) {
          text("F3; CAMERA", 10, 100);
        }
        break;
      case RECOG:
        renderRecog();
        if (debugType != 0) mFbo.text("F4; RECOG", 10, 100); 
        break;
      }
    }

    if ((debugType == 2 || debugType == 3) && !isScanning)
      displayDebugIntel();
      
      
    if(togUI.getState()) {
        // UI high level
        mFbo.fill(255, 255, 255);     
        mFbo.textAlign(CENTER);
        mFbo.text(strUI, myPtxInter.mFbo.width/2, myPtxInter.mFbo.height/2 - 100);
    } else {
        togUI.stop(false); 
    }

    mFbo.endDraw();

    if (! (myPtxInter.myGlobState == globState.CAMERA && myPtxInter.myCamState == cameraState.CAMERA_WHOLE) ) {
        displayFBO();
    }

  }

  /** 
   * Sub renderer function, to display the Mire
   */
  void renderMire() {  // F2

    mFbo.stroke(250);
    mFbo.strokeWeight(2);
    mFbo.beginShape(LINES);
    for (int i = 0; i < 7; i++) { //Mire
      mFbo.vertex(wFrameFbo / 6.f*i, 0); //Lignes verticales
      mFbo.vertex(wFrameFbo / 6.f*i, hFrameFbo);

      mFbo.vertex(0, hFrameFbo / 6.f*i); //Lignes horizontales
      mFbo.vertex(wFrameFbo, hFrameFbo / 6.f*i);
    }

    //Bords
    mFbo.vertex(0, hFrameFbo -3); 
    mFbo.vertex(wFrameFbo, hFrameFbo -3);

    mFbo.vertex(0, 2);
    mFbo.vertex(wFrameFbo, 2);

    mFbo.vertex(2, 0);
    mFbo.vertex(2, hFrameFbo);

    mFbo.vertex(wFrameFbo - 2, 0);
    mFbo.vertex(wFrameFbo - 2, hFrameFbo);

    mFbo.endShape();


    mFbo.stroke(255, 255*0.3, 255*0.3);
    mFbo.beginShape(LINES);
    mFbo.vertex(wFrameFbo/2.f, hFrameFbo*0.4); //Lignes verticales
    mFbo.vertex(wFrameFbo/2.f, hFrameFbo*0.6);

    mFbo.vertex(wFrameFbo*0.4, hFrameFbo/2.f); //Lignes horizontales
    mFbo.vertex(wFrameFbo*0.6, hFrameFbo/2.f);

    mFbo.endShape();

    mFbo.stroke(255);
  }


  /** 
   * Sub renderer function, to display the Camera
   * First mode allows for the whole camera to be displayed, and
   * selection of the 4 corneres of the ROI.
   * Second allows for just the ROI to be displayed and geometric
   * correction to be tested/applied.
   */
  void renderCamera() { // F3

    switch (myCamState) {
    case CAMERA_WHOLE: // Show the whole view of the camera
      /*
      mFbo.pushMatrix();
       
       //      mFbo.translate(wFrameFbo / 2 - ratio * myCam.mImg.width  / 2,
       //                     hFrameFbo / 2 - ratio * myCam.mImg.height / 2);
       
       mFbo.translate(0, hFrameFbo / 2 - ratio * myCam.mImg.height / 2);
       
       mFbo.scale(ratio, ratio);
       
       //    mFbo.fill(200); 
       //    mFbo.stroke(255, 0, 0);
       //    mFbo.rect(0, 0, myCam.mImg.width-10, myCam.mImg.height);
       mFbo.image(myCam.mImg, 0,0);
       
       
       mFbo.strokeWeight(2);
       mFbo.stroke(255,0,0);
       mFbo.noFill();
       mFbo.beginShape();
       mFbo.vertex(myCam.ROI[0].x, myCam.ROI[0].y);
       mFbo.vertex(myCam.ROI[1].x, myCam.ROI[1].y);
       mFbo.vertex(myCam.ROI[2].x, myCam.ROI[2].y);
       mFbo.vertex(myCam.ROI[3].x, myCam.ROI[3].y);
       mFbo.endShape(CLOSE);
       
       mFbo.popMatrix();
       
       mFbo.fill(255);
       if (debugType != 0) mFbo.text("F3 - 1/2; ZOOM", 10, 30);
       */


      // IN THE MEAN WHILE...
      image(myCam.mImg, 0, 0);
      strokeWeight(2);
      stroke(255, 130);
      noFill();
      beginShape();
      vertex(myCam.ROI[0].x, myCam.ROI[0].y);
      vertex(myCam.ROI[1].x, myCam.ROI[1].y);
      vertex(myCam.ROI[2].x, myCam.ROI[2].y);
      vertex(myCam.ROI[3].x, myCam.ROI[3].y);
      endShape(CLOSE);
      
      
      if(myCam.dotIndex != -1) {
        stroke(255, 200);
        ellipse(myCam.ROI[myCam.dotIndex].x, myCam.ROI[myCam.dotIndex].y, 20, 20);
        ellipse(myCam.ROI[myCam.dotIndex].x, myCam.ROI[myCam.dotIndex].y, 40, 40);
        stroke(255, 50);
        line(myCam.ROI[myCam.dotIndex].x - 20, myCam.ROI[myCam.dotIndex].y, myCam.ROI[myCam.dotIndex].x + 20, myCam.ROI[myCam.dotIndex].y);
        line(myCam.ROI[myCam.dotIndex].x, myCam.ROI[myCam.dotIndex].y - 20, myCam.ROI[myCam.dotIndex].x, myCam.ROI[myCam.dotIndex].y + 20);
      }

      fill(255);

      if (debugType != 0) mFbo.text("F3 - 1/2; ZOOM", 10, 30);

      break;

    case CAMERA_ZOOM:  // Show the region of interest

      mFbo.image(myCam.mImgCroped, 0, 0);

      mFbo.stroke(0);
      mFbo.strokeWeight(1);
      mFbo.beginShape(LINES);
      for (int i = 0; i < 7; i++) { //Mire
        mFbo.vertex(wFrameFbo / 6.f*i, 0); //Lignes verticales
        mFbo.vertex(wFrameFbo / 6.f*i, hFrameFbo);

        mFbo.vertex(0, hFrameFbo / 6.f*i); //Lignes horizontales
        mFbo.vertex(wFrameFbo, hFrameFbo / 6.f*i);
      }

      //Bords
      mFbo.vertex(0, hFrameFbo -3); 
      mFbo.vertex(wFrameFbo, hFrameFbo -3);

      mFbo.vertex(0, 2);
      mFbo.vertex(wFrameFbo, 2);

      mFbo.vertex(2, 0);
      mFbo.vertex(2, hFrameFbo);

      mFbo.vertex(wFrameFbo - 2, 0);
      mFbo.vertex(wFrameFbo - 2, hFrameFbo);

      mFbo.endShape();


      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F3 - 1/2; ROI", 10, 30);



      break;
    }
  }

  /** 
   * Sub renderer function, to display the Recognition mode.
   * This mode has a few substate, all to diagnose if the color 
   * recognition is working fine, and to fine tune it if it's not.
   */
  void renderRecog() {  // F4
    background(0);

    switch (myRecogState) {
    case RECOG_GRAY:

      mFbo.noStroke();
      mFbo.beginShape(TRIANGLE_FAN);
      mFbo.fill(grayLevelUp);
      mFbo.vertex(mFbo.width, 0);
      mFbo.vertex(0, 0);  
      mFbo.fill(grayLevelDown);
      mFbo.vertex(0, mFbo.height);
      mFbo.vertex(mFbo.width, mFbo.height);
      mFbo.endShape();
        
      mFbo.fill(255);      
      if (debugType != 0) mFbo.text("F4 - 1/7; GRAY", 10, 30);
      break;

    case RECOG_ROI:
      mFbo.image(myCam.mImgCroped, 0, 0);
      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F4 - 2/7; ROI", 10, 30);
      break;

    case RECOG_BACK:
      mFbo.image(myCam.mImgFilter, 0, 0);
      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F4 - 3/7; BACK", 10, 30);
      break;

    case RECOG_COL:
      mFbo.image(myCam.mImgRez, 0, 0);


      //Color Wheel
      mFbo.colorMode(HSB, 360);
      mFbo.noStroke();
      mFbo.pushMatrix();
      mFbo.translate(wFrameFbo/2, hFrameFbo/2);
      mFbo.beginShape(QUADS);
      for (int i = 0; i < 360; i++) {
        mFbo.fill(i, 360, 360);
        mFbo.vertex(100 * cos(2 * PI*float(i)     / 360), 100 * sin(2 * PI*float(i)     / 360));
        mFbo.vertex(100 * cos(2 * PI*float(i + 1) / 360), 100 * sin(2 * PI*float(i + 1) / 360));
        mFbo.vertex(120 * cos(2 * PI*float(i + 1) / 360), 120 * sin(2 * PI*float(i + 1) / 360));
        mFbo.vertex(120 * cos(2 * PI*float(i)     / 360), 120 * sin(2 * PI*float(i)     / 360));
      }
      mFbo.endShape();

      //Histogram
      mFbo.beginShape(QUADS);
      for (int i = 0; i < 360; i++) {
        mFbo.fill(i, 360, 360);
        int val = 140 + myPtx.histHue[i];

        mFbo.vertex(140 * cos(2 * PI*float(i)     / 360), 140 * sin(2 * PI*float(i)     / 360));
        mFbo.vertex(140 * cos(2 * PI*float(i + 1) / 360), 140 * sin(2 * PI*float(i + 1) / 360));
        mFbo.vertex(val * cos(2 * PI*float(i + 1) / 360), val * sin(2 * PI*float(i + 1) / 360));
        mFbo.vertex(val * cos(2 * PI*float(i)     / 360), val * sin(2 * PI*float(i)     / 360));
      }
      mFbo.endShape();

      // HueZones
      for (hueInterval myZone : myPtx.listZone) {
        mFbo.beginShape(QUADS);
        mFbo.fill(myZone.getRef(), 360, 360);

        for (int hue : myZone.getRange()) {
          mFbo.vertex(123 * cos(2 * PI*float(hue)     / 360), 123 * sin(2 * PI*float(hue)     / 360));
          mFbo.vertex(123 * cos(2 * PI*float(hue + 1) / 360), 123 * sin(2 * PI*float(hue + 1) / 360));
          mFbo.vertex(137 * cos(2 * PI*float(hue + 1) / 360), 137 * sin(2 * PI*float(hue + 1) / 360));
          mFbo.vertex(137 * cos(2 * PI*float(hue)     / 360), 137 * sin(2 * PI*float(hue)     / 360));
        }
        mFbo.endShape();
      }

      // Cursor
      int indexCol = 0;
      if (myPtx.indexHue%2 == 1)
        indexCol = myPtx.listZone.get(myPtx.indexHue/2).b;
      else
        indexCol = myPtx.listZone.get(myPtx.indexHue/2).a;

      mFbo.beginShape(TRIANGLES);
      mFbo.fill(255);
        mFbo.vertex(153 * cos(2 * PI*float(indexCol-3) / 360), 153 * sin(2 * PI*float(indexCol-3) / 360));
        mFbo.vertex(138 * cos(2 * PI*float(indexCol)   / 360), 138 * sin(2 * PI*float(indexCol)   / 360));
        mFbo.vertex(153 * cos(2 * PI*float(indexCol+3) / 360), 153 * sin(2 * PI*float(indexCol+3) / 360));
      mFbo.endShape();

      mFbo.popMatrix();   
      mFbo.colorMode(RGB, 255);

      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F4 - 4/7; COL", 10, 30);
      break;

    case RECOG_AREA:

      mFbo.colorMode(HSB, 360);

      for (area itArea : myPtx.listArea) {
        mFbo.noStroke();
        mFbo.fill(itArea.hue, 360, 360);

        mFbo.beginShape();

        // 1) Exterior part of shape, clockwise winding
        for (vec2i itPos : itArea.listContour.get(0))
          mFbo.vertex(itPos.x, itPos.y);

        // 2) Interior part of shape, counter-clockwise winding
        for (int i = 1; i < itArea.listContour.size();++i) {
          mFbo.beginContour();
          for (vec2i itPos : itArea.listContour.get(i))
            mFbo.vertex(itPos.x, itPos.y);
          mFbo.endContour();
        }
        mFbo.endShape(CLOSE);
      }

      mFbo.colorMode(RGB, 255);
      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F4 - 5/7; AREA", 10, 30);
      break;

    case RECOG_CONTOUR:

      mFbo.stroke(50, 0, 0);
      mFbo.beginShape(POINTS);
      for (area itArea : myPtx.listArea)
        for (vec2i itPos : itArea.posXY)
          mFbo.vertex(itPos.x, itPos.y);
      mFbo.endShape();

      mFbo.stroke(255, 0, 0 );
      mFbo.beginShape(POINTS);
      for (area itArea : myPtx.listArea)
        for (ArrayList<vec2i> itContour : itArea.listContour)
          for (vec2i itPos : itContour)
            mFbo.vertex(itPos.x, itPos.y);
      mFbo.endShape();

      for (area itArea : myPtx.listArea) {
        String perSur = "";

        switch(itArea.myShape) {
        case DOT:  
          perSur = "dot";  
          break;
        case LINE: 
          perSur = "line";  
          break;
        case FILL: 
          perSur = "fill";  
          break;
        case GAP:  
          perSur = "gap";  
          break;
        }

        mFbo.text(perSur, itArea.posXY.get(0).x, itArea.posXY.get(0).y);
      }

      mFbo.fill(255);
      if (debugType != 0) mFbo.text("F4 - 6/7; CONTOUR", 10, 30);
      break;

    case RECOG_ORIENTED:

      mFbo.stroke(50, 0, 0);
      mFbo.beginShape(POINTS);
      for (area itArea : myPtx.listArea)
        for (vec2i itPos : itArea.posXY)
          mFbo.vertex(itPos.x, itPos.y);
      mFbo.endShape();

      int i = 0;
      mFbo.beginShape(POINTS);
      for (area itArea : myPtx.listArea)
        for (ArrayList<vec2i> itContour : itArea.listContour) {
          i++;
          mFbo.stroke(i*50%250, (80+i*i*80)%250, (160+i*i*150)%250);
          for (vec2i itPos : itContour)
            mFbo.vertex(itPos.x, itPos.y);
        }  
      mFbo.endShape();

      mFbo.fill(255);
      mFbo.stroke(255);
      if (debugType != 0) mFbo.text("F4 - 7/7; ORIENTED", 10, 30);
      break;
    }
  }

  /** 
   * Sub renderer function, to display the Scanning white screen
   * when in the process of flashing the drawing
   */
  void renderScan() { // SCAN

    whiteCtp++;

    if (myGlobState == globState.CAMERA) {

      mFbo.background(0.3f, 0.3f, 0.3f);

      mFbo.stroke(255);
      mFbo.strokeWeight(2);
      mFbo.beginShape(LINES);
      for (int i = 0; i < 7; i++) { //Mire
        mFbo.vertex(wFrameFbo / 6.f*i, 0); //Lignes verticales
        mFbo.vertex(wFrameFbo / 6.f*i, hFrameFbo);

        mFbo.vertex(0, hFrameFbo / 6.f*i); //Lignes horizontales
        mFbo.vertex(wFrameFbo, hFrameFbo / 6.f*i);
      }

      //Bords
      mFbo.vertex(0, hFrameFbo-1); 
      mFbo.vertex(wFrameFbo-1, hFrameFbo-1);

      mFbo.vertex(0, 0);
      mFbo.vertex(wFrameFbo-1, 0);

      mFbo.vertex(0, 0);
      mFbo.vertex(0, hFrameFbo-1);

      mFbo.vertex(wFrameFbo-1, 0);
      mFbo.vertex(wFrameFbo-1, hFrameFbo-1);

      mFbo.endShape();
    } else {
      mFbo.noStroke();
      mFbo.beginShape(TRIANGLE_FAN);
      mFbo.fill(grayLevelUp);
      mFbo.vertex(mFbo.width, 0);
      mFbo.vertex(0, 0);  
      mFbo.fill(grayLevelDown);
      mFbo.vertex(0, mFbo.height);
      mFbo.vertex(mFbo.width, mFbo.height);
      mFbo.endShape();
    }
  }

  /** 
   * Helper function to display some of the most often needed
   * parametrs value for the Recognise mode.
   */
  void displayDebugIntel() {

    //Values
    String debugStr = "Gray Top: "  + grayLevelUp + "\n"
      + "GrayDown: "  + grayLevelDown + "\n"
      + "Ratio: "     + int(100*myPtx.ratioCam)/100.0 + "\n"
      + "Luminance: " + myPtx.seuilValue + "\n"
      + "Saturation: " + int(100*myPtx.seuilSaturation)/100.0 + "\n"
//      + "Flash: T " + myPtx.flashUp
//      + " - R " + myPtx.flashRight 
//      + " - B " + myPtx.flashDown
//      + " - L " + myPtx.flashLeft
      + "CamExp: " + myCam.getExposure() + "\n"
      + "CamSat: " + myCam.getSaturation()  + "\n";

    if (debugType == 2) {
      mFbo.textAlign(LEFT);
      mFbo.text(debugStr, 50, 200);
    } 

    if (debugType == 3) {
      mFbo.textAlign(RIGHT);
      mFbo.text(debugStr, wFrameFbo - 50, 200);
    } 

    mFbo.textAlign(LEFT);
  }

  /** 
   * Save all parametrs in a predifined file (data/config.json)
   */
  void saveConfig() {
    println("Config Saved!");
    
    //Save key stone
    ks.save("./data/configKeyStone.xml");
    
    JSONObject json = new JSONObject();

    json.setFloat("seuilSaturation", myPtx.seuilSaturation);
    json.setFloat("seuilValue", myPtx.seuilValue);
    json.setInt("grayLevelUp", grayLevelUp);
    json.setInt("grayLevelDown", grayLevelDown);

    json.setFloat("a0", myPtx.a0);
    json.setFloat("a1", myPtx.a1);

    json.setFloat("ratioCam", myPtx.ratioCam);

    json.setInt("redMin", myPtx.listZone.get(0).getMin());
    json.setInt("redMax", myPtx.listZone.get(0).getMax());
    json.setInt("greenMin", myPtx.listZone.get(1).getMin());
    json.setInt("greenMax", myPtx.listZone.get(1).getMax());
    json.setInt("blueMin", myPtx.listZone.get(2).getMin());
    json.setInt("blueMax", myPtx.listZone.get(2).getMax());
    json.setInt("yellowMin", myPtx.listZone.get(3).getMin());
    json.setInt("yellowMax", myPtx.listZone.get(3).getMax());

    json.setFloat("flashLeft", myPtx.flashLeft);
    json.setFloat("flashRight", myPtx.flashRight);
    json.setFloat("flashUp", myPtx.flashUp);
    json.setFloat("flashDown", myPtx.flashDown);

    /*
    json.set("wCam", myCam.wCam);
     json.set("hCam", myCam.hCam);
     */
    json.setFloat("UpperLeftX", myCam.ROI[0].x);
    json.setFloat("UpperLeftY", myCam.ROI[0].y);
    json.setFloat("UpperRightX", myCam.ROI[1].x);
    json.setFloat("UpperRightY", myCam.ROI[1].y);
    json.setFloat("LowerRightX", myCam.ROI[2].x);
    json.setFloat("LowerRightY", myCam.ROI[2].y);
    json.setFloat("LowerLeftX", myCam.ROI[3].x);
    json.setFloat("LowerLeftY", myCam.ROI[3].y);

    json.setInt("tooSmallThreshold", myPtx.tooSmallThreshold);
    json.setInt("tooSmallContourThreshold", myPtx.tooSmallContourThreshold);

    //TEMP, quand supprimer, ne pas oublier de retirer la virgule juste au dessus
    json.setFloat("seuil_ratioSurfacePerimetre", myPtx.seuil_ratioSurfacePerimetre);
    json.setFloat("seuil_tailleSurface", myPtx.seuil_tailleSurface);
    json.setInt("seuil_smallArea", myPtx.seuil_smallArea);

    json.setInt("idCam", idCam);

    saveJSONObject(json, "data/config.json");
  }


  /** 
   * Load all parametrs from a predifined file (data/config.json)
   */
  void loadConfig() {

    //load keystone
    ks.load("./data/configKeyStone.xml");
    
    JSONObject json = loadJSONObject("data/config.json");

    myPtx.seuilSaturation = json.getFloat("seuilSaturation");
    myPtx.seuilValue      = json.getFloat("seuilValue");
    grayLevelUp   = json.getInt("grayLevelUp");
    grayLevelDown = json.getInt("grayLevelDown");

    myPtx.a0 = json.getFloat("a0");
    myPtx.a1 = json.getFloat("a1");

    myPtx.ratioCam = json.getFloat("ratioCam");


    int redMin, redMax, greenMin, greenMax, blueMin, blueMax, yellowMin, yellowMax, backMin, backMax;
    redMin    = json.getInt("redMin");
    redMax    = json.getInt("redMax");
    greenMin  = json.getInt("greenMin");
    greenMax  = json.getInt("greenMax");
    blueMin   = json.getInt("blueMin");
    blueMax   = json.getInt("blueMax");
    yellowMin = json.getInt("yellowMin");
    yellowMax = json.getInt("yellowMax");

    //    backMin = json.getInt("backMin");
    //    backMax = json.getInt("backMax");

    myPtx.listZone.clear();
    myPtx.listZone.add( new hueInterval(redMin, redMax) );
    myPtx.listZone.add( new hueInterval(greenMin, greenMax) );
    myPtx.listZone.add( new hueInterval(blueMin, blueMax) );
    myPtx.listZone.add( new hueInterval(yellowMin, yellowMax) );

    //    myPtx.backHue = new hueInterval(backMin, backMax);
    //    if(backMin != backMax)
    //      myPtx.hasBackHue = true;


    myPtx.flashLeft  = json.getFloat("flashLeft");
    myPtx.flashRight = json.getFloat("flashRight");
    myPtx.flashUp    = json.getFloat("flashUp");
    myPtx.flashDown  = json.getFloat("flashDown");

    /*
    json.get("wCam", myCam.wCam);
     json.get("hCam", myCam.hCam);
     */

    myCam.ROI[0].x = json.getFloat("UpperLeftX");
    myCam.ROI[0].y = json.getFloat("UpperLeftY");
    myCam.ROI[1].x = json.getFloat("UpperRightX");
    myCam.ROI[1].y = json.getFloat("UpperRightY");
    myCam.ROI[2].x = json.getFloat("LowerRightX");
    myCam.ROI[2].y = json.getFloat("LowerRightY");
    myCam.ROI[3].x = json.getFloat("LowerLeftX");
    myCam.ROI[3].y = json.getFloat("LowerLeftY");


    //  json.getFloat("volumeMusic");
    //  json.getFloat("volumeSound");

    myPtx.tooSmallThreshold = json.getInt("tooSmallThreshold");
    myPtx.tooSmallContourThreshold = json.getInt("tooSmallContourThreshold");


    //TEMP, quand supprimer, ne pas oublier de retirer la virgule juste au dessus
    myPtx.seuil_ratioSurfacePerimetre = json.getFloat("seuil_ratioSurfacePerimetre");
    myPtx.seuil_tailleSurface = json.getFloat("seuil_tailleSurface");
    myPtx.seuil_smallArea = json.getInt("seuil_smallArea");


    idCam = loadJSONObject("data/config.json").getInt("idCam");
  }


  void managementKeyPressed() {
     // MANAGEMENT KEYS (FK_F** - 5), the -5 is here because of a weird behavior of P3D for keymanagement
    switch(keyCode) {
    case (KeyEvent.VK_F1-15):
      isInConfig = false;
      myPtx.verboseImg = false;
      ks.stopCalibration();
      myCam.dotIndex = -1;
      noCursor();
      break;
    case (KeyEvent.VK_F2-15):
      ks.toggleCalibration();
      isInConfig = true;
      myPtx.verboseImg = true;
      myCam.dotIndex = -1;
      if(ks.isCalibrating())
        cursor();
      else
        noCursor();
      myGlobState = globState.MIRE;
      break;
    case (KeyEvent.VK_F3-15):
      ks.stopCalibration();
      isInConfig = true;
      myPtx.verboseImg = true;
      cursor();
      if (myGlobState == globState.CAMERA) {
        switch (myCamState) {
        case CAMERA_WHOLE:  
          noCursor();
          myCamState = cameraState.CAMERA_ZOOM;  
          break;
        case CAMERA_ZOOM:
          myCamState = cameraState.CAMERA_WHOLE;  
          break;
        }
      }
      myGlobState = globState.CAMERA;
      break;
    case (KeyEvent.VK_F4-15):
      noCursor();
      myCam.dotIndex = -1;
      ks.stopCalibration();
      isInConfig = true;
      myPtx.verboseImg = true;
      if ( myGlobState == globState.RECOG) {
        switch(  myRecogState ) {
        case RECOG_GRAY:     myRecogState = recogState.RECOG_ROI;       break;
        case RECOG_ROI:      myRecogState = recogState.RECOG_BACK;      break;
        case RECOG_BACK:     myRecogState = recogState.RECOG_COL;       break;
        case RECOG_COL:      myRecogState = recogState.RECOG_AREA;      break;
        case RECOG_AREA:     myRecogState = recogState.RECOG_CONTOUR;   break;
        case RECOG_CONTOUR:  myRecogState = recogState.RECOG_ORIENTED;  break;
        case RECOG_ORIENTED: myRecogState = recogState.RECOG_GRAY;      break;
        }
      }
      myGlobState = globState.RECOG;
      break;
    
    case (KeyEvent.VK_F6-15):
      myCam.mImgCroped = loadImage("./data/testDrawing.png");  
      myCam.mImgFilter.copy(myPtxInter.myCam.mImgCroped, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo);
      myCam.mImgRez.copy(myPtxInter.myCam.mImgCroped, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo);
      myCam.mImgCroped = createImage(myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo, RGB);
      myCam.mImgCroped.copy(myPtxInter.myCam.mImgFilter, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo, 0, 0, myPtxInter.myCam.wFbo, myPtxInter.myCam.hFbo);
  
      scanClr();
      atScan();
      break;

    case (KeyEvent.VK_F7-15):
      debugType = (debugType + 1) % 4; 
      break;

    case (KeyEvent.VK_F8-15):
      myCam.update();    
      myCam.updateImg(); 
      break;
      
    case (KeyEvent.VK_F9-15):
      scanClr(); 
      break;  
      
     case (KeyEvent.VK_F10-15): case (KeyEvent.VK_F10):
      if (!isScanning) {
        whiteCtp = 0;
        isScanning = true;
      }
      break;
    }
  }

  /** 
   * Ptx KeyPressed function that highjack most of the keys you could use.
   * Only triggered when in recognision mode.
   */
  void keyPressed() {

    float rotVal = 0.01;

    switch(key) {
    //Save/Load Config
    case 'w': saveConfig(); strUI = "Config Saved!"; togUI.reset(true); break;
    case 'x': loadConfig(); strUI = "Config Loaded!"; togUI.reset(true); break;

    case 'A': myPtx.seuilValue  = Math.max(  0.f, myPtx.seuilValue - 1);  break;
    case 'a': myPtx.seuilValue  = Math.min(255.f, myPtx.seuilValue + 1);  break;      
    case 'Z': myPtx.seuilSaturation  = Math.max( 0.f, myPtx.seuilSaturation - 0.01); break;
    case 'z': myPtx.seuilSaturation  = Math.min( 1.f, myPtx.seuilSaturation + 0.01); break;
    case 'E': grayLevelUp  = Math.max(  0, grayLevelUp -3);    break;
    case 'e': grayLevelUp  = Math.min(255, grayLevelUp +3);    break;
    case 'R': grayLevelDown = Math.max(  0, grayLevelDown -3); break;
    case 'r': grayLevelDown = Math.min(255, grayLevelDown +3); break;

    case 'd': myCam.addSaturation(2);  break;
    case 'D': myCam.addSaturation(-2); break;
    case 'f': myCam.addExposure(10);    break;
    case 'F': myCam.addExposure(-10);   break;

    case 'S':
      if (myPtx.indexHue%2 != 0)
        myPtx.listZone.get(myPtx.indexHue/2).b =
          (myPtx.listZone.get(myPtx.indexHue/2).b + 1 )%360;
      else
        myPtx.listZone.get(myPtx.indexHue/2).a =
          (myPtx.listZone.get(myPtx.indexHue/2).a + 1 )%360;
      break;

    case 's':
      if (myPtx.indexHue%2 != 0)
        myPtx.listZone.get(myPtx.indexHue/2).b =
          (myPtx.listZone.get(myPtx.indexHue/2).b + 359 )%360;
      else
        myPtx.listZone.get(myPtx.indexHue/2).a =
          (myPtx.listZone.get(myPtx.indexHue/2).a + 359 )%360;
      break;


    case 'Q': myPtx.indexHue = (myPtx.indexHue + 7)%8; break;
    case 'q': myPtx.indexHue = (myPtx.indexHue + 1)%8; break;

      // Gestion Cam
    case 'C': myCam.zoomCamera*=1.02;       break;
    case 'c': myCam.zoomCamera/=1.02;       break;

    case 'o':
      if( myCam.dotIndex != -1 ) {
        myCam.ROI[myCam.dotIndex].y -= 1;
        myPtx.calculateHomographyMatrice(wFrameFbo, hFrameFbo, myCam.ROI);
        myPtxInter.scanCam();
      }
      break;
    case 'l':
      if( myCam.dotIndex != -1 ) {
        myCam.ROI[myCam.dotIndex].y += 1;
        myPtx.calculateHomographyMatrice(wFrameFbo, hFrameFbo, myCam.ROI);
        myPtxInter.scanCam();
      }
      break;
   case 'k':
      if( myCam.dotIndex != -1 ) {
        myCam.ROI[myCam.dotIndex].x -= 1;
        myPtx.calculateHomographyMatrice(wFrameFbo, hFrameFbo, myCam.ROI);
        myPtxInter.scanCam();
      }
      break;
    case 'm':
      if( myCam.dotIndex != -1 ) {
        myCam.ROI[myCam.dotIndex].x += 1;
        myPtx.calculateHomographyMatrice(wFrameFbo, hFrameFbo, myCam.ROI);
        myPtxInter.scanCam();
      }
      break;
    }
  }
}