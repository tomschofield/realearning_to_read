/*
TO DO
 ONE GRAB IS STILL UPSIDE DOWN!
 stop ai at the end of the page
 
 */


import netP5.*;
import oscP5.*;
import processing.video.*;
import java.io.*;
import boofcv.processing.*;
import java.util.*;
import rita.*;
import java.util.*;

RiLexicon lexicon = new RiLexicon();

OscP5 oscP5;

///handles webcams and marker detection
ScanManager scanManager;
///basically a struct to hold hocr information
WordBox [] boxes;
///for messaging other apps
NetAddress aiLocation, analysisLocation;
PFont font;

int cameraId, sW, sH, fontSize, wpm, aiPort, analysisPort, titleFontSize;
color backgroundColour;
String fontName, aiIp, analysisIp, appPathAI, appPathAnalysis, dataPathReader, scriptsPath, messagesFontName;
int wordInterval=0;

int messageIndex = 0;
///handles messaging, marker availability, modes etc
InteractionManager interactionManager;
SpeedReader reader;
boolean runLive = true;
String [] words ={"This", "is", "too", "easy"};
Capture camLeft;


void setup() {
 // size(1920, 1200);
  fullScreen(4);

  //get settings from xml  
  loadSettings();

  //must go after loadsettings  - port etc comes from xml
  setupOSC();
  
  //uncomment to automate app opening
  // openOtherApps();

  //my own speed reader takes an array of words and an interval in millis
  reader = new SpeedReader(words, wordInterval);
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
  println("opening ", appPathAI, appPathAnalysis);
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
  oscP5.send(myMessage, aiLocation);
  oscP5.send(myMessage, analysisLocation);
}

///creates the remote addresses which are all on localhpst but with different ports at the mo
void setupOSC() {
  oscP5 = new OscP5(this, 2233);

  aiLocation = new NetAddress(aiIp, aiPort);
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


  int r = int(xml.getChild("backgroundColour").getString("r"));
  int g = int(xml.getChild("backgroundColour").getString("g"));
  int b = int(xml.getChild("backgroundColour").getString("b"));
  
  backgroundColour = color(r, g, b);

  aiPort = xml.getChild("aiPort").getIntContent();
  analysisPort= xml.getChild("analysisPort").getIntContent();

  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");

  fontName = xml.getChild("fontName").getString("name");
  messagesFontName = xml.getChild("messagesFontName").getString("name");

  titleFontSize = xml.getChild("titleFontSize").getIntContent();

  appPathAI = xml.getChild("appPathAI").getString("name");
  appPathAnalysis = xml.getChild("appPathAnalysis").getString("name");
  dataPathReader = xml.getChild("dataPathReader").getString("name");

  scriptsPath = xml.getChild("scriptsPath").getString("name");
  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
 
  font = loadFont(messagesFontName);
  textFont(font, titleFontSize);

  wordInterval = 60000 /wpm;
}

//parses Tesseract hocr output to get bounding box info 
//WordBox [] getWordBoxesFromHOCR(String fname) {
//  XML xml;
//  ArrayList<WordBox> wordboxes= new ArrayList<WordBox>();

//  xml = loadXML(fname);

//  XML body = xml.getChild("body");
//  XML page = body.getChild("div");


//  XML [] paragraphs = page.getChildren();
//  String titles = page.getString("title");
//  //println(titles);

//  //println(paragraphs.length);

//  for (int i=0; i<paragraphs.length; i++) {
//    XML [] areas = paragraphs[i].getChildren();
//    for (int m=0; m<areas.length; m++) {
//      XML [] lines = areas[m].getChildren();
//      for (int j=0; j<lines.length; j++) {
//        XML [] words = lines[j].getChildren();
//        for (int k=0; k<words.length; k++) {
//          XML word = words[k];
//          //println("word", word);
//          String word_literal = word.getContent();
//          //eg 'bbox 124 911 276 975; x_wconf 81'
//          String title = word.getString("title");
//          if (word_literal.trim().length()>0) {
//            // println("word", word_literal, title);
//            String [] titleParts = splitTokens(title, " ");
//            //bbox 133 549 218 609; x_wconf 87
//            int bottomRight = int(titleParts[4].substring(0, titleParts[4].length()-1));
//            WordBox box = new WordBox(int(titleParts[1]), int(titleParts[2]), int(titleParts[3]), bottomRight, word_literal.trim(), int(titleParts[6]), title);
//            // println(box.x, box.y, box.w, box.h, bottomRight);
//            wordboxes.add(box);
//          }
//        }
//      }
//    }
//  }
//  WordBox [] boxes = wordboxes.toArray(new WordBox[wordboxes.size()]);
//  return boxes;
//}


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
  println("got words inside function");
  printArray(ws);
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