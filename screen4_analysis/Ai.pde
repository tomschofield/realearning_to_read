class Ai {
  String text="";
  int latestFadedWordIndex =-1;
  int platestFadedWordIndex = -1;
  boolean runLive = true;
  int xBorder  =  50;
  int yBorder  =  100;
  Word [] words;

  Ai() {
  }
  void loadTextThird() {
     pushStyle();
    textFont(bodyFont, bodyFontSize);
    latestFadedWordIndex=-1;
    text = join(loadStrings(rootPath+"/install_v1/scripts/aiText.txt"), " ");
     //println(text);
    if (text!=null) {
      String [] allwords = splitTokens(text, " ");
      if (allwords.length>0) {
        //  println("aitext,");

        int third = allwords.length/3;
        words = new Word [third];

        int inPoint;
        int outPoint;

        if (isCentreScreen) {
          inPoint = 0;
          outPoint = third;
        } else {
          if (isLeftScreen) {
            inPoint = third;
            outPoint = 2*third;
          } else {
            inPoint =( 2 * third);
            outPoint = allwords.length-1;
          }
        }
        //println(third, inPoint, outPoint);

        int x = xBorder;
        int y = yBorder+bodyFontSize;
        int wordIndex=  0;
        for (int i=inPoint; i<outPoint-1; i++) {
          words[wordIndex] = new Word(allwords[i], x, y); 
          x+=textWidth(allwords[i]+" ");
          if (x + textWidth(allwords[i+1])>width - xBorder) {
            y+=(bodyFontSize+10);
            x=xBorder;
          }
          wordIndex++;
        }
        if (words.length>0)  words[words.length-1] = new Word("last", 100000, 10000);
      }
    }
    popStyle();
  }
  void loadText() {
    pushStyle();
    textFont(bodyFont, bodyFontSize);

    latestFadedWordIndex=-1;
    text = join(loadStrings(rootPath+"/install_v1/scripts/aiText.txt"), " ");
    if (text!=null) {
      String [] allwords = splitTokens(text, " ");
      if (allwords.length>0) {
        //  println("aitext,");
        words = new Word [allwords.length];

        int x = xBorder;
        int y = yBorder+bodyFontSize;

        for (int i=0; i<words.length-1; i++) {
          words[i] = new Word(allwords[i], x, y); 
          x+=textWidth(allwords[i]+" ");
          if (x + textWidth(allwords[i+1])>width - xBorder) {
            y+=(bodyFontSize+10);
            x=xBorder;
          }
        }
        if (words.length>0)  words[words.length-1] = new Word("last", 100000, 10000);
      }
    }
    popStyle();
  }
  void makeNewText() {
     pushStyle();
    textFont(bodyFont, bodyFontSize);
    latestFadedWordIndex=-1;
    if (runLive) {
      try {
        //TO DO add argument for which script this is
        String bash  = "bash runinstallation.sh "+str(random(0, 1));
        String[] cmd = { "/bin/sh", "-c", bash};
        ProcessBuilder newProc = new ProcessBuilder(cmd);

        newProc.directory(new File("/Users/tomschofield/torch/torch-rnn"));
        newProc.inheritIO();
        Process openApps = newProc.start();
        openApps.waitFor();
      }
      catch(Exception e) {
        println(e);
      }
    }
    loadTextThird();
    //loadText();
    popStyle();
  }
  void display() {
    pushStyle();
    textFont(bodyFont, bodyFontSize);
    if (words!=null) {

      // text(aiText,xBorder,yBorder, width-xBorder,height);
      if (words.length>0) {
             //     println("displaying ambient",frameCount);

        words[0].update();
        words[0].display();
        //  println(words.length);

        for (int i=1; i<words.length; i++) {
          if (words[i-1]!=null) {
            if (words[i-1].hasFadedIn) {
              latestFadedWordIndex = i;

              words[i].update();
              words[i].display();
            }
          }
        }
      }
      if (latestFadedWordIndex>=0 && words.length>0 & isLeftScreen) {
        if (words[latestFadedWordIndex].y>=height) {
          makeNewText();
        }
      }
    }
    popStyle();
  }
}