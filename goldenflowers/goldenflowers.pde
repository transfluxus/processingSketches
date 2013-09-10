/*
This program was developed during the 6. Processing code jam Berlin 
The idea was to have several computers connected to this to have 
a canvas for cooperative drawing.
The basic programs for osc interaction are here:
https://github.com/hamoid/Fun-Programming/tree/master/processing/ideas/2013/09/processingCodeJam

*/


Receiver rec;

void setup() {
  size(displayWidth, displayHeight);
  noStroke();
  background(0);
  rec = new Receiver(12000);
  PFont font = loadFont("font.vlw");
  textFont(font);
  textSize(150);
  textMode(CENTER);
  strokeCap(ROUND);
}

// circle radius
float r=30;
// number of leafes per draw
int iter = 6;
// maximum radius and number of leafes
float maxR=50;
int maxIter = 6;
// actual angle of all leafes
float angle=random(TWO_PI);
// superUser set drawing lines between user positions
boolean drawLines = true;

float goldenRatio =( 1+ sqrt(5)) / 2;
float goldenAngle = TWO_PI / goldenRatio;

// a map of users : <userId,internalId> internal ids are simply incrementing with each new user
HashMap<Integer, Integer> userMap = new HashMap<Integer, Integer>();
// internalId of the superuser. The power user controls the radius and number of leafes
int superuser=0;
// last position of the superuser
PVector superuserPos = new PVector(0, 0);
// last positions of all other users
HashMap<Integer, PVector> lastPoses = new HashMap<Integer, PVector>();
// number of frames per superuser. randomly select a new superuser ever SuperUserTime frames
int SuperUserTime = 450;

boolean localuser = true;

void draw() {
  blendMode(ADD);
  fill(0, 140);
  rect(-5, -5, width+10, height+10);

  // draw lines between users if superuser clicks the mouse
  if (drawLines)
    drawConnections();
  // this makes the color magic
  if (frameCount%2==0)
    blendMode(ADD);
  else
    blendMode(SUBTRACT);
  // process the mouse positions of all users
  takeMouseMsgs();
  // process the key hits of all users
  takeKeyMsgs();

  // for private interaction
  if (localuser && mousePressed) 
    drawFlower(mouseX, mouseY, r, iter);

  // define new superuser after a certain time
  if (frameCount%SuperUserTime==0) {
    newSuperUser();
  }
  // new leaf-angle
  angle +=goldenAngle;
}

// clear the screen and randomly set a new superuser
void newSuperUser() {
  blendMode(DARKEST);
  fill(random(255), random(255), random(255), 20);
  rect(-5, -5, width+10, height+10);
  superuser = (int) random(userMap.size());
}

// draw lines between all users except the superuser
void drawConnections() {
  strokeWeight(5);
  stroke(255, 10);
  blendMode(SCREEN);
  // outer loop
  for (Integer id : lastPoses.keySet()) {
    if (id == superuser)
      continue;
    PVector me =lastPoses.get(id);
    // inner loop
    for (Integer ids : lastPoses.keySet()) 
      if (id!=ids) {
        PVector other =lastPoses.get(ids);
        line(me.x, me.y, other.x, other.y);
      }
  }
  noStroke();
}

// taking the mouse osc messages
void takeMouseMsgs() {
  while (true) {
    // loop through all received mouse data 
    MouseData event = rec.getMouseData();
    // get out if no more data
    if (event == null) {
      break;
    }
    // add the user to the usermap if his id is new
    if (! userMap.containsKey(event.usrid))
      newUser(event.usrid);
      // superuser
    if (userMap.get(event.usrid)== superuser) {
      // change radius and number of leafes if he presses the mouse
      if (event.pressed) {
        r = event.x*maxR;
        iter = (int)(event.y*maxIter);
        superuserPos.set(event.x*width, event.y*height, 0);
        println("new r: "+ r+ " ,iter: "+iter);
      }
      drawLines = event.pressed;
    } 
    else // other users, update their location and draw leafes
      if (event.pressed) {
      lastPoses.put(userMap.get(event.usrid), new PVector(event.x*width, event.y*height));
      drawFlower(event.x*width, event.y*height, r, iter);
    }
  }
}

// draw the flower, or better a number of leafes
void drawFlower(float t1x, float t1y, float r, int iter ) {
  // a leaf is a triangle between a circle center and two points a a circle with given radius and number of leafes (iter)
  for (int i=0; i < iter;i++) {
    // first point on the circle
    float t2x= t1x+cos(angle)*r;
    float t2y= t1y+sin(angle)*r;
    // 2nd point on the circle, 36 degree further, so a golden triangle is drawn
    float t3x = t1x+cos(angle+radians(36))*r;
    float t3y = t1y+sin(angle+radians(36))*r;
    fill(random(255), random(255), random(255), 2);
    triangle(t1x, t1y, t2x, t2y, t3x, t3y);
    // increase the size of each leaf
    r*= goldenRatio;
  }
}

// process key input
void takeKeyMsgs() {
  while (true) {
    // loop through all received key data
    KeyData event = rec.getKeyData();
    // get out if no more data
    if (event == null) {
      break;
    }
    // draw the letter at the position of the superuser
    fill(event.usrid * 100 % 256);
    noStroke();
    text(event.key, superuserPos.x, superuserPos.y);
  }
}

// add the user to the map
public void newUser(int id) {
//  println(id);
  userMap.put(id, userMap.size());
  superuser = (int) random(userMap.size());
}

