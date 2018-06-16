
class particle {
 
  PVector p;
  float s, r;
  color c;
  
  particle(PVector _center) {
    p = _center.copy();
    s = random(1,2); 
    r = 1;
    c = color(random(255), random(255), random(255), random(20, 200) );
  }

  void update() {
    r += s;
  }
  
  void draw() {
    myPtxInter.mFbo.noFill();
    myPtxInter.mFbo.stroke(c);
    myPtxInter.mFbo.strokeWeight(5*(700.0-r)/700);
    myPtxInter.mFbo.ellipse(p.x, p.y, r, r);
    myPtxInter.mFbo.strokeWeight(1);
    myPtxInter.mFbo.noStroke();
  }
  
  
}