class Manager {
  boolean inBookPresentMode = false;
  boolean inBookJustEnteredMode = false;
  boolean inBookStartedAnalysisMode = false;
  boolean inAmbientMode = true;
  boolean showHOCR =true;
  boolean showTFIDF =false;
  int timeTillScan = 8;
  long startTime = 0;
  float currentHue;
  int direction = 1;
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
      drawAIText();
    } else if (inAmbientMode) {
      drawAmbient();
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
    color currentColour = color(fromHue,fromSaturation, currentHue);
    
    background(currentColour);
    currentHue+=(direction*rate);
    
    if(currentHue>= max(fromBrightness,toHue) || currentHue<= min(fromBrightness,toHue) ){
      direction*=-1;
    }
    println("throbbing",currentHue);
    popStyle();
  }
  void drawAmbient() {
    //throb(color(0),1);
    String amb = "AMBIENT SCREEN";
    text(amb, (width/2)-(0.5*textWidth(amb)), height/2);
  }
  void drawCountDown(String message, int countLimit) {
    //String amb = "AMBIENT SCREEN";
    //text(amb, (width/2)+(0.5*textWidth(amb)), height/2);

    String timeToScan = message+str(countLimit- (int(millis()- startTime   )/1000));
    text(timeToScan, (width/2)-(0.5*textWidth(timeToScan)), height/2);
  }

  void processMessage(String addrPattern) {
    println("got osc", addrPattern);
    if (addrPattern.equals("/go")) {
      makeNewText();

      println("received in analysis");
      // tfidfResult = processTFIDF();
      //boxes = getWordBoxesFromHOCR(hocrPath);
      //showHOCR = true;
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

  void drawAIText() {
    textFont(bodyFont, bodyFontSize);
    if (words!=null) {
      // text(aiText,xBorder,yBorder, width-xBorder,height);
      if (words.length>0) {
        words[0].update();
        words[0].display();
        //  println(words.length);

        for (int i=1; i<words.length; i++) {
          if (words[i-1].hasFadedIn) {
            latestFadedWordIndex = i;

            words[i].update();
            words[i].display();
          }
        }
      }
    }
  }
}