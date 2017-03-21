import netP5.*;
import oscP5.*;

OscP5 oscP5;
PFont font;
PFont bodyFont;
int cameraId, sW, sH, fontSize, wpm, aiPort, analysisPort, titleFontSize, bodyFontSize;
String fontName, aiIp, analysisIp, hocrPath, scriptsPath, messagesFontName, bodyFontName;
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
color backgroundColour;
Manager manager;

/*
TO DO - shift aitext into install folder
*/

void setup() {
  fullScreen(1);
  //size(1920, 1200);
  // colorMode(HSB, 360, 100, 100);

  loadSettings();

  oscP5 = new OscP5(this, aiPort);
  manager = new Manager();
}


void draw() {
  //colorMode(HSB, 360, 100, 100);
  background(backgroundColour);
  // colorMode(RGB);
  fill(0);

  manager.update();
  manager.display();
}

void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");
  manager.processMessage(theOscMessage.addrPattern());
  //if (theOscMessage.addrPattern().equals("/go")) {
  //  println("received in ai");
  //  messageIndex = theOscMessage.get(0).intValue();
  //  gotNewMessage =  true;
  //}
}
void loadSettings() {
  XML xml;
  xml = loadXML("../settings.xml");
  cameraId = xml.getChild("cameraID").getIntContent();
  sW = xml.getChild("screenWidth").getIntContent();
  sH = xml.getChild("screenHeight").getIntContent();
  fontSize = xml.getChild("aiFontSize").getIntContent();
  titleFontSize = xml.getChild("titleFontSize").getIntContent();
  bodyFontSize= xml.getChild("bodyFontSize").getIntContent();
  wpm = xml.getChild("wpm").getIntContent();

  aiPort = xml.getChild("aiPort").getIntContent();
  analysisPort= xml.getChild("analysisPort").getIntContent();

  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");
  rootPath = xml.getChild("rootPath").getString("name");

  fontName = xml.getChild("fontName").getString("name");
  messagesFontName = xml.getChild("messagesFontName").getString("name");
  bodyFontName = xml.getChild("bodyFontName").getString("name");


  int r = int(xml.getChild("backgroundColour").getString("r"));
  int g = int(xml.getChild("backgroundColour").getString("g"));
  int b = int(xml.getChild("backgroundColour").getString("b"));

  backgroundColour = color(r, g, b);
  
  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
  //font = createFont(fontName, fontSize, true, charset);

  //textFont(font);
  bodyFont = loadFont(bodyFontName);
  font = loadFont(messagesFontName);
  textFont(font, titleFontSize);
  wordInterval = 60000 /wpm;
}


void makeNewText() {
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