import processing.serial.*;

Dobot dobot;

/////////////////////////////////////////////////////////////////////
///////////////some dobot data///////////////////////////////////////
float L1 = 160;                          //the small arm's length;
float L2 = 135;                          //the big arm's length;
float L3 = 80;                            //the base's height;

float MAXRADIUS = 280;                   //the dobot cannot fully stretch, the value is not accurate,it needs to be changed.
float MINA1 = -15*PI/360;
float MAXA1 = PI/2;
float MINA2 = 0;
float MAXA2 = PI/2;

/////////////////////////////////////////////////////////////////////
//////////////////////////some UI data///////////////////////////////
float frontScaleRatio = 1.5;             //enlarge to fit screen
float topScaleRatio = 0.5;                   

float frontOriginTranslateX = 0.2;
float frontOriginTranslateY = 0.25;

int border = 10;                         //the UI ...er a border width
int frontQuadWidth = 800;
int topRadius = 185;

color background = color(230, 245, 245);
PFont dobotWord, coorWord;
//////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////

Dobot2DModule myDobotModule = new Dobot2DModule();

Coordinate2D caught = new Coordinate2D(L2*cos(PI/4) + L1*sin(PI/4), L3 + L2*sin(PI/4) - L1*cos(PI/4), 0);
Coordinate2D target = new Coordinate2D(L2*cos(PI/4) + L1*sin(PI/4), L3 + L2*sin(PI/4) - L1*cos(PI/4), 0);
Coordinate2D display = new Coordinate2D(L2*cos(PI/4) + L1*sin(PI/4), L3 + L2*sin(PI/4) - L1*cos(PI/4), 0);
Coordinate2D real = new Coordinate2D(L2*cos(PI/4) + L1*sin(PI/4), L3 + L2*sin(PI/4) - L1*cos(PI/4), 0);


///////////////////////////some program flags////////////////////////
boolean sent = true;                    //flag to indicate whether the data has been sent
boolean serialEn = false;

/////////////////////////////////////////////////////////////////////
void setup()
{
  dobot = new Dobot("/dev/tty.usbmodem1421", 115200);
  //dobot = new FakeDobot(null, 0);
  dobot.open(this);
  try {
    Thread.sleep(1000);
  } catch (Exception e) {
    // Do nothing.
  }
  int i = 0;
  boolean connected = false;
  while (i < 100 && !connected) {
    IntTuple result = dobot.isReady();
    connected = (result.el0 == 1 && result.el1 == 0x40);
    if (connected) {
      break;
    }
    i++;
  }
  if (!connected) {
    throw new RuntimeException("Dobot unreachable");
  }
  
  serialEn = true;
  
  size(1200, 600);
  smooth();
  dobotWord = loadFont("STHupo-24.vlw");
  coorWord = loadFont("NI7SEG-48.vlw");
}

void draw()
{
  if (serialEn && !sent)
  {
//    float sendX = -(target.x*cos(target.A3)-real.x*cos(real.A3));//the machine's axis is not same as the module, so the sendCoordinate is plus a negtive sign;
//    float sendY = -(target.x*sin(target.A3)-real.x*sin(real.A3));
//    float sendZ = (target.y-real.y);
//
//    sendDeltaXYZ(sendX, sendY, sendZ, 0, 0, 2*sqrt(sq(sendX) + sq(sendY) + sq(sendZ)));

    //the machine's axis is not same as the module, so the sendCoordinate is with plus a negative sign.
    float sendX = -(target.x*cos(target.A3));
    float sendY = -(target.x*sin(target.A3));
    float sendZ = target.y;
    
    //sendXYZ(sendX, sendY, sendZ);
    dobot.steps(0, 0, 1, 12000, 0, 0, 0, false);

    //println("send.x " + target.x + "\tsend.y " + target.y + "\tsend.A3 " + target.A3);
    //println("real.x " + real.x + "\treal.y " + real.y + "\treal.A3 " + real.A3);
    //println("send_X " + sendX + "\tsend_Y " + sendY + "\tsend_Z " + sendZ);
    //println(target.A3);
    //println();

    real.x = target.x;
    real.y = target.y;
    real.A3 = target.A3;
    sent = true;
  }
  target = constrain(caught);

  background(background);
  strokeWeight(2);
  noFill();
  quad(border, border, frontQuadWidth+border, border, frontQuadWidth+border, height-8*border, border, height-8*border);//the front quad
  //  quad(frontQuadWidth+3*border, border, width-border, border, width-border, height/2-border, frontQuadWidth+3*border, height/2-border);//the servo quad
  //  quad(frontQuadWidth+3*border, height/2+border, width-border, height/2+border, width-border, height-border, frontQuadWidth+3*border, height-border);//top quad
  //ellipse(width-border-topRadius, height-border-topRadius, 2*topRadius, 2*topRadius);//the top ellipse;
  arc(width-border-topRadius, 2*border+topRadius, 2*topRadius, 2*topRadius, -5*QUARTER_PI, QUARTER_PI, CHORD);

  fill(100);
  textFont(coorWord, 48);

  String stringX = (Float.toString(display.x*cos(display.A3))+"00000").substring(0, 5);
  String stringY = (Float.toString(display.y*sin(display.A3))+"00000").substring(0, 5);
  String stringZ = (Float.toString(display.y)+"00000").substring(0, 5);

  text("x: "+stringX, 885, 400);
  text("Y: "+stringY, 885, 450);
  text("Z: "+stringZ, 885, 500);

  /////////////////////////////////////////////////////////////////////
  /////////////////////the front dobot easing move/////////////////////
  float easing = 0.1;
  float dx = target.x - display.x;
  float dy = target.y - display.y;
  float ds = sqrt(sq(dx)+sq(dy));
  if (ds > 1.0) {
    myDobotModule.displayFront(display.x + dx*easing, display.y + dy*easing);
    display.x += dx*easing;
    display.y += dy*easing;
  } else {
    myDobotModule.displayFront(display.x, display.y);
  }
  //  print(display.x + "\t");
  //  println(display.y);
  /////////////////////////////////////////////////////////////////////
  ///////////////////the top dobot easing move/////////////////////////
  float dA3 = target.A3 - display.A3;
  if (abs(dA3) >0.01 )
  {
    myDobotModule.displayTop(display.x, display.y, display.A3 + dA3*easing);
    display.A3 += dA3*easing;
  } else
  {
    myDobotModule.displayTop(display.x, display.y, display.A3);
  }
}

