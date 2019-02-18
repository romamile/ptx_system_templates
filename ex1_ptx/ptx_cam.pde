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
import java.io.InputStreamReader;

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
  int camVideoId, camId;

  boolean hasImage, isFiltered, isRecognised;

  PImage mImg;          // Whole image
  PImage mImgCroped;    // Image with trapeze done
  PImage mImgFilter;
  PImage mImgRez;

  int wFbo, hFbo;
  int wCam, hCam;

  //Selection of ROI in mImg for mImgCroped
  //0 1
  //3 2
  vec2f[] ROI;
  int dotIndex; // 0->3 & -1 == no editing
  float zoomCamera;

  cam() {

    wFbo = 1000;
    hFbo = 1000;
    camVideoId = -1;

    wCam = 0;
    hCam = 0;

    ROI = new vec2f[4];
    mImg = createImage(wFbo, hFbo, RGB);
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

  cam(int _w, int _h) {

    wCam = 0;
    hCam = 0;

    wFbo = _w;
    hFbo = _h;
    camVideoId = -1;

    ROI = new vec2f[4];
    mImg = createImage(wFbo, hFbo, RGB);
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
   * Functions that let the user resize the fbo which defines the 
   * playfield.
   * @param _wFbo        width of FBO
   * @param _hFbo        height of FBO
   */
  void resize(int _wFbo, int _hFbo) {

    wFbo = _wFbo;
    hFbo = _hFbo;

    mImgCroped = createImage(wFbo, hFbo, RGB);
    mImgFilter = createImage(wFbo, hFbo, RGB);
    mImgRez    = createImage(wFbo, hFbo, RGB);
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

    if (cameras.length == 0)
      return;

    if (_idCam < cameras.length) {
      println("FOUND GOOD CAM");
      camStr = cameras[_idCam];
      camId = _idCam;
    } else {
      println("DEFAULT CAM");
      camStr = cameras[0];
    }

    println(_idCam + " / Camera: " + camStr);

    // Check camVideoId for control of hardware camera
    String[] camStrSplit = split(camStr, ',');
    camVideoId = Character.getNumericValue( camStrSplit[0].charAt(camStrSplit[0].length()-1) ); 

    // 2) Create the capture object
    cpt = new Capture(_myGrandParent, camStr);

    // 3) Launch
    cpt.start();

    while (cpt.width * cpt.height == 0) {     
      update();
      print("Waiting for camera with non null values ");
    }

    wCam = cpt.width;
    hCam = cpt.height;
    mImg = createImage(wCam, hCam, RGB);

    println(cpt.width);

    switchToManual();
    update();
    update();
  }

  /** 
   * Get another image from the camera stream if possible
   * @return          <code>true</code> if the camera is availabe. 
   */
  boolean update() {

    if (camVideoId == -1)
      return true;

    long locStart  = System.currentTimeMillis();  
    if (cpt.available()) {
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


  /** 
   * Function that setup camera
   */
  void parametriseCamera() {
    if (  System.getProperty ("os.name") == "Linux") {
      String setCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl ";
      String getCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --get-ctrl ";

      exe(setCmd+"white_balance_temperature_auto=0");
      exe(setCmd+"exposure_auto_priority=0");
      exe(setCmd+"focus_auto=0");
      exe(setCmd+"exposure_auto=0");
    }
  }

  int getSaturation() {
    if (  System.getProperty("os.name").contains("Linux") ) {      
      String satStr = exe("v4l2-ctl -d /dev/video"+camVideoId+" --get-ctrl saturation");

      if ( satStr.contains("unknown") ) {
        println("Camera doesn't have the parametre saturation");
        return -1;
      }
      return Integer.parseInt( split(satStr, ' ')[1] );
    }
    return -1;
  }

  int getExposure() {
    if (  System.getProperty("os.name").contains("Linux") ) {
      String expStr = exe("v4l2-ctl -d /dev/video"+camVideoId+" --get-ctrl exposure_absolute");

      if ( expStr.contains("unknown") ) {
        println("Camera doesn't have the parametre saturation");
        return -1;
      }
      return Integer.parseInt( split(expStr, ' ')[1] );
    }
    return -1;
  }

  void addSaturation(int n) {
    if (  System.getProperty("os.name").contains("Linux") ) {
      String setCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl ";
      String getCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --get-ctrl ";

      String satStr = exe(getCmd+"saturation");

      if ( satStr.contains("unknown") ) {
        println("Camera doesn't have the parametre saturation");
        return;
      }
      int satVal = Integer.parseInt( split(satStr, ' ')[1] ) + n;
      exe(setCmd+"saturation="+satVal);
    }
  }

  void addExposure(int n) {
    if (  System.getProperty ("os.name").contains("Linux") ) {
      String setCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl ";
      String getCmd = "v4l2-ctl -d /dev/video"+camVideoId+" --get-ctrl ";

      String expStr = exe(getCmd+"exposure_absolute");
      if ( expStr.contains("unknown") ) {
        println("Camera doesn't have the parametre exposure");
        return;
      }
      int expVal = Integer.parseInt( split(expStr, ' ')[1] ) + n;
      exe(setCmd+"exposure_absolute="+expVal);
    }
  }  

  void switchToManual() {
    if (  System.getProperty ("os.name").contains("Linux") ) {

      exe("v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl white_balance_temperature_auto=0");
      exe("v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl exposure_auto_priority=0");
      exe("v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl focus_auto=0");
      exe("v4l2-ctl -d /dev/video"+camVideoId+" --set-ctrl exposure_auto=1");
    }
  }

  String exe(String cmd) {

    String returnedValues = "";
    String rezStr = "";

    try {
      File workingDir = new File("./");  
      Process p = Runtime.getRuntime().exec(cmd, null, workingDir);

      // variable to check if we've received confirmation of the command
      int i = p.waitFor();

      // if we have an output, print to screen
      if (i == 0) {

        // BufferedReader used to get values back from the command
        BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));

        // read the output from the command
        while ( (returnedValues = stdInput.readLine ()) != null) {
          if (rezStr.equals(""))
            rezStr=returnedValues;
          //println("out/ "+ returnedValues);
        }
      }

      // if there are any error messages but we can still get an output, they print here
      else {
        BufferedReader stdErr = new BufferedReader(new InputStreamReader(p.getErrorStream()));

        // if something is returned (ie: not null) print the result
        while ( (returnedValues = stdErr.readLine ()) != null) {
          if (rezStr.equals(""))
            rezStr=returnedValues;
          //println("err/ "+returnedValues);
        }
      }
    }

    // if there is an error, let us know
    catch (Exception e) {
      println("Error running command!");  
      println(e);
    } 

    return rezStr;
  }
}