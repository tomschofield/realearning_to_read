/*
TO DO
 stop ai at the end of the page
 
 */


import netP5.*;
import oscP5.*;
import processing.video.*;
import java.io.*;
import boofcv.processing.*;
import rita.*;
import java.util.*;

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
color backgroundColour;
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

void setup() {
  //  size(1920, 1200);
  fullScreen(3);
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


void draw() {
  background(backgroundColour);
  reader.update();

  scanManager.update();
  interactionManager.manage();
  interactionManager.display();
}

void openOtherApps() {
  //println("opening ", appPathAI, appPathAnalysis);
  openApp(appPathAI);
  openApp(appPathAnalysis);
}

void openApp(String appPath) {
  try {
    Process openApps = Runtime.getRuntime().exec("open "+appPath);

    openApps.waitFor();
  }
  catch(Exception e) {
    println(e);
  }
}


void stop() {
} 

///wraps up the messaging functions
void messageOtherScreens(String address) {
  OscMessage myMessage = new OscMessage(address);

  myMessage.add(messageIndex);
  oscP5.send(myMessage, analysisLocation2);
  oscP5.send(myMessage, analysisLocation);
}
void messageOtherScreens(String address, int index) {
  OscMessage myMessage = new OscMessage(address);

  myMessage.add(index);
  oscP5.send(myMessage, analysisLocation2);
  oscP5.send(myMessage, analysisLocation);
}

///creates the remote addresses which are all on localhpst but with different ports at the mo
void setupOSC() {
  oscP5 = new OscP5(this, 2233);

  analysisLocation2 = new NetAddress(aiIp, analysisPort2);
  analysisLocation = new NetAddress(analysisIp, analysisPort);
}
void loadSettings() {
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


  int r = int(xml.getChild("backgroundColour").getString("r"));
  int g = int(xml.getChild("backgroundColour").getString("g"));
  int b = int(xml.getChild("backgroundColour").getString("b"));

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


String [] getWordsFromHOCR(String fname) {
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