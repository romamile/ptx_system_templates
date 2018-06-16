class player {
 int id;
 int r;
 PVector facing, sCom;
 PVector s, a;
 Body body;
 
 ptx_color col;
 
 public PVector getP() {
   return body == null ? new PVector() : box2d.coordWorldToPixelsPVector( body.getPosition() );
 }
 
 player() {
  id = -1;
  s = new PVector();
  a = new PVector();
  facing = new PVector();
  sCom = new PVector();

  r = 40;
  
  makeBody();
  reset();  
  col = new ptx_color();
 }

 player(int _id) {
  id = _id; 
  s = new PVector();
  a = new PVector();
  facing = new PVector();
  sCom = new PVector();

  r = 60;
    
  switch(id) {
  case 1: col = new ptx_color(255, 255, 0); break;
  case 2: col = new ptx_color(255, 0, 255); break;
  }
 
  makeBody();
  reset();
 }
 
 void updateMe() {
   
    
   // Check if dead
   if(0 > getP().x || getP().x > myPtxInter.mFbo.width
   || 0 > getP().y || getP().y > myPtxInter.mFbo.height) { // Outside of the square game field
     getP().x = myPtxInter.mFbo.width / 2;
     getP().y = myPtxInter.mFbo.height / 2;  
   }
   
   // Moving
   int k =  3;
   if(facing.x != 0) sCom.x = facing.x * k; else sCom.x *= 0.9;
   if(facing.y != 0) sCom.y = facing.y * k; else sCom.y *= 0.9;
   
   //friction
   a.set( - (s.x) / 10, -(s.y) / 10  );
   s.add( a );      


   //physic
   body.setLinearVelocity(new Vec2(s.x + sCom.x, s.y + sCom.y));
 }
 
 void drawMe() {
  myPtxInter.mFbo.noStroke();
  myPtxInter.mFbo.fill(col.r, col.g, col.b);
  myPtxInter.mFbo.ellipse(getP().x, getP().y, r, r);
   
 }
 
void reset() {

  s.set(0,0);
  a.set(0,0);
     
  facing.set(0,0);
  sCom.set(0,0);
  
  box2d.destroyBody(body);
  makeBody();
 }
 
 
  // This function adds the rectangle to the box2d world
  void makeBody() {

    // Define a polygon (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.setRadius(box2d.scalarPixelsToWorld(r/2));

    // Define a fixture
    FixtureDef fd = new FixtureDef();
    fd.shape = sd;
    // Parameters that affect physics
    fd.density = 1;
    fd.friction = 0.3;
    fd.restitution = 0.5;

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;

    PVector p = new PVector();
    switch(id) {
    case 1: p.set(myPtxInter.mFbo.width/2 - 100, myPtxInter.mFbo.height/2 + 100); break;
    case 2: p.set(myPtxInter.mFbo.width/2 + 100, myPtxInter.mFbo.height/2 - 100); break;
    }
    bd.position.set(box2d.coordPixelsToWorld(p));

    body = box2d.createBody(bd);
    body.createFixture(fd);

    body.setUserData(this);
  }

}