Coordinate2D constrain(Coordinate2D coor)
{
/////////////////////// constrain the dobot in the reachable area ///////////////////
    if (coor.x<60)
    { 
      coor.x = 120 - coor.x;
    }
    if (coor.y<0)
    {
      coor.y = 0;
    }
    // The radius.
    float R = sqrt(sq(coor.x) + sq(coor.y-L3));
    if (R > MAXRADIUS)
    {
      coor.x = coor.x*MAXRADIUS/R;
      coor.y = L3+(coor.y-L3)*MAXRADIUS/R;
    }
    /////////////////////////////////////////////////////////////////////
    /////////caculate the a1 and a2 (angle1 and angle2)//////////////////
    float A = -2 * coor.x * L1;
    float B = 2 * (coor.y-L3)*L1;
    float C = sq(L2) - sq(L1) - sq(coor.x) - sq(coor.y-L3);
    float a1 = constrain(2*atan((B-sqrt(sq(B)+sq(A)-sq(C)))/(A+C)), MINA1, MAXA1);
    
    A = 2 * (coor.y-L3) * L2;
    B = 2 * coor.x * L2;
    C = sq(L2) + sq(coor.x) + sq(L3 - coor.y) - sq(L1) ;
    float a2 = constrain(2*atan((B-sqrt(sq(B)+sq(A)-sq(C)))/(A+C)), MINA2, MAXA2);
    
    coor.A3 = constrain(coor.A3, -3*QUARTER_PI, 3*QUARTER_PI);
    /////////////////////////////////////////////////////////////////////

    Coordinate2D temp = new Coordinate2D(L2*sin(a2)+L1*cos(a1),(L2*cos(a2)-L1*sin(a1)+L3)<=0 ? 0 : (L2*cos(a2)-L1*sin(a1)+L3),coor.A3);
    return(temp);
}

void mousePressed() {
  //if mouse is in the front quad
  if (border<mouseX && mouseX<frontQuadWidth+border && border<mouseY && mouseY<height-8*border)
  {
    caught.x = (mouseX - width*frontOriginTranslateX)/frontScaleRatio;//calculate mouseX and mouseY in the front origin system;
    caught.y = (height*(1-frontOriginTranslateY) - mouseY)/frontScaleRatio;
  }

  //if mouse is in the top width-border-topRadius, height-border-topRadius, 2*topRadius, 2*topRadius
  if (sq(mouseX - (width-border-topRadius)) + sq((2*border+topRadius) - mouseY) < sq(topRadius))
  {
    float tempX = (mouseX - (width-border-topRadius))/topScaleRatio;
    float tempY = ((2*border+topRadius) - mouseY)/topScaleRatio;

    if (tempX>0)
    {
      caught.A3 =  HALF_PI-atan(tempY/tempX);
    } else
    {
      caught.A3 =  -HALF_PI-atan(tempY/tempX);
    }
  }
}

void mouseDragged()
{
  if (border<mouseX && mouseX<frontQuadWidth+border && border<mouseY && mouseY<height-8*border)//if mouse is in the front quad
  {
    caught.x = (mouseX - width*frontOriginTranslateX)/frontScaleRatio;//caculate the mouseX and mouseY in the front origin system;
    caught.y = (height*(1-frontOriginTranslateY) - mouseY)/frontScaleRatio;
  }

  if (sq(mouseX - (width-border-topRadius)) + sq((2*border+topRadius) - mouseY) < sq(topRadius))//if mouse is in the top width-border-topRadius, height-border-topRadius, 2*topRadius, 2*topRadius
  {
    float tempX = (mouseX - (width-border-topRadius))/topScaleRatio;
    float tempY = ((2*border+topRadius) - mouseY)/topScaleRatio;

    if (tempX>0)
    {
      caught.A3 =  HALF_PI-atan(tempY/tempX);
    } else
    {
      caught.A3 =  -HALF_PI-atan(tempY/tempX);
    }
  }
}

void mouseReleased()
{
  sent = false;
}