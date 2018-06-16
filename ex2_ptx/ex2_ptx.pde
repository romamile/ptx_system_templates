// ===== 1) ROOT LIBRARY =====
boolean isScanning, isInConfig;
ptx_inter myPtxInter;
char scanKey = 'a';
char configKey = 'z';
// ===== =============== =====


ArrayList<particle> parList = new ArrayList<particle>();

void setup() {

  // ===== 2) INIT LIBRARY =====  
  isScanning = false;
  isInConfig = false;
  myPtxInter = new ptx_inter(this);

  // ===== =============== =====


  fullScreen(P3D);
  noCursor();

}

void draw() {

  // ===== 3) SCANNING & CONFIG DRAW LIBRARY =====  
  if (isScanning) {
    background(0);
    myPtxInter.generalRender(); 

    if (myPtxInter.whiteCtp > 20 && myPtxInter.whiteCtp < 22)
      myPtxInter.myCam.update();

    if (myPtxInter.whiteCtp > 35) {

      myPtxInter.scanCam();
      if (myPtxInter.myGlobState != globState.CAMERA)
        myPtxInter.scanClr();

      myPtxInter.whiteCtp = 0;
      isScanning = false;
      atScan();
    }
    return;
  }

  if (isInConfig) {
    background(0);
    myPtxInter.generalRender();
    return;
  }
  // ===== ================================= =====  



  // Your drawing start here

  for(area it: myPtxInter.getListArea())
    if(random(1) < 0.01)
      parList.add( new particle(new PVector(it.center.x, it.center.y) ) );  
    

  for(particle it: parList)
    it.update();
    
    println(parList.size() + " - " + frameRate);

  for(int i = parList.size()-1; i>=0; --i)
    if(parList.get(i).r >= 700)
      parList.remove(i);

  // Keep this part of the code to reset drawing
  background(0);
  myPtxInter.mFbo.beginDraw();

  // Draw here with "myPtxInter.mFbo" before call to classic drawing functions 
  myPtxInter.mFbo.background(0);
  
  
  for(area refArea : myPtxInter.getListArea())
    myPtxInter.drawArea(refArea);
    
    
  for(particle it: parList)
    it.draw();

  // Keep this part of the code to reset drawing
  myPtxInter.mFbo.endDraw();
  myPtxInter.displayFBO();
}



// Function that is triggered at the end of a scan operation
// Use it to update what is meant to be done once you have "new areas"

void atScan() {
  
  parList.clear();
  
}



void keyPressed() {


  // ===== 4) KEY HANDlING LIBRARY ===== 

  // Forbid any change it you're in the middle of scanning
  if (isScanning) {
    return;
  }

  // Master key #1 / 2, that switch between your project and the configuration interface
  if (key == configKey) {
    isInConfig = !isInConfig;
    return;
  }

  // Master key #2 / 2, that launch the scanning process
  if (key == scanKey && !isScanning) {
    myPtxInter.whiteCtp = 0;
    isScanning = true;
    return;
  }

  // Set of key config in the the input mode
  if (isInConfig) {
    myPtxInter.keyPressed();
    return;
  }

  // ===== ================================= =====    


}

void keyReleased() {

  // ===== 5) KEY HANDlING LIBRARY ===== 

  if (isScanning || isInConfig) {
    return;
  }
  // ===== ======================= =====
}


void mousePressed() {

  // ===== 6) MOUSE HANDLIND LIBRARY ===== 

  if (isInConfig && myPtxInter.myGlobState == globState.CAMERA && mouseButton == LEFT) {

    if (myPtxInter.myCam.dotIndex == -1)
      myPtxInter.myCam.dotIndex = 0; // Switching toward editing 
    else
      myPtxInter.myCam.ROI[myPtxInter.myCam.dotIndex++  ] =
        new vec2f(mouseX * myPtxInter.myCam.mImg.width / width, 
        mouseY * myPtxInter.myCam.mImg.height / height);

    if ( myPtxInter.myCam.dotIndex == 4)
      myPtxInter.myCam.dotIndex = -1;
  }
  // ===== ========================= =====
}

void mouseMoved() {

  // ===== 7) MOUSE HANDLIND LIBRARY ===== 

  if (isInConfig && myPtxInter.myGlobState == globState.CAMERA && myPtxInter.myCam.dotIndex != -1)
    myPtxInter.myCam.ROI[myPtxInter.myCam.dotIndex] =
      new vec2f(mouseX * myPtxInter.myCam.mImg.width  / width, 
      mouseY * myPtxInter.myCam.mImg.height / height);
  // ===== ========================= =====
}