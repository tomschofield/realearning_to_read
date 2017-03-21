class Manager {
  boolean inBookPresentMode = false;
  boolean inBookJustEnteredMode = false;
  boolean inBookStartedAnalysisMode = false;
  boolean inAmbientMode = true;
  boolean showHOCR =true;
  boolean showTFIDF =false;
  int timeTillScan = 8;
  long startTime = 0;
  Manager() {
  }
  void update() {
    if (inBookPresentMode) {
    }
  }
  void display() {
    if (inBookJustEnteredMode) {
      drawCountDown("SCANNING IN: ", 8);
    } else if (inBookStartedAnalysisMode) {
      drawCountDown("BOOK PROCESSED IN: ", 150);
    } else if (inBookPresentMode) {
      if (showHOCR) {

        //TODO work out proper ratio

        PVector xDimensions = getHOCRXDimensions(boxes);
        PVector yDimensions = getHOCRYDimensions(boxes);
        float hocrWidth = xDimensions.y-xDimensions.x;        
        float hocrHeight = yDimensions.y-yDimensions.x;        

        float ratio =  (width-200)/hocrWidth;     
        ;//float(width)/float(height);

        println(ratio, yDimensions, xDimensions);
        textFont(bodyFont, bodyFontSize);
        if (boxes.length>0) {
          if (!boxes[boxes.length-1].hasFadedIn) {
            drawHOCR(xDimensions.x, xDimensions.y, yDimensions.x, yDimensions.y, ratio, 100, 0);
          } else {
            showHOCR=false;
            showTFIDF=true;
          }
        }
      } else if (showTFIDF) {
        drawTFIDF();
      }
    } else if (inAmbientMode) {
      drawAmbient();
    }
  }
  void processMessage(String addrPattern) {
    println("got osc", addrPattern);
    if (addrPattern.equals("/go")) {

      println("received in analysis");
      tfidfResult = processTFIDF();
      boxes = getWordBoxesFromHOCR(hocrPath);
      showHOCR = true;
      inBookJustEnteredMode = false;
      inBookPresentMode  = true;
      inAmbientMode = false;
      inBookStartedAnalysisMode = false;
    } else if (addrPattern.equals("/startedanalysis")) {

      if (!inBookStartedAnalysisMode) startTime = millis();
      inBookJustEnteredMode = false;
      inAmbientMode = false; 
      inBookPresentMode  = false;
      inBookStartedAnalysisMode = true;
    } else if (addrPattern.equals("/ambient")) {
      inBookPresentMode  = false;
      inBookJustEnteredMode = false;
      inAmbientMode = true;
      inBookStartedAnalysisMode = false;
    } else if (addrPattern.equals("/justentered")) {
      if (!inBookJustEnteredMode) startTime = millis();
      inBookJustEnteredMode = true;
      inBookPresentMode  = false;  
      inAmbientMode = false;
      inBookStartedAnalysisMode = false;
    }
  }
  void drawAmbient() {
    String amb = "AMBIENT SCREEN";
    fill(0);
    text(amb, (width/2)-(0.5*textWidth(amb)), height/2);
  }
  void drawCountDown(String message, int countLimit) {
    //String amb = "AMBIENT SCREEN";
    //text(amb, (width/2)+(0.5*textWidth(amb)), height/2);
    fill(0);
    String timeToScan = message+str(countLimit- (int(millis()- startTime   )/1000));
    text(timeToScan, (width/2)-(0.5*textWidth(timeToScan)), height/2);
  }
  void drawTFIDF() {
    float spacing = height/(tfidfResult.length+2);
    for (int i=0; i<tfidfResult.length; i++) {


      if (i>0) {
        if (tfidfResult[i-1].hasFadedIn) {
          tfidfResult[i].update();
        }
      } else {
        tfidfResult[i].update();
      }
      tfidfResult[i].display(width/2, spacing +(i*spacing));
    }
  }
  PVector getHOCRXDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minX = 100000000;
    float maxX = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.x < minX) {
        minX = box.x;
      } else if (box.x > maxX ) {
        maxX = box.x;
      }
    }
    dimensions.x = minX;
    dimensions.y = maxX;
    return dimensions;
  }
  PVector getHOCRYDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minY = 100000000;
    float maxY = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.y < minY) {
        minY = box.y;
      } else if (box.y > maxY ) {
        maxY = box.y;
      }
    }

    dimensions.x = minY;
    dimensions.y = maxY;

    return dimensions;
  }
  PVector getHOCRBoxWidthDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minW = 100000000;
    float maxW = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.w < minW) {
        minW = box.w;
      } else if (box.w > maxW ) {
        maxW = box.w;
      }
    }

    dimensions.x = minW;
    dimensions.y = maxW;

    return dimensions;
  }
  PVector getHOCRBoxHeightDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minH = 100000000;
    float maxH = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.h < minH) {
        minH = box.h;
      } else if (box.h > maxH ) {
        maxH = box.h;
      }
    }
    dimensions.x = minH;
    dimensions.y = maxH;
    return dimensions;
  }

  void drawHOCR(float xMin, float xMax, float yMin, float yMax, float ratio, int offSetX, int offSetY) {
    //println("Drwaing hcr");
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      fill(0);
      noStroke();
      float thisX =map(box.x, xMin, xMax, offSetX, width -offSetX);  
      float thisY =  offSetY + (box.y*ratio); // map(box.y, 0, yMax*ratio, offSetY, (height*ratio)-offSetY ); 

      float thisW =box.w *ratio;//map(box.w, xMin, xMax, offSetX, width -offSetX); 
      float thisH =box.h*ratio;//map(box.h, yMin, yMax, offSetY, (height*ratio) ); 
      noFill();
      //stroke(0);
      if (i>0) {
        if (boxes[i-1].hasFadedIn) {
          boxes[i].update();
          stroke(0, boxes[i].alpha);
        }
      } else {
        boxes[i].update();
      }
      rect(thisX, thisY, thisW, thisH);
    }
  }
}