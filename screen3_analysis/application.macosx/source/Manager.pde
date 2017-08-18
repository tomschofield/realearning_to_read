class Manager {
  //boolean inBookPresentMode = true;
  //boolean inBookJustEnteredMode = false;
  //boolean inBookStartedAnalysisMode = false;
  //boolean inAmbientMode = false;
  //boolean showHOCR =true;
  //boolean showTFIDF =false;
  //boolean showMask =false;

  //

  boolean inBookPresentMode = false;
  boolean inBookJustEnteredMode = false;
  boolean inBookStartedAnalysisMode = false;
  boolean inAmbientMode = true;
  boolean showHOCR =true;
  boolean showTFIDF =false;
  boolean showMask =false;

  int timeTillScan = 8;
  long startTime = 0;
  float currentHue;
  int direction = 1;

  float fontIndex = 0;
  float fontChangeSpeed = 0.2;

  int currentWordIndex=0;
  PFont currentFont;

  Manager(PFont defaultFont) {
    currentFont = defaultFont;
  }

  void update() {
    if (inBookPresentMode) {
    }
  }
  void display() {
    if (fontIndex>=0 && fontIndex<readerFonts.length) {

      currentFont = readerFonts[int(fontIndex)];
    }
    //textFont(speedReaderFont);

    fontIndex+=fontChangeSpeed;
    if (fontIndex>=readerFonts.length-1 || fontIndex <=0) {
      fontChangeSpeed*=-1;
    }

    if (inBookJustEnteredMode) {

      drawCountDown("SCANNING IN: ", "SCANNING IN: 8", 8, speedReaderFont, fontSize/2, -30);
    } else if (inBookStartedAnalysisMode) {

      drawCountDown("", "22", 35, currentFont, 550, 120);
      // drawSpeedReader();
    } else if (inBookPresentMode) {
      if (showHOCR) {

        //TODO work out proper ratio

        PVector xDimensions = getHOCRXDimensions(boxes);
        PVector yDimensions = getHOCRYDimensions(boxes);
        float hocrWidth = xDimensions.y-xDimensions.x;        
        float hocrHeight = yDimensions.y-yDimensions.x;        

        float ratio =  (width-200)/hocrWidth;     
        //float(width)/float(height);

        // println(ratio, yDimensions, xDimensions);
        textFont(bodyFont, bodyFontSize);



        if (boxes.length>0) {

          //if we haven't finished drawing boxes
          //if (!boxes[boxes.length-1].hasFadedIn) {
          // println("word indices",currentWordIndex,totalBoxesLength);
          if (currentWordIndex<=totalBoxesLength && totalBoxesLength>0) {
            //  throb(color(0), 1);

            drawHOCR(xDimensions.x, xDimensions.y, yDimensions.x, yDimensions.y, ratio, 100, 0);
          } else {
            // println("hcor false");
            showHOCR=false;
            showMask = false;
            wordInterval *= 0.5;
            showTFIDF=true;
          }
        }
      } else if (showTFIDF) {
        String currentWord =  getCurrentWordAllWords();

        drawTFIDF(currentWord);
      } else if (showMask) {
        drawMask();
      }
    } else if (inAmbientMode) {
      drawAmbient();
    }
  }
  void drawMask() {
    mask.display();
  }
  void drawSpeedReader() {
    reader.update();
    reader.display();
  }
  void processMessage(OscMessage theOscMessage ) {

    String addrPattern = theOscMessage.addrPattern();

    //println("got osc", addrPattern);
    if (addrPattern.equals("/go")) {

      // println("received in analysis");
      tfidfResult = processTFIDF();
      boxes = getWordHalfBoxesFromHOCR(hocrPath, isLeftScreen);
      allBoxes = getWordBoxesFromHOCR(hocrPath);
      showHOCR = true;
      showMask = false;
      showTFIDF = false;
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
      //println("ambient");
      inBookPresentMode  = false;
      inBookJustEnteredMode = false;

      inBookStartedAnalysisMode = false;
      if (!inAmbientMode) {
        ai.loadTextThird();
      }
      inAmbientMode = true;
    } else if (addrPattern.equals("/justentered")) {
      if (!inBookJustEnteredMode) startTime = millis();
      inBookJustEnteredMode = true;
      inBookPresentMode  = false;  
      inAmbientMode = false;
      inBookStartedAnalysisMode = false;
    } else if (addrPattern.equals("/speedreader")) {
      currentWordIndex = theOscMessage.get(0).intValue();
    } else if (addrPattern.equals("/mask")) {
      //println("show mask");
      showHOCR = false;
      showTFIDF = false;
      showMask = true;
      mask.resetMask();
      mask.makeMask(dataPathReader+"data/grab.png");
    }
  }
  void throb(color to, float rate) {
    float fromHue = hue(backgroundColour);
    colorMode(RGB);
    float fromSaturation = saturation(backgroundColour);
    float fromBrightness = brightness(backgroundColour);

    float toHue = brightness(to);
    pushStyle();
    colorMode(HSB);
    color currentColour = color(fromHue, fromSaturation, currentHue);

    background(currentColour);
    currentHue+=(direction*rate);

    if (currentHue>= max(fromBrightness, toHue) || currentHue<= min(fromBrightness, toHue) ) {
      direction*=-1;
    }
    // println("throbbing", currentHue);
    popStyle();
  }
  void drawAmbient() {
    //String amb = "AMBIENT SCREEN";
    //fill(0);
    //text(amb, (width/2)-(0.5*textWidth(amb)), height/2);
    ai.display();
  }
  void drawCountDown(String message, String widthSetMessage, int countLimit, PFont countDownFont, int fontSize, int yOffSet) {
    //String amb = "AMBIENT SCREEN";
    //text(amb, (width/2)+(0.5*textWidth(amb)), height/2);
    pushStyle();
    textFont(countDownFont, fontSize);
    fill(0);
    int currentCount = countLimit- (int(millis()- startTime   )/1000);
    if (currentCount < 0) currentCount = 0;
    String timeToScan = message+str(currentCount);
    text(timeToScan, (width/2)-(0.5*textWidth(widthSetMessage)), yOffSet+(height/2));
    popStyle();
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
  void drawTFIDF(String word) {
    pushStyle();
    textFont(speedReaderFont);
    String [] stems = getAllPossibleStems(removePunctuation(word.trim()));
    //printArray(stems);
    for (int i=0; i<tfidfResult.length; i++) {
      // println(word, tfidfResult[i].word);
      if (stringArrayContainsString(stems, tfidfResult[i].word.toLowerCase())) {
        //println("found", tfidfResult[i].word);
        for (int j=0; j<tfidfResult.length; j++) {
          tfidfResult[j].alpha =0;
        }
        tfidfResult[i].alpha = 255;
        tfidfResult[i].fullWord = word.trim().toUpperCase();
      }
      tfidfResult[i].updateAlpha();
      fill(0, tfidfResult[i].alpha);

      // text(word.toUpperCase(),(width/2) - (0.5*textWidth(word.toUpperCase())), height/2);
      tfidfResult[i].displayFullWord((width/2), height/2);
    }
    popStyle();
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
  String getCurrentWord() {
    String currentWord="";
    for (int i=0; i<boxes.length; i++) {
      if (boxes[i].index==currentWordIndex) {
        currentWord=boxes[i].word;
      }
    }
    return currentWord;
  }
  String getCurrentWordAllWords() {
    String currentWord="";
    for (int i=0; i<allBoxes.length; i++) {
      if (allBoxes[i].index==currentWordIndex) {
        currentWord=allBoxes[i].word;
      }
    }
    return currentWord;
  }

  void drawHOCR(float xMin, float xMax, float yMin, float yMax, float ratio, int offSetX, int offSetY) {
    //println("Drwaing hcr");
    for (int i=0; i<boxes.length; i++) {


      fill(0);
      noStroke();
      //float thisX =map(boxes[i].x, xMin, xMax, offSetX, width -offSetX);  
      //float thisY =  offSetY + (boxes[i].y*ratio); // map(box.y, 0, yMax*ratio, offSetY, (height*ratio)-offSetY ); 

      //float thisW =boxes[i].w *ratio;//map(box.w, xMin, xMax, offSetX, width -offSetX); 
      //float thisH =boxes[i].h*ratio;//map(box.h, yMin, yMax, offSetY, (height*ratio) ); 
      float thisX = boxes[i].x;
      float thisY = boxes[i].y;
      float thisW = boxes[i].w;
      float thisH = boxes[i].h;


      if (boxes[i].index==currentWordIndex) {
        boxes[i].updateAlpha();
        fill(255, 0, 0, boxes[i].alpha);
      } else {
        noFill();
        stroke(100, 100);
      }

      //stroke(0);
      //if (i>0) {
      //  if (boxes[i-1].hasFadedIn) {
      //    boxes[i].update();
      //    stroke(0, boxes[i].alpha);
      //  }
      //} else {
      //  boxes[i].update();
      //}
      rect(thisX, thisY, thisW, thisH);
    }
  }
  void drawHOCRSelfAnimated(float xMin, float xMax, float yMin, float yMax, float ratio, int offSetX, int offSetY) {
    //println("Drwaing hcr");
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      fill(0);
      noStroke();
      float thisX =map(box.x, xMin, xMax, offSetX, width -offSetX);  
      float thisY =  offSetY + (box.y*ratio); // map(box.y, 0, yMax*ratio, offSetY, (height*ratio)-offSetY ); 

      float thisW =box.w *ratio;//map(box.w, xMin, xMax, offSetX, width -offSetX); 
      float thisH =box.h*ratio;//map(box.h, yMin, yMax, offSetY, (height*ratio) ); 
      fill(255, 0, 0, boxes[i].alpha);
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