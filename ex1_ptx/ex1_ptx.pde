import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.shapes.Shape;
import org.jbox2d.collision.Manifold;
import org.jbox2d.collision.WorldManifold;

import java.util.Collection;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Set;


// ===== 1) ROOT LIBRARY =====
boolean isScanning, isInConfig;
ptx_inter myPtxInter;
char scanKey = 'a';
// ===== =============== =====


// TODO: HERITAGE CONSTRUCTEUR DANS AREACORE + typeArea : BUMP, WALL,  LAVA ...

Box2DProcessing box2d;
ArrayList<Object> myObj1, myObj2;
player player1, player2;
ArrayList<areaCore> myMap = new ArrayList<areaCore>();


void setup() {

  // ===== 2) INIT LIBRARY =====  
  isScanning = false;
  isInConfig = false;
  myPtxInter = new ptx_inter(this);

  // ===== =============== =====


  //fullScreen(P3D);
  size(1300, 900, P3D);
  noCursor();

  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setScaleFactor(100);
  box2d.setGravity(0,0);
  box2d.listenForCollisions();
  
  myObj1 = new ArrayList<Object>();
  myObj2 = new ArrayList<Object>();

  player1 = new player(1);
  player2 = new player(2);

}

void reset() {
    player1.reset();
    player2.reset();    
    atScan();
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



 
  //UPDATE
  player1.updateMe();
  player2.updateMe();
  box2d.step();
  
  myObj1.clear();
  myObj2.clear();
    
  //DRAW
  background(0);
  myPtxInter.mFbo.beginDraw();
  myPtxInter.mFbo.background(0);
  myPtxInter.mFbo.fill(255);
  myPtxInter.mFbo.stroke(255);

  for(area refArea : myPtxInter.getListArea())
    refArea.draw(1);
        
  player1.drawMe();
  player2.drawMe();

  myPtxInter.mFbo.endDraw();
  myPtxInter.displayFBO();
}



// Function that is triggered at the end of a scan operation
// Use it to update what is meant to be done once you have "new areas"

void atScan() {
  
    // clear Bodies
    for (areaCore it : myMap)
      box2d.destroyBody(it.body);
        
    // clear Map
    myMap.clear();
    
    for (area itArea : myPtxInter.getListArea())
      myMap.add(new areaCore(itArea) );
      
}



void keyPressed() {


  // ===== 4) KEY HANDlING LIBRARY ===== 

  // Forbid any change it you're in the middle of scanning
  if (isScanning) {
    return;
  }


  myPtxInter.managementKeyPressed();

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


    switch(key) {
    case 'a': player1.facing.y =  1; break;
    case 'z': player1.facing.y = -1; break; 
    case 'e': player1.facing.x = -1; break;
    case 'r': player1.facing.x =  1; break; 
    
    case 'q': player2.facing.y =  1; break;
    case 's': player2.facing.y = -1; break; 
    case 'd': player2.facing.x = -1; break;
    case 'f': player2.facing.x =  1; break; 
      
    case 'p' : reset();
    }
}
 

void keyReleased() {

  // ===== 5) KEY HANDlING LIBRARY ===== 

  if (isScanning || isInConfig) {
    return;
  }
  // ===== ======================= =====
  
  switch(key) {
  case 'a': player1.facing.y = min(player1.facing.y, 0); break;
  case 'z': player1.facing.y = max(player1.facing.y, 0); break;
  case 'e': player1.facing.x = max(player1.facing.x, 0); break;
  case 'r': player1.facing.x = min(player1.facing.x, 0); break;

  case 'q': player2.facing.y = min(player2.facing.y, 0); break;
  case 's': player2.facing.y = max(player2.facing.y, 0); break;
  case 'd': player2.facing.x = max(player2.facing.x, 0); break;
  case 'f': player2.facing.x = min(player2.facing.x, 0); break;
  }
  
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

// Collision event functions!
void beginContact(Contact cp  ) {
    
  // Get manifold
  WorldManifold mp = new WorldManifold();
  cp.getWorldManifold(mp);
  
  PVector normP = new PVector(mp.normal.x, mp.normal.y).normalize();
  PVector contP = box2d.coordWorldToPixelsPVector(mp.points[0]);
  
  // Get both fixtures
  Fixture f1 = cp.getFixtureA();
  Fixture f2 = cp.getFixtureB();
  
  // Get both bodies
  Body b1 = f1.getBody();
  Body b2 = f2.getBody();

  // Check if both bodies have already interact
  boolean getOut = false;
  for(int i = 0; i<myObj1.size(); ++i)
    if( (myObj1.get(i) ==  b1.getUserData() && myObj2.get(i) == b2.getUserData())
     || (myObj1.get(i) ==  b1.getUserData() && myObj2.get(i) == b2.getUserData()) )
       getOut = true;

  if(getOut) {
    return;
  }
    
  // Add to the list
  myObj1.add(b1.getUserData());
  myObj2.add(b2.getUserData());

  // Get our objects that reference these bodies
  Object o1 = b1.getUserData();
  Object o2 = b2.getUserData();

  // 2 Joueurs
  if (o1.getClass() == player.class && o2.getClass() == player.class) {
    
    player p1, p2;
    
    if( ((player) o1).id == 1) {
      p1 = (player) o1;  
      p2 = (player) o2;  
    
    } else {
      p1 = (player) o2;  
      p2 = (player) o1;  
    }

    PVector dir = box2d.coordWorldToPixelsPVector( p1.body.getPosition() );
    dir.sub(box2d.coordWorldToPixelsPVector( p2.body.getPosition() ) );
    dir.normalize();
    
    // Bump par contact (centre centre)
    p1.s.sub( normP.copy().mult(4) );
    p2.s.add( normP.copy().mult(4) );

    // Bump par vitesse de l'autre (centre centre? Ou direction de vitesse? anti physique)
    p1.s.add( p2.facing.copy().mult( abs(p2.sCom.mag() + p1.s.mag()) ).mult(0.7) );
    p2.s.add( p1.facing.copy().mult( abs(p1.sCom.mag() + p1.s.mag()) ).mult(0.7) );  
    
  } 
  

  // Zone Joueur
  if( (o1.getClass() == areaCore.class && o2.getClass() == player.class) || (o1.getClass() == player.class && o2.getClass() == areaCore.class) ) {
    player myP;
    areaCore myA;

    if(o1.getClass() == areaCore.class) {
      myA = (areaCore) o1;
      myP = (player) o2;
    } else {
      myA = (areaCore) o2;
      myP = (player) o1;
    }
    
    if(b1.getUserData() == b2.getUserData());
    if(myA.type == areaCoreType.BUMP) {
      myP.s.add( normP.copy().mult(20));
    }
    
  }
  
}