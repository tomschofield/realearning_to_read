class ScanManager {
  Capture camLeft;
  Capture camRight;

  String leftName= "FaceTime HD Camera";
  String rightName= "FaceTime HD Camera (Display)";

  SimpleFiducial detector;
  List<FiducialFound> found;

  int camsWidth, camsHeight;
  boolean runStereoCam = true;
  boolean leftCamHasMarker = false;
  boolean rightCamHasMarker = false;
  boolean camsActive = false;
  int  captureWidth, captureHeight;
  int grabWidth;
  int grabHeight;
  int grabX;
  int grabY;
  PApplet pa;
  boolean assignedLeftAndRight = false;

  ScanManager(PApplet _pa, int _captureWidth, int _captureHeight) {
    pa= _pa;
    grabWidth = _captureWidth;
    grabHeight = _captureHeight;
    grabX = (width/2) - (grabWidth/2) ;
    grabY = (height/2) - (grabHeight/2) ;
    captureWidth = _captureWidth;
    captureHeight = _captureHeight;

    String[] cameras = Capture.list();
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      // println("Available cameras:");
      //for (int i = 0; i < cameras.length; i++) {
      //  println(i, cameras[i]);
      //}
    }


    String leftName= "HD Pro Webcam C920";
    String rightName= "HD Pro Webcam C920 #"+str(findLogitechNumber(cameras));
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    camLeft = new Capture(pa, captureWidth, captureHeight, leftName, 15);
    camLeft.start();

    if (runStereoCam) {
      camRight = new Capture(pa, captureWidth, captureHeight, rightName, 15);
      camRight.start();
    }
    camsActive = true;

    camsWidth = camLeft.width;
    camsHeight = camLeft.height;


    detector = Boof.fiducialSquareBinaryRobust(0.1);

    detector.guessCrappyIntrinsic(camsWidth, camsHeight);
  }

  int findLogitechNumber(String [] cameras) {
    // String [] logitechs = new String[2];
    int logitechNumber = 1;
    // int index = 0;
    for (int i=0; i<cameras.length; i++) {
     // println("cameras[i].substring(0, 18)", cameras[i].substring(0, 25));
      if (cameras[i].substring(0, 25).trim().equals("name=HD Pro Webcam C920 #")) {
       // println("Found one", cameras[i].substring(25, 26));
        logitechNumber = int(cameras[i].substring(25, 26));
      }
    }
    return logitechNumber;
  }
  void stopCams() {
    camsActive = false;
    camLeft.stop();
    camRight.stop();
  }
  void startCams() {
    
    if (!camsActive) {
      camsActive = true;
      camLeft.start();
      camRight.start();
    }
  }
  void update() {

    if (!assignedLeftAndRight) {



      while (!leftCamHasMarker && !rightCamHasMarker) {

        if (camLeft.available() == true) {
          //  println("camleft available");
          camLeft.read();
          found = detector.detect(camLeft);
          if (found.size()>0) {
            leftCamHasMarker = true;
          }
        }
        if (runStereoCam) {
          if (camRight.available() == true) {
            //    println("camright available");

            camRight.read();
            found = detector.detect(camRight);
            if (found.size()>0) {
              rightCamHasMarker = true;
            }
          }
        }

        if (!leftCamHasMarker && !rightCamHasMarker) {
          println("no markers found, waiting");
        } else if (leftCamHasMarker) {
          //do nothing this is the default setup
        } else if (rightCamHasMarker) {

          //println("found marker in right");
          //camLeft.stop();
          //camRight.stop();
          //camLeft = new Capture(pa, 1280, 720, rightName, 15);
          //camLeft.start();

          //if (runStereoCam) {
          //  camRight = new Capture(pa, 1280, 720, leftName, 15);
          //  camRight.start();
          //}
        }
      }
      if (rightCamHasMarker) {
        //println("found marker in right");
      } else if (leftCamHasMarker) {
        //println("found marker in left");
      }
      assignedLeftAndRight=true;
    } else {
      if (camsActive) {
        ///only after cams are assigned
        //println("cams are assigned");
        if (camLeft.available() == true) {
          //println("camleft available");
          camLeft.read();
          if (leftCamHasMarker) {
            found = detector.detect(camLeft);
            //println("detecing in left cam", found.size());
          } else {
            // println("no marker in left cam");
          }
        }
        if (runStereoCam) {
          if (camRight.available() == true) {
            // println("camright available");

            camRight.read();
            if (rightCamHasMarker) {
              found = detector.detect(camRight);
              // println("detecing in right cam", found.size());
            } else {
              // println("no marker in right cam");
            }
          }
        }
      }
    }
  }
  boolean foundBook() {
    if (assignedLeftAndRight) {
      if (found!=null) {
        //  println(found.size());
        if (found.size()<=0) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
  void drawLeft(int x, int y, int w, int h) {

    image(camLeft, x, y, w, h);

    //image(camLeft, 0, 0, width, height);
  }

  void drawRight(int x, int y, int w, int h) {
    if (runStereoCam) {
      image(camRight, x, y, w, h);
    }
  }

  void drawBoth() {
    drawLeft(0, 0, camsWidth, camsHeight);
    drawRight(width/2, 0, camsWidth, camsHeight);
  }
  void rotateAndSaveImage(PImage im) {

    PImage sImage = createImage(im.height, im.width, RGB);
    im.loadPixels();
    sImage.loadPixels();
    for (int x=0; x<im.width; x++) {
      for (int y=0; y<im.height; y++) {
        sImage.set(y, x, im.get(x, im.height-y));
      }
    }
    sImage.updatePixels();
    sImage.save("data/grab.png");
  }
  void rotateAndSaveImageDouble(PImage im, PImage im2) {

    PImage sImage = createImage(2*im.height, im.width, RGB);
    im.loadPixels();
    sImage.loadPixels();
    for (int x=0; x<im.width; x++) {
      for (int y=0; y<im.height; y++) {
        sImage.set(im2.height+y, x, im.get(im.width-x, y));
      }
    }

    im2.loadPixels();
    for (int x=0; x<im2.width; x++) {
      for (int y=0; y<im2.height; y++) {
        sImage.set(y, x, im2.get(x, im2.height-y));
      }
    }


    sImage.updatePixels();
    sImage.save("data/grab.png");
  }
  void rotateAndSaveImageDoubleStacked(PImage im, PImage im2) {

    PImage sImage = createImage(im.height, 2*im.width, RGB);
    im.loadPixels();
    sImage.loadPixels();
    for (int x=0; x<im.width; x++) {
      for (int y=0; y<im.height; y++) {
        sImage.set(y, x, im.get(im.width-x, y));
      }
    }

    im2.loadPixels();
    for (int x=0; x<im2.width; x++) {
      for (int y=0; y<im2.height; y++) {
        sImage.set(y, im2.width+x, im2.get(x, im2.height-y));
      }
    }


    sImage.updatePixels();
    sImage.save("data/grab.png");
  }
  void saveGrab() {
    PImage section =  camLeft.get(grabX, grabY, grabWidth, grabHeight);//createImage(grabWidth, grabHeight, RGB);
    PImage section2 =  camRight.get(grabX, grabY, grabWidth, grabHeight);//createImage(grabWidth, grabHeight, RGB);

    //section.save("data/grab.png");

    if (runStereoCam) {
      rotateAndSaveImageDouble(section, section2);
    } else {
      rotateAndSaveImage(section);
    }
  }
}