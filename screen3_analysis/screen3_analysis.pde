import netP5.*;
import oscP5.*;
TFIDFResult [] tfidfResult;
WordBox [] boxes;
OscP5 oscP5;
PFont font;  
PFont bodyFont;
int cameraId, sW, sH, fontSize, wpm, aiPort, analysisPort, titleFontSize, bodyFontSize;
String fontName, aiIp, analysisIp, hocrPath, scriptsPath, messagesFontName, bodyFontName;
int wordInterval;
int messageIndex;
color backgroundColour;

Manager manager;
void setup() {
 // size(1000, 1000);
 fullScreen(2);
  manager = new Manager();

  loadSettings();

  println("hocr");
  //printArray(getWordsFromHOCR(hocrPath));
  oscP5 = new OscP5(this, analysisPort);
  boxes = getWordBoxesFromHOCR(hocrPath);
  tfidfResult = processTFIDF();
}


void draw() {
  background(backgroundColour);
  manager.update();
  manager.display();
}

void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");
  manager.processMessage(theOscMessage.addrPattern());
}
void loadSettings() {
  XML xml;
  xml = loadXML("../settings.xml");
  cameraId = xml.getChild("cameraID").getIntContent();
  sW = xml.getChild("screenWidth").getIntContent();
  sH = xml.getChild("screenHeight").getIntContent();
  fontSize = xml.getChild("fontSize").getIntContent();
  titleFontSize = xml.getChild("titleFontSize").getIntContent();
  bodyFontSize= xml.getChild("bodyFontSize").getIntContent();



  int r = int(xml.getChild("backgroundColour").getString("r"));
  int g = int(xml.getChild("backgroundColour").getString("g"));
  int b = int(xml.getChild("backgroundColour").getString("b"));

  backgroundColour = color(r, g, b);

  wpm = xml.getChild("wpm").getIntContent();

  aiPort = xml.getChild("aiPort").getIntContent();
  analysisPort= xml.getChild("analysisPort").getIntContent();

  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");
  hocrPath = xml.getChild("hocrPath").getString("name");
  fontName = xml.getChild("fontName").getString("name");
  messagesFontName = xml.getChild("messagesFontName").getString("name");
  bodyFontName = xml.getChild("bodyFontName").getString("name");
  scriptsPath = xml.getChild("scriptsPath").getString("name"); 
  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
  //font = createFont(fontName, fontSize, true, charset);
  font = loadFont(messagesFontName);
  bodyFont = loadFont(bodyFontName);
  textFont(font, titleFontSize);

  wordInterval = 60000 /wpm;
}

WordBox [] getWordBoxesFromHOCR(String fname) {
  XML xml;
  ArrayList<WordBox> wordboxes= new ArrayList<WordBox>();

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
        XML [] words = lines[j].getChildren();
        for (int k=0; k<words.length; k++) {
          XML word = words[k];
          //println("word", word);
          String word_literal = word.getContent();
          //eg 'bbox 124 911 276 975; x_wconf 81'
          String title = word.getString("title");
          if (word_literal.trim().length()>0) {
            // println("word", word_literal, title);
            String [] titleParts = splitTokens(title, " ");
            //bbox 133 549 218 609; x_wconf 87
            int bottomRight = int(titleParts[4].substring(0, titleParts[4].length()-1));
            WordBox box = new WordBox(int(titleParts[1]), int(titleParts[2]), int(titleParts[3]), bottomRight, word_literal.trim(), int(titleParts[6]), title);
            // println(box.x, box.y, box.w, box.h, bottomRight);
            wordboxes.add(box);
          }
        }
      }
    }
  }
  WordBox [] boxes = wordboxes.toArray(new WordBox[wordboxes.size()]);
  return boxes;
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
            words.add(word_literal.trim().toUpperCase());
          }
        }
      }
    }
  }
  String [] ws = words.toArray(new String[words.size()]);
  return ws;
}
TFIDFResult [] processTFIDF() {
  TFIDFResult [] tfidf = new TFIDFResult[0];
  int maxTfidfLength  =100;
  JSONArray arr;
  try {
    Process resize = Runtime.getRuntime().exec("/usr/local/bin/python /Users/tomschofield/Dropbox/readingreading/install_v1/scripts/tfidf.py");

    resize.waitFor();
    int exitVal = resize.exitValue();
    println("resized script finished", exitVal);
    arr = loadJSONArray(scriptsPath+"result.json");
    tfidf = new TFIDFResult[arr.size()];
    for (int i=0; i<arr.size(); i++) {
      JSONArray pair = arr.getJSONArray(i); 
      String word = pair.getString(0);
      float val = pair.getFloat(1);
      println(word, val);
      tfidf [i] = new TFIDFResult(word, val);
      println(tfidf [i].word, tfidf [i].val);
    }
    if (tfidf.length>maxTfidfLength) {
      tfidf = (TFIDFResult []) subset(tfidf, 0, maxTfidfLength-1);
    }
    //go = true;
  }
  catch (Exception e) {
    println(e);
  } 
  return tfidf;
}