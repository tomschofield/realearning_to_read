class InteractionManager {

  boolean bookJustEntered = false;
  boolean analysisFinished = false;
  boolean establishedBookPresence = false;
  boolean bookJustRemoved = false;
  boolean inAmbientMode = true;
  boolean finishedWholeSequence = false;
  //boolean  = true;
  long bookEnteredTime = 0;
  long timeBeforeAnalysis = 8 * 1000;
  long bookRemovedTime = 0;
  ///wait 5 minutes before displaying ambient stuff
  long timeBeforeAmbient = 3*1000;// 5 * 60 * 1000;
  boolean runLive = true;
  int readerCycle = 0;

  InteractionManager() {
  }

  void manage() {
    if (scanManager.assignedLeftAndRight) {

      //println("found book", scanManager.foundBook());
      //println("bookJustEntered; ", bookJustEntered);
      //println("establishedBookPresence; ", establishedBookPresence);
      //println("inAmbientMode; ", inAmbientMode);
      //println("bookJustRemoved; ", bookJustRemoved);
      //println();
      boolean noBook =false;

      if (inAmbientMode || bookJustRemoved ) noBook = true;

      if (scanManager.foundBook()  && noBook) {
        if (!finishedWholeSequence) {
          bookEnteredTime = millis();
          bookJustEntered = true;
          inAmbientMode = false;
          bookJustRemoved = false;
        }
      }



      //if this book went in recently 
      if (bookJustEntered && scanManager.foundBook() ) {
        messageOtherScreens("/justentered");
        if (millis() - bookEnteredTime >  timeBeforeAnalysis) {
          messageOtherScreens("/startedanalysis");
          establishedBookPresence = true;
          bookJustEntered = false;

          //now do the scanning
          //println("saving grab");
          if (runLive) {
            scanManager.saveGrab();
          }
          //scanManager.stopCams();

          //now process the OCR
          //println("processing OCR", hour(), ":", minute(), ":", second());
          processOCR();
          //println("processed OCR", hour(), ":", minute(), ":", second());
          reader.words = getWordsFromHOCR(dataPathReader+"hocrOutput.hocr");
          reader.reset();

          messageIndex++;
          messageOtherScreens("/go");
        }
      }
      if (!scanManager.foundBook()) {
        finishedWholeSequence = false;
        bookJustEntered = false;
        if (establishedBookPresence) {
          establishedBookPresence = false;
          bookJustRemoved = true;
          bookRemovedTime = millis();
        } else if (bookJustRemoved) {
          //println("book just removed but not timed out");
          if (millis()-bookRemovedTime > timeBeforeAmbient) {
            //println("book just removed and timed out");
            bookJustRemoved = false;
            inAmbientMode = true;
            //println("Making new Ai text", frameCount);
            ai.makeNewText();

            messageOtherScreens("/ambient");
          //  scanManager.startCams();
          }
        } else if (!establishedBookPresence && !bookJustRemoved) {
          //    println("in ambient mode");
          inAmbientMode = true;

          messageOtherScreens("/ambient");
        //  scanManager.startCams();
        } else {
          //println("hadn't thought of this, ", bookJustEntered, establishedBookPresence, bookJustRemoved, inAmbientMode);
        }
      }
    }
  }

  void display() {
    if (scanManager.assignedLeftAndRight) {
      if (bookJustEntered) {
        displayBookEnteredSequence();
      } else if (establishedBookPresence) {
        displayAnalysisReadySequence();
      } else if (bookJustRemoved) {
        displayAnalysisReadySequence();
      } else if (inAmbientMode) {
        //ai.display();
        aphoReader.update();
        aphoReader.display();
        //String amb = "AMBIENT SCREEN";
        //text(amb, (width/2)-(0.5*textWidth(amb)), height/2);
      }
    } else {
      displayScans();
    }
  }
  void displayScans() {
    scanManager.drawLeft(0, 0, scanManager.camsWidth, scanManager.camsHeight);
    scanManager.drawRight(width/2, 0, scanManager.camsWidth, scanManager.camsHeight);
  }
  void dispRotatedScans() {
    pushMatrix();

    translate(width/2, height/2);
    rotate(-0.5*PI);
    translate(-width/2, -height/2);
    translate(0, height/2);
    scanManager.drawLeft(0, 0, scanManager.camsWidth, scanManager.camsHeight);

    popMatrix();
    pushMatrix();
    translate(width/2, height/2);
    rotate(0.5*PI);
    translate(-width/2, -height/2);
    translate(0, height/2);
    //scanManager.drawRight(width/2, 0, scanManager.camsWidth, scanManager.camsHeight);
    scanManager.drawRight(0, 0, scanManager.camsWidth, scanManager.camsHeight);

    popMatrix();
  }
  void displayAnalysisReadySequence() {
    if (reader.cycle<2) {
      reader.display();
    } else if (reader.cycle==2) {
      //   println("reader cycle == 2");

      if (mask.hasFinished) {
        //println("mask has finished");
        //TODO TIME OUT UNTIL BOOK HAS BEEN TAKEN OUT
        inAmbientMode = true;
        //TODO THIS may not be the correct seuqnece
        establishedBookPresence = false;
        bookJustRemoved = false;
        mask.resetMask();
        finishedWholeSequence = true;
        //reader.cycle=3;
      //  scanManager.startCams();
      } else {
        if (!mask.loaded) {
          //delay(1000);
          //println("messaging other screen for mask");
          messageOtherScreens("/mask");
          mask.makeMask(dataPathReader+"data/grab.png");
          mask.startMaskCounter();
        }
        mask.display();
      }
    } else {
      println("reader cycle broken");
    }
  }


  void displayBookEnteredSequence() {
    dispRotatedScans(); 
    pushMatrix();
    //text("PREPARING TO SCAN", 200, 200);
    textFont(speedReaderFont, fontSize/2);
    fill(0);
    int time = int( (millis() - bookEnteredTime)/1000); 
    String displayText;
    if (int(timeBeforeAnalysis/1000)-time <= 1) {
      displayText = "SCANNING";
    } else {
      displayText = "SCANNING IN: " +str( int(timeBeforeAnalysis/1000)-time);
    }
    text(displayText, (width/2)-(0.5*textWidth(displayText) ), height/2 );
    popMatrix();
  }
  //launches imagemagick script and then tesseract
  void processOCR() {
    scanManager.camLeft.stop();
    scanManager.camRight.stop();
    //println("start time", hour(), ":", minute(), ":", second());
    try {
      boolean useFreds = true;
      if (useFreds && runLive) {
        String bash  ="bash "+dataPathReader+"data/clean.sh";

        String[] cmd = { "/bin/sh", "-c", bash};
        ProcessBuilder newProc = new ProcessBuilder(cmd);

        newProc.directory(new File(dataPathReader));
        newProc.inheritIO();
        Process openApps = newProc.start();
        openApps.waitFor();

        Process resize = Runtime.getRuntime().exec(cmd);

        resize.waitFor();
      } 
      //println("resized script finished", hour(), ":", minute(), ":", second());


      if (runLive) {
        Process tess = Runtime.getRuntime().exec("/usr/local/Cellar/tesseract/3.04.01_2/bin/tesseract "+dataPathReader+ "data/dense_grab.png "+dataPathReader+ "./hocrOutput -l eng hocr ");
        tess.waitFor();
        //println("ocr script finished");
      } else {
        //Process tess = Runtime.getRuntime().exec("/usr/local/Cellar/tesseract/3.04.01_2/bin/tesseract "+dataPathReader+ "data/dense_grab_bu.png "+dataPathReader+ "./hocrOutput -l eng hocr ");
        //tess.waitFor();
        //println("file ocr ready");
      }
      //println("finish time", hour(), ":", minute(), ":", second());
      scanManager.camLeft.start();
      scanManager.camRight.start();
      //now save plain text version
      String [] hocrWords = getWordsFromHOCR("/Users/tomschofield/Dropbox/readingreading/install_v1/screen2_reader/hocrOutput.hocr");
      String joined = join(hocrWords, " ");

      joined = cleanText(joined);

      PrintWriter output; 
      output = createWriter(scriptsPath+"atext.txt"); 
      output.print(joined);
      output.flush();  // Writes the remaining data to the file
      output.close();

      //now add plain text version with time stamp to store
      PrintWriter storeOutput; 
      Date d = new Date();
      long current=d.getTime()/1000;
      String timestamp = str(current);
      storeOutput = createWriter(scriptsPath+"store/atext_"+timestamp+".txt"); 
      storeOutput.print(joined);
      storeOutput.flush();  // Writes the remaining data to the file
      storeOutput.close();
    } 
    catch (Exception err) {
      err.printStackTrace();
    }

    //exit();
  }
  ///check each word against a dictionary after temporarily removing punctuation
  String cleanText(String text) {
    String clean="";
    String [] exploded = splitTokens(text, " ");
    for (int i=0; i<exploded.length; i++) {
      if (isValidWord(exploded[i])) {
        clean+=exploded[i];
        clean+=" ";
      }
    }
    return clean;
  }
  boolean isValidWord(String word) {
    boolean valid = false;
    String stem = RiTa.stem(word, RiTa.PORTER);
    if ( lexicon.containsWord(removePunctuation(stem)) ) {
      if (stem.length()>1 || stem.toLowerCase().equals("a") ||  stem.toLowerCase().equals("i") ) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
  //thanks to Nerzid at http://stackoverflow.com/questions/18830813/how-can-i-remove-punctuation-from-input-text-in-java
  String removePunctuation(String s) {
    String res = "";
    for (Character c : s.toCharArray()) {
      if (Character.isLetterOrDigit(c))
        res += c;
    }
    return res;
  }
}