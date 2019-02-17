
// ===== 1) ROOT LIBRARY =====
boolean isScanning, isInConfig;
ptx_inter myPtxInter;
char scanKey = 'a';
// ===== =============== =====

int x, y;
  
void setup() {

  // ===== 2) INIT LIBRARY =====  
  isScanning = false;
  isInConfig = false;
  myPtxInter = new ptx_inter(this);

  // ===== =============== =====


  //fullScreen(P3D);
  size(1300, 900, P3D);
  noCursor();

  x = myPtxInter.wFrameFbo/2;
  y = myPtxInter.hFrameFbo/2;
  
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


  // Keep this part of the code to reset drawing
  background(10);
  myPtxInter.mFbo.beginDraw();

  // Draw here with "myPtxInter.mFbo" before call to classic drawing functions 
  myPtxInter.mFbo.background(0);
  myPtxInter.mFbo.fill(255);
  myPtxInter.mFbo.stroke(255);
  myPtxInter.mFbo.ellipse(x, y, 20, 20);
  
  for(area refArea : myPtxInter.getListArea())
    refArea.draw(1);

  // Keep this part of the code to reset drawing
  myPtxInter.mFbo.endDraw();
  myPtxInter.displayFBO();

}



// Function that is triggered at the end of a scan operation
// Use it to update what is meant to be done once you have "new areas"

void atScan() {
}



void keyPressed() {


  // ===== 4) KEY HANDlING LIBRARY ===== 

  // Forbid any change it you're in the middle of scanning
  if (isScanning) {
    return;
  }

  myPtxInter.managementKeyPressed();

  if (isInConfig) {
    myPtxInter.keyPressed();
    return;
  }

   
  // Master key #2 / 2, that launch the scanning process
  if (key == scanKey && !isScanning) {
    myPtxInter.whiteCtp = 0;
    isScanning = true;
    return;
  }

  // ===== ================================= =====    


  if (key==CODED) {
    println(keyCode);
    switch(keyCode) {
    case UP:    
      y-=5; 
      break;
    case DOWN:  
      y+=5; 
      break;
    case LEFT:  
      x-=5; 
      break;
    case RIGHT: 
      x+=5; 
      break;    
    }
  }
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

  if (isInConfig && myPtxInter.myGlobState == globState.CAMERA  && myPtxInter.myCamState == cameraState.CAMERA_WHOLE && mouseButton == LEFT) {

    // Select one "dot" of ROI if close enough
    myPtxInter.myCam.dotIndex = -1;
    for(int i = 0; i < 4; ++i) {
      if( (myPtxInter.myCam.ROI[i].subTo( new vec2f(mouseX, mouseY) ).length()) < 50 ) {
        myPtxInter.myCam.dotIndex = i;
      }
      
    }
  }

  // ===== ========================= =====
}

void mouseDragged() {

  // ===== 7) MOUSE HANDLIND LIBRARY ===== 
  
    if (isInConfig && myPtxInter.myGlobState == globState.CAMERA) {
       if (myPtxInter.myCam.dotIndex != -1) {
         myPtxInter.myCam.ROI[myPtxInter.myCam.dotIndex].addMe( new vec2f(mouseX-pmouseX, mouseY - pmouseY) ); 
       }
    }

  // ===== ========================= =====
}

void mouseReleased() {
  
  if (isInConfig && myPtxInter.myGlobState == globState.CAMERA  && myPtxInter.myCamState == cameraState.CAMERA_WHOLE)
       if (myPtxInter.myCam.dotIndex != -1) {
         myPtxInter.myPtx.calculateHomographyMatrice(myPtxInter.wFrameFbo, myPtxInter.hFrameFbo, myPtxInter.myCam.ROI);
         myPtxInter.scanCam();
       }

  
  
}