import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import netP5.*; 
import oscP5.*; 
import processing.video.*; 
import java.io.*; 
import boofcv.processing.*; 
import rita.*; 
import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class screen2_reader extends PApplet {

/*
TO DO
 stop ai at the end of the page
 
 */










RiLexicon lexicon = new RiLexicon();

OscP5 oscP5;
Ai ai;

///handles webcams and marker detection
ScanManager scanManager;

ColorMask mask;

///basically a struct to hold hocr information
WordBox [] boxes;
///for messaging other apps
NetAddress analysisLocation, analysisLocation2;
PFont font;
PFont bodyFont;

PFont speedReaderFont;

PFont [] readerFonts;

int cameraId, sW, sH, fontSize, wpm, aphoWpm, aiPort, analysisPort, analysisPort2, titleFontSize, bodyFontSize;
int backgroundColour;
String fontName, rootPath, aiIp, analysisIp, appPathAI, appPathAnalysis, dataPathReader, scriptsPath, messagesFontName, bodyFontName, speedReaderFontName;
int wordInterval=0;
int aphoWordInterval = 0;

int messageIndex = 0;
///handles messaging, marker availability, modes etc
InteractionManager interactionManager;
SpeedReader reader;
SpeedReader aphoReader;

boolean runLive = true;
String [] words ={"This", "is", "too", "easy"};
Capture camLeft;
boolean isLeftScreen = false;
boolean isCentreScreen = true;
//TODO - shift the checking for stem to main app
//todo work out why the TFIDF sequence is continyeing instead of shifting to mask image on wing apps

public void setup() {
  //  size(1920, 1200);
  
  noCursor();

  //get settings from xml   - must go first
  loadSettings();
  ai = new Ai();
  ai.loadText();

  mask = new ColorMask();
  mask.makeMask(dataPathReader+"data/grab.png");
  mask.resetMask();
  //must go after loadsettings  - port etc comes from xml
  setupOSC();

  //uncomment to automate app opening
 // 
 
 openOtherApps();

  //my own speed reader takes an array of words and an interval in millis
  reader = new SpeedReader(words, wordInterval, true);
  aphoReader = new SpeedReader(words, aphoWordInterval, false);
  aphoReader.loadWords(rootPath+"install_v1/scripts/aphorisms.txt");
  //takes an applet eference and a grab size
  scanManager = new ScanManager(this, 1920, 1080);
  interactionManager = new InteractionManager();
}


public void draw() {
  background(backgroundColour);
  reader.update();

  scanManager.update();
  interactionManager.manage();
  interactionManager.display();
}

public void openOtherApps() {
  //println("opening ", appPathAI, appPathAnalysis);
  openApp(appPathAI);
  openApp(appPathAnalysis);
}

public void openApp(String appPath) {
  try {
    Process openApps = Runtime.getRuntime().exec("open "+appPath);

    openApps.waitFor();
  }
  catch(Exception e) {
    println(e);
  }
}


public void stop() {
} 

///wraps up the messaging functions
public void messageOtherScreens(String address) {
  OscMessage myMessage = new OscMessage(address);

  myMessage.add(messageIndex);
  oscP5.send(myMessage, analysisLocation2);
  oscP5.send(myMessage, analysisLocation);
}
public void messageOtherScreens(String address, int index) {
  OscMessage myMessage = new OscMessage(address);

  myMessage.add(index);
  oscP5.send(myMessage, analysisLocation2);
  oscP5.send(myMessage, analysisLocation);
}

///creates the remote addresses which are all on localhpst but with different ports at the mo
public void setupOSC() {
  oscP5 = new OscP5(this, 2233);

  analysisLocation2 = new NetAddress(aiIp, analysisPort2);
  analysisLocation = new NetAddress(analysisIp, analysisPort);
}
public void loadSettings() {
  XML xml;
  ///all apps share a common settings file
  xml = loadXML("../settings.xml");
  cameraId = xml.getChild("cameraID").getIntContent();
  sW = xml.getChild("screenWidth").getIntContent();
  sH = xml.getChild("screenHeight").getIntContent();
  fontSize = xml.getChild("fontSize").getIntContent();
  wpm = xml.getChild("wpm").getIntContent();
  aphoWpm = xml.getChild("aphoWpm").getIntContent();
  bodyFontSize= xml.getChild("bodyFontSize").getIntContent();


  int r = PApplet.parseInt(xml.getChild("backgroundColour").getString("r"));
  int g = PApplet.parseInt(xml.getChild("backgroundColour").getString("g"));
  int b = PApplet.parseInt(xml.getChild("backgroundColour").getString("b"));

  backgroundColour = color(r, g, b);

  aiPort = xml.getChild("aiPort").getIntContent();
  analysisPort= xml.getChild("analysisPort").getIntContent();
  analysisPort2= xml.getChild("analysisPortTwo").getIntContent();

  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");

  fontName = xml.getChild("fontName").getString("name");
  messagesFontName = xml.getChild("messagesFontName").getString("name");
  speedReaderFontName = xml.getChild("speedReaderFontName").getString("name");
  bodyFontName = xml.getChild("bodyFontName").getString("name");

  titleFontSize = xml.getChild("titleFontSize").getIntContent();

  appPathAI = xml.getChild("appPathAI").getString("name");
  appPathAnalysis = xml.getChild("appPathAnalysis").getString("name");
  dataPathReader = xml.getChild("dataPathReader").getString("name");
  rootPath = xml.getChild("rootPath").getString("name");

  scriptsPath = xml.getChild("scriptsPath").getString("name");

  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
  //speedReaderFont = createFont(speedReaderFontName, fontSize);

  readerFonts = new PFont [6];
  readerFonts[0] = createFont(rootPath+"install_v1/fonts/" +"TorqueraUltraLight.ttf", fontSize);
  readerFonts[1] = createFont(rootPath+"install_v1/fonts/" +"TorqueraLight.ttf", fontSize);
  readerFonts[2] = createFont(rootPath+"install_v1/fonts/" +"TorqueraMedium.ttf", fontSize);
  readerFonts[3] = createFont(rootPath+"install_v1/fonts/" +"TorqueraBold.ttf", fontSize);
  readerFonts[4] = createFont(rootPath+"install_v1/fonts/" +"TorqueraHeavy.ttf", fontSize);
  readerFonts[5] = createFont(rootPath+"install_v1/fonts/" +"TorqueraBlack.ttf", fontSize);

  speedReaderFont = createFont(rootPath+"install_v1/fonts/" +"TorqueraBlack.ttf", fontSize);

  font = loadFont(messagesFontName);
  //bodyFont = loadFont(bodyFontName);

  textFont(font, titleFontSize);

  wordInterval = 60000 /wpm;
  aphoWordInterval = 60000/ aphoWpm;
}


public String [] getWordsFromHOCR(String fname) {
  XML xml;
  ArrayList<String> words= new ArrayList<String>();

  xml = loadXML(fname);

  XML body = xml.getChild("body");
  XML page = body.getChild("div");


  XML [] paragraphs = page.getChildren();
  String titles = page.getString("title");
  //println(titles);

  //println(paragraphs.length);

  for (int i=0; i<paragraphs.length; i++) {
    XML [] areas = paragraphs[i].getChildren();
    for (int m=0; m<areas.length; m++) {
      XML [] lines = areas[m].getChildren();
      for (int j=0; j<lines.length; j++) {
        XML [] lwords = lines[j].getChildren();
        for (int k=0; k<lwords.length; k++) {
          XML word = lwords[k];
          //println("word", word);
          String word_literal = word.getContent();
          //eg 'bbox 124 911 276 975; x_wconf 81'
          if (word_literal.trim().length()>0) {
            //String title = word.getString("title");
            words.add(word_literal.trim());
          }
        }
      }
    }
  }
  String [] ws = words.toArray(new String[words.size()]);
  //println("got words inside function");
  //printArray(ws);
  if (ws==null) {
    ws= new String [4];
    ws[0]="COULDN'T";
    ws[1]="SCAN";
    ws[2]="YOUR";
    ws[3]="BOOK";
  }

  if (ws.length<4) {
    ws= new String [4];
    ws[0]="COULDN'T";
    ws[1]="SCAN";
    ws[2]="YOUR";
    ws[3]="BOOK";
  }
  for (int i=0; i<ws.length; i++) {
    if (ws[i]==null) {
      ws[i]="";
    }
  }
  return ws;
}
class Ai {
  String text="";
  int latestFadedWordIndex =-1;
  int platestFadedWordIndex = -1;
  boolean runLive = true;
  int xBorder  =  10;
  int yBorder  =  10;
  Word [] words;

  Ai() {
  }
  public void loadText() {
    latestFadedWordIndex =-1;
    text = join(loadStrings(rootPath+"/install_v1/scripts/aiText.txt"), " ");

    if (text!=null) {
      String [] allwords = splitTokens(text, " ");
      if (allwords.length>0) {
        //println("aitext,");
        words = new Word [allwords.length];

        int x = xBorder;
        int y = yBorder+fontSize;

        for (int i=0; i<words.length-1; i++) {
          words[i] = new Word(allwords[i], x, y); 
          x+=textWidth(allwords[i]+" ");
          if (x + textWidth(allwords[i+1])>width - xBorder) {
            y+=(fontSize+10);
            x=xBorder;
          }
        }
        if (words.length>0)  words[words.length-1] = new Word("last", 100000, 10000);
      }
    }
  }
  public void makeNewText() {
    latestFadedWordIndex =-1;
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

    loadText();
  }
  public void display() {
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
class WordBox {
  //int topLeftX;
  //int topLeftY;
  //int bottomRightX;
  //int bottomRightY;
  String word;
  float conf;
  float x, y, w, h, x_n, y_n, w_n, h_n ;
  String title;

  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title ) {
    x = PApplet.parseFloat(_topLeftX) ;
    y = PApplet.parseFloat(_topLeftY);
    w = PApplet.parseFloat(_bottomRightX - _topLeftX);
    h = PApplet.parseFloat(_bottomRightY - _topLeftY);
    word = _word;
    conf = _conf/100;
    title = _title;
    float ratio = 300/72;
    x_n = x/ratio;
    y_n = y/ratio;
    w_n = w/ratio;
    h_n = h/ratio;
  }
  public void displayBox(){
    
  }
}
class ColorMask {
  PImage target;
  int [][] grid;
  int [][] ugrid;
  int [][] dgrid;
  float numFadeInFrames = 500;
  int numFadeOutFrames = 400;
  long startTime = 0;
  long fadeInDuration = 5000;
  long fadeOutDuration = 5000;

  boolean hasFinished = false;
  float inCount = 0;
  float ratio = 0.9f;
  boolean loaded = false;
  ColorMask() {
  }
  public void makeMask(String path) {
    PImage source= loadImage(path);
    grid  = getColourMask(source);
    loaded = true;
  }
  public void startMaskCounter() {
    inCount = 0;
    startTime = millis();
  }
  public void resetMask() {

    hasFinished = false;
    loaded = false;
  }
  public void display() {
   // println("millis() - startTime", millis() - startTime);
    if (millis() - startTime < fadeInDuration) {
      fadeInGridRandomness(grid, millis() - startTime, fadeInDuration);
   //   println("fading in:");
    } else if (millis() - startTime >= fadeInDuration &&  millis() - startTime < fadeInDuration + fadeOutDuration ) {
      drawGrid(grid);
    //  println("drawing grid:");
    } else {
      hasFinished = true;
    //  println("finished:");
    }
    //inCount++;
  }
  public void displayFrames() {

    if (inCount<numFadeInFrames) {
      fadeInGridRandomness(grid, inCount, numFadeInFrames);
    } else if (inCount > numFadeInFrames + numFadeOutFrames ) {
      drawGrid(grid);
    } else {
      hasFinished = true;
    }
    inCount++;
  }

  public void fadeInGridRandomness(int [][] grid, float inCount, float numFadeInFrames) {
    pushStyle();
    noStroke();
    int fadFromColour = color (255);
    float ratio = 0.9f;
    float xSpace = width/grid.length;
    float ySpace = height/grid[0].length;
    for (int i=0; i<grid.length; i++) {
      for (int j=0; j<grid[i].length; j++) {
        int c = grid[i][j];
        float redDifference = red(c)-red(fadFromColour);
        float greenDifference = green(c)-green(fadFromColour);
        float blueDifference = blue(c)-blue(fadFromColour);

        float nr = red(fadFromColour) + ( ((ratio * redDifference) +  ( (1-ratio)*random(redDifference))) * (inCount/numFadeInFrames));
        float ng = green(fadFromColour) + ( ((ratio * greenDifference) +  ( (1-ratio)*random(greenDifference))) * (inCount/numFadeInFrames));
        float nb = blue(fadFromColour) + ( ((ratio * blueDifference) +  ( (1-ratio)*random(blueDifference))) * (inCount/numFadeInFrames));

        int nc = color(nr, ng, nb);
        fill(nc);
        rect(i * xSpace, j *ySpace, xSpace, ySpace);
      }
    }
    popStyle();
  }
  public void drawGrid(int [][] grid) {
    pushStyle();
    noStroke();
    float xSpace = width/grid.length;
    float ySpace = height/grid[0].length;
    for (int i=0; i<grid.length; i++) {
      for (int j=0; j<grid[i].length; j++) {
        int c = grid[i][j];

        fill(c);
        rect(i * xSpace, j *ySpace, xSpace, ySpace);
      }
    }
    popStyle();
  }
  public int [][] getColourMask(PImage im) {
    float ratio = PApplet.parseFloat(height)/PApplet.parseFloat(width);
    int w = 50;
    int h  =PApplet.parseInt( w*ratio);

    int [][] grid = new int[w][h];
    PImage mask;

    if (isLeftScreen) {
      mask = im.get( PApplet.parseInt( im.width/4)-(w/2), PApplet.parseInt(im.height/4)-(h/2), w, h);
    } else if (isCentreScreen) {
      mask = im.get( PApplet.parseInt( im.width/4)-(w/2), PApplet.parseInt(im.height/2)-(h/2), w, h);
    } else {
      mask = im.get( PApplet.parseInt( im.width/4)-(w/2), PApplet.parseInt(im.height/3)-(h/2), w, h);
    }
    mask.loadPixels();
    int randQuantity = 200;
    int x = 0;
    int y= 0;
    int t1 = 50;
    int t2 = 60;
    for (int i=0; i<mask.pixels.length; i++) {
      float brightness =brightness(mask.pixels[i]);
      if (brightness<t1) {
        grid[x][y]=color(0);
        //  grid[x][y]+=random(randQuantity);
      } else if (brightness>=t1 && brightness <t2) {
        grid[x][y]=color(255, 0, 0);
        //  grid[x][y]+=random(randQuantity);
      } else {
        grid[x][y]=color(18, 250, 201);
        //   grid[x][y]+=random(randQuantity);
      }
      x++;
      if (x>=mask.width) {
        x=0;
        y++;
      }
    }

    //    PImage mask = im.get(  1500,1500,400,400);

    //createImage(width,height,RGB);

    return grid;
  }
}
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

  public void manage() {
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

  public void display() {
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
  public void displayScans() {
    scanManager.drawLeft(0, 0, scanManager.camsWidth, scanManager.camsHeight);
    scanManager.drawRight(width/2, 0, scanManager.camsWidth, scanManager.camsHeight);
  }
  public void dispRotatedScans() {
    pushMatrix();

    translate(width/2, height/2);
    rotate(-0.5f*PI);
    translate(-width/2, -height/2);
    translate(0, height/2);
    scanManager.drawLeft(0, 0, scanManager.camsWidth, scanManager.camsHeight);

    popMatrix();
    pushMatrix();
    translate(width/2, height/2);
    rotate(0.5f*PI);
    translate(-width/2, -height/2);
    translate(0, height/2);
    //scanManager.drawRight(width/2, 0, scanManager.camsWidth, scanManager.camsHeight);
    scanManager.drawRight(0, 0, scanManager.camsWidth, scanManager.camsHeight);

    popMatrix();
  }
  public void displayAnalysisReadySequence() {
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


  public void displayBookEnteredSequence() {
    dispRotatedScans(); 
    pushMatrix();
    //text("PREPARING TO SCAN", 200, 200);
    textFont(speedReaderFont, fontSize/2);
    fill(0);
    int time = PApplet.parseInt( (millis() - bookEnteredTime)/1000); 
    String displayText;
    if (PApplet.parseInt(timeBeforeAnalysis/1000)-time <= 1) {
      displayText = "SCANNING";
    } else {
      displayText = "SCANNING IN: " +str( PApplet.parseInt(timeBeforeAnalysis/1000)-time);
    }
    text(displayText, (width/2)-(0.5f*textWidth(displayText) ), height/2 );
    popMatrix();
  }
  //launches imagemagick script and then tesseract
  public void processOCR() {
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
  public String cleanText(String text) {
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
  public boolean isValidWord(String word) {
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
  public String removePunctuation(String s) {
    String res = "";
    for (Character c : s.toCharArray()) {
      if (Character.isLetterOrDigit(c))
        res += c;
    }
    return res;
  }
}
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


    detector = Boof.fiducialSquareBinaryRobust(0.1f);

    detector.guessCrappyIntrinsic(camsWidth, camsHeight);
  }

  public int findLogitechNumber(String [] cameras) {
    // String [] logitechs = new String[2];
    int logitechNumber = 1;
    // int index = 0;
    for (int i=0; i<cameras.length; i++) {
     // println("cameras[i].substring(0, 18)", cameras[i].substring(0, 25));
      if (cameras[i].substring(0, 25).trim().equals("name=HD Pro Webcam C920 #")) {
       // println("Found one", cameras[i].substring(25, 26));
        logitechNumber = PApplet.parseInt(cameras[i].substring(25, 26));
      }
    }
    return logitechNumber;
  }
  public void stopCams() {
    camsActive = false;
    camLeft.stop();
    camRight.stop();
  }
  public void startCams() {
    
    if (!camsActive) {
      camsActive = true;
      camLeft.start();
      camRight.start();
    }
  }
  public void update() {

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
  public boolean foundBook() {
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
  public void drawLeft(int x, int y, int w, int h) {

    image(camLeft, x, y, w, h);

    //image(camLeft, 0, 0, width, height);
  }

  public void drawRight(int x, int y, int w, int h) {
    if (runStereoCam) {
      image(camRight, x, y, w, h);
    }
  }

  public void drawBoth() {
    drawLeft(0, 0, camsWidth, camsHeight);
    drawRight(width/2, 0, camsWidth, camsHeight);
  }
  public void rotateAndSaveImage(PImage im) {

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
  public void rotateAndSaveImageDouble(PImage im, PImage im2) {

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
  public void rotateAndSaveImageDoubleStacked(PImage im, PImage im2) {

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
  public void saveGrab() {
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
class SpeedReader {
  float wpm = 250;
  float wordInterval;
  long startTime = 0;
  int wordIndex = 0;  
  String [] words;
  int fontIndex = 0;
  int fontChangeSpeed = 1;
  int cycle = 0;
  boolean isCycleLimited;
  float initWordInterval;
  SpeedReader(String [] _words, float _wordInterval, boolean _isCycleLimited) {
    words = _words;
    isCycleLimited = _isCycleLimited;
    wordInterval = _wordInterval;
    initWordInterval = _wordInterval;
    startTime=millis();
  }
  public void loadWords(String [] _words) {
    words = _words;
    cycle = 0;
  }
  public void loadWords(String path) {
    words = splitTokens(join(loadStrings(path), " "), " ");
    cycle = 0;
  }
  public void reset() {
    cycle = 0;
  }
  public void update() {
    if (isCycleLimited) {
      if (cycle==0) {
        wordInterval = initWordInterval;
      } else {
        wordInterval = 4  * initWordInterval;
      }
    }
    if (millis()-wordInterval>=startTime) {
      startTime=millis();
      //if (go) {

      if (isCycleLimited) {
        if (cycle<2) {
          wordIndex++;
          messageOtherScreens("/speedreader", wordIndex);
        }
        if (wordIndex>=words.length) {
          wordIndex=0;
          cycle++;
        }
      } else {

        wordIndex++;
        messageOtherScreens("/speedreader", wordIndex);
        if (wordIndex>=words.length) {
          wordIndex=0;
        }
      }
    }
  }

  public void display() {
    pushMatrix();
    pushStyle();
    colorMode(RGB);

    if (fontIndex>=0 && fontIndex<readerFonts.length) textFont(readerFonts[fontIndex]);
    //textFont(speedReaderFont);

    fontIndex+=fontChangeSpeed;
    if (fontIndex>=readerFonts.length-1 || fontIndex <=0) {
      fontChangeSpeed*=-1;
    }
    String thisWord ="";
    
    if(words!=null){
     if(words.length>0){
      thisWord = trim(words[wordIndex].toUpperCase());
      
     }
    }
    int centralCharIndex = getCentralCharIndex(thisWord);
    String centralChar = getCentralChar(thisWord);

    float offset = 0;
    for (int i=0; i<centralCharIndex; i++) {
      offset+=textWidth(str(thisWord.charAt(i)));
    }
    if (thisWord.length()>1) {
      offset+= 0.5f *(textWidth(str(thisWord.charAt(centralCharIndex))));
    }
    // textFont(font);
    translate( (width/2)-offset, height/2);
    fill(0, 255, 0);

    float xPos = 0;


    for (int i=0; i<thisWord.length (); i++) {
      if (i==getCentralCharIndex(thisWord)) {
        fill(255, 0, 0);
      } else {
        fill(0);
      }
      text(str(thisWord.charAt(i)), xPos, 0     );


      xPos+=textWidth(str(thisWord.charAt(i)));
    }
    popStyle();
    popMatrix();
  }

  public void displayAnimated() {
    pushMatrix();
    pushStyle();
    colorMode(RGB);
    textFont(speedReaderFont);
    String thisWord = trim(words[wordIndex].toUpperCase());
    int centralCharIndex = getCentralCharIndex(thisWord);
    String centralChar = getCentralChar(thisWord);

    float offset = 0;
    for (int i=0; i<centralCharIndex; i++) {
      offset+=textWidth(str(thisWord.charAt(i)));
    }
    if (thisWord.length()>1) {
      offset+= 0.5f *(textWidth(str(thisWord.charAt(centralCharIndex))));
    }
    // textFont(font);
    translate( (width/2)-offset, height/2);
    fill(0, 255, 0);

    float xPos = 0;


    for (int i=0; i<thisWord.length (); i++) {
      if (i==getCentralCharIndex(thisWord)) {
        fill(255, 0, 0);
      } else {
        fill(0);
      }
      text(str(thisWord.charAt(i)), xPos, 0     );


      xPos+=textWidth(str(thisWord.charAt(i)));
    }
    popStyle();
    popMatrix();
  }
  public float getCentralCharPos(String word) {

    int numChars = word.length();
    int centralCharIndex =PApplet.parseInt( numChars/2.0f);
    float fCentralCharIndex = numChars/2.0f;
    float centralCharPos = 0.0f;
    String centralChar="";


    if (numChars>2) {
      if (fCentralCharIndex - centralCharIndex>0) {

        centralChar = str( word.charAt(centralCharIndex)  );
      } else {
        centralChar = str( word.charAt(centralCharIndex)  );
      }
    } else {
      centralChar =  str( word.charAt(0)  );
      centralCharIndex = 0;
    }

    String sub = word.substring(centralCharIndex);
    float sWidth = textWidth(sub);
    return sWidth;
  }
  public String getCentralChar(String word) {

    int numChars = word.length();
    int centralCharIndex =PApplet.parseInt( numChars/2.0f);
    float fCentralCharIndex = numChars/2.0f;
    float centralCharPos = 0.0f;
    String centralChar="";


    if (numChars>2) {
      if (fCentralCharIndex - centralCharIndex>0) {

        centralChar = str( word.charAt(centralCharIndex)  );
      } else {
        centralChar = str( word.charAt(centralCharIndex)  );
      }
    } else {
      centralChar =  str( word.charAt(0)  );
      centralCharIndex = 0;
    }

    String sub = word.substring(centralCharIndex);
    float sWidth = textWidth(sub);
    return centralChar;
  }
  public int getCentralCharIndex(String word) {

    int numChars = word.length();
    int centralCharIndex =PApplet.parseInt( numChars/2.0f);
    float fCentralCharIndex = numChars/2.0f;
    float centralCharPos = 0.0f;
    String centralChar="";


    if (numChars>2) {
      if (fCentralCharIndex - centralCharIndex>0) {
        //centralCharIndex++;
        centralChar = str( word.charAt(centralCharIndex)  );
      } else {
        centralChar = str( word.charAt(centralCharIndex)  );
      }
    } else {
      centralChar =  str( word.charAt(0)  );
      centralCharIndex = 1;
    }

    String sub = word.substring(centralCharIndex);
    float sWidth = textWidth(sub);
    return centralCharIndex;
  }
}
class Word {
  String theword;
  boolean hasFadedIn;
  int alpha, x, y;
  Word(String _theword, int _x, int _y) {
    hasFadedIn = false;
    theword = _theword;
    alpha = 0;
    x = _x;
    y = _y;
  }

  public void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
  public void display() {
    fill(0, alpha);
    text(theword, x, y);
  }
}
  public void settings() {  fullScreen(3); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--hide-stop", "screen2_reader" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
