
enum areaCoreType { VOID, WALL, BUMP, LAVA }; 

class areaCore extends area {
  
  areaCoreType type;
  Body body;
  
  public areaCore() {
    super();
    type = areaCoreType.VOID;
    
    makeBody();
    reset();
  }
  
  public areaCore(area _area) {
    
    // Area ptx
    super();

    id      = _area.id;
    hue     = _area.hue;
    colId   = _area.colId;
    myShape = _area.myShape;
    
    center = _area.center;
    posXY = new ArrayList<vec2i>(_area.posXY);
    listContour = new ArrayList< ArrayList<vec2i> >(_area.listContour);;
          
    // Area core
    switch(colId) {
    case 0 : type = areaCoreType.BUMP;    break; // RED
    case 1 : type = areaCoreType.WALL;  break; // GREEN
    case 2 : type = areaCoreType.VOID;   break; // BLUE HAR HAR
    case 3 : type = areaCoreType.LAVA; break; // YELLOW
    }

    makeBody();
    reset();
      
  }
  
  public void makeBody() {
    
    ChainShape sd = new ChainShape();

    int kk = 8;
    ArrayList<Vec2> vAL = new ArrayList<Vec2>();
    ArrayList<vec2i> ctr = listContour.get(0);

    Vec2 prev = new Vec2(ctr.get(0).x, ctr.get(0).y);
    vAL.add( box2d.coordPixelsToWorld(prev) );

    for(int i=8; i<listContour.get(0).size(); ++i) {
      Vec2 now = new Vec2(ctr.get(i).x, ctr.get(i).y);
      
      if(PVector.dist( new PVector(prev.x, prev.y), new PVector(now.x, now.y)) > 1) {
        vAL.add( box2d.coordPixelsToWorld(now) );
        i += 8;
        prev = now;
      }
    }

    sd.createLoop(vAL.toArray(new Vec2[vAL.size()]), vAL.size());

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    bd.position.set( new Vec2(0,0) );
    body = box2d.createBody(bd);

    body.createFixture(sd, 1.0);
    
    body.setUserData(this);
   
  }
  
  public void reset() {
   
    box2d.destroyBody(body);
    makeBody(); 
  }
  
}