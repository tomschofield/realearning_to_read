import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import netP5.*; 
import oscP5.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class screen1_ai extends PApplet {




OscP5 oscP5;
PFont font;
int cameraId, sW, sH, fontSize, wpm, aiPort, analysisPort;
String fontName, aiIp, analysisIp;
int wordInterval;
int messageIndex;
boolean gotNewMessage = false;

Word [] words;

String rnnPath;
String rootPath;
int port ;
String aiText="";

int xBorder  =  100;
int yBorder  =  100;

int textHeight;
float textYPos = 0;
int latestFadedWordIndex =-1;
int platestFadedWordIndex = -1;
boolean runLive = true;
int backgroundColour;

public void setup() {
  
  colorMode(HSB, 360, 100, 100);

  loadSettings();
  font = loadFont("Baskerville-48.vlw");
  textFont(font, fontSize);
  oscP5 = new OscP5(this, aiPort);
}


public void draw() {
  background(backgroundColour);
  text(messageIndex, 20, 20);
  if (gotNewMessage) {
    makeNewText();
    gotNewMessage=false;
  }

  if (words!=null) {
    if (words.length>0) {
      words[0].update();
      words[0].display();
      println(words.length);
      for (int i=1; i<words.length; i++) {
        if (words[i-1].hasFadedIn) {
          latestFadedWordIndex = i;
          words[i].update();
          words[i].display();
        }
      }
    }
    if (words.length<100) {
      makeNewText();
    }
    if (latestFadedWordIndex!=platestFadedWordIndex) {
      if (words[latestFadedWordIndex].y>height ) {
        makeNewText();
      }
      platestFadedWordIndex = latestFadedWordIndex;
    }
  }
}

public void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");

  if (theOscMessage.addrPattern().equals("/go")) {
    println("received in ai");
    messageIndex = theOscMessage.get(0).intValue();
    gotNewMessage =  true;
  }
}
public void loadSettings() {
  XML xml;
  xml = loadXML("../settings.xml");
  cameraId = xml.getChild("cameraID").getIntContent();
  sW = xml.getChild("screenWidth").getIntContent();
  sH = xml.getChild("screenHeight").getIntContent();
  fontSize = xml.getChild("fontSize").getIntContent();
  wpm = xml.getChild("wpm").getIntContent();

  aiPort = xml.getChild("aiPort").getIntContent();
  analysisPort= xml.getChild("analysisPort").getIntContent();

  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");

  fontName = xml.getChild("fontName").getString("name");

  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
  //font = createFont(fontName, fontSize, true, charset);

  //textFont(font);

  wordInterval = 60000 /wpm;
}


public void makeNewText() {
  if (runLive) {
    try {
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
      //String [] lines=  loadStrings(rootPath+"aiText.txt");
      //textHeight = fontSize * lines.length;
      //println(textHeight);
      //aiText = join(lines, " ");
    }
  }

  if (runLive) {
    aiText = join(loadStrings(rootPath+"aiText.txt"), " ");
  } else {
    aiText = join(loadStrings(rootPath+"aiTextBackup.txt"), " ");
  }

  println("aitext,", aiText);
  String [] allwords = splitTokens(aiText, " ");
  words = new Word [allwords.length];

  int x = xBorder;
  int y = yBorder;

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
  public void settings() {  size(600, 800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "screen1_ai" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
