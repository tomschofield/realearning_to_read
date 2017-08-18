import rita.*;

import netP5.*;
import oscP5.*;

TFIDFResult [] tfidfResult;

WordBox [] boxes;
WordBox [] allBoxes;
ColorMask mask;
PFont [] readerFonts;

Ai ai;
OscP5 oscP5;
PFont font;  
PFont bodyFont;
PFont speedReaderFont;
PFont bigCountDownFont;

SpeedReader reader;
int cameraId, sW, sH, fontSize, wpm, aiPort, analysisPort, analysisPort2, titleFontSize, bodyFontSize;
String fontName, rootPath, aiIp, analysisIp, hocrPath, scriptsPath, dataPathReader, messagesFontName, bodyFontName, speedReaderFontName;
int wordInterval;
int messageIndex;
int totalBoxesLength=0;
color backgroundColour;

boolean isLeftScreen = false;
boolean isCentreScreen = false;
RiWordNet rita;

Manager manager;
void setup() {
  fullScreen(2);
  noCursor();
  loadSettings();

  manager = new Manager(bigCountDownFont);
  ai = new Ai();
  if (isLeftScreen) ai.makeNewText();
  ai.loadTextThird();
  mask = new ColorMask();
  mask.makeMask(dataPathReader+"data/grab.png");
  reader = new SpeedReader(wordInterval);
  reader.loadText(scriptsPath);

  rita = new RiWordNet(rootPath+"install_v1/wordnet");

  oscP5 = new OscP5(this, analysisPort);

  allBoxes = getWordBoxesFromHOCR(hocrPath);
  boxes = getWordHalfBoxesFromHOCR(hocrPath, isLeftScreen);
  tfidfResult = processTFIDF();
}


void draw() {
  background(backgroundColour);
  manager.update();
  manager.display();
}

String [] getAllPossibleStems(String word) {
  String [] pos = rita.getPos(word);
  ArrayList <String> allStems= new ArrayList<String>();
  if (pos!=null) {
    for (int i=0; i<pos.length; i++) {
      String [] stems = rita.getStems(word, pos[i]);
      if (stems!=null) 
        for (int j=0; j<stems.length; j++) {
          allStems.add(stems[j]);
        }
    }
  }

  String [] sts = allStems.toArray(new String[allStems.size()]);
  return sts;
}
boolean stringArrayContainsString(String [] arr, String word) {
  boolean contains = false;
  for (int i=0; i<arr.length; i++) {
    if (arr[i].equals(word)) contains = true;
  }
  return contains;
}
String removePunctuation(String s) {
  String res = "";
  for (Character c : s.toCharArray()) {
    if (Character.isLetterOrDigit(c))
      res += c;
  }
  return res;
}
void oscEvent(OscMessage theOscMessage) {
  // print("### received an osc message.");

  manager.processMessage(theOscMessage);
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
  if (isLeftScreen) {
    analysisPort= xml.getChild("analysisPort").getIntContent();
  } else {
    analysisPort= xml.getChild("analysisPortTwo").getIntContent();
  }
  aiIp = xml.getChild("aiIp").getString("name");
  analysisIp = xml.getChild("analysisIp").getString("name");
  hocrPath = xml.getChild("hocrPath").getString("name");
  rootPath = xml.getChild("rootPath").getString("name");
  dataPathReader = xml.getChild("dataPathReader").getString("name");

  fontName = xml.getChild("fontName").getString("name");
  messagesFontName = xml.getChild("messagesFontName").getString("name");
  speedReaderFontName = xml.getChild("speedReaderFontName").getString("name");

  readerFonts = new PFont [6];
  int countDownFontSize = xml.getChild("countDownFontSize").getIntContent();

  readerFonts[0] = createFont(rootPath+"install_v1/fonts/" +"TorqueraUltraLight.ttf", countDownFontSize);
  readerFonts[1] = createFont(rootPath+"install_v1/fonts/" +"TorqueraLight.ttf", countDownFontSize);
  readerFonts[2] = createFont(rootPath+"install_v1/fonts/" +"TorqueraMedium.ttf", countDownFontSize);
  readerFonts[3] = createFont(rootPath+"install_v1/fonts/" +"TorqueraBold.ttf", countDownFontSize);
  readerFonts[4] = createFont(rootPath+"install_v1/fonts/" +"TorqueraHeavy.ttf", countDownFontSize);
  readerFonts[5] = createFont(rootPath+"install_v1/fonts/" +"TorqueraBlack.ttf", countDownFontSize);

  speedReaderFont = createFont(speedReaderFontName, fontSize/2);
  bigCountDownFont= createFont(speedReaderFontName, countDownFontSize);

  bodyFontName = xml.getChild("bodyFontName").getString("name");
  scriptsPath = xml.getChild("scriptsPath").getString("name"); 
  char [] charset =  new char[255];
  for (int i=0; i<charset.length; i++) {
    charset[i] = (char) i;
  }
  //font = createFont(fontName, fontSize, true, charset);
  font = loadFont(messagesFontName);
  bodyFont = createFont(bodyFontName, bodyFontSize);
  textFont(font, titleFontSize);

  wordInterval = 60000 /wpm;
}

WordBox [] getWordHalfBoxesFromHOCRScaled(String fname, boolean isLeft) {
  XML xml;
  ArrayList<WordBox> wordboxes= new ArrayList<WordBox>();

  xml = loadXML(fname);

  XML body = xml.getChild("body");
  XML page = body.getChild("div");


  XML [] paragraphs = page.getChildren();
  String titles = page.getString("title");
  //println(titles);

  //println(paragraphs.length);

  int xMin=1000000;
  int xMax= 0;

  int yMin = 1000000;
  int yMax = 0;

  //first lets find the width of the document to establish a cut off point
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
            int thisX = int(titleParts[1]);
            if (thisX>xMax) {
              xMax = thisX;
            } else if (thisX <xMin) {
              xMin = thisX;
            }
          }
        }
      }
    }
  }

  int thisIndex =0;
  float half = ( (xMax-xMin) *0.5) + xMin;
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

            //if this is the left hand side then check if the corner is on the left side of the page
            if (isLeft) {
              if (int(titleParts[1])<half) {
                WordBox box = new WordBox(int(titleParts[1]), int(titleParts[2]), int(titleParts[3]), bottomRight, word_literal.trim(), int(titleParts[6]), title, thisIndex);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            } else {
              if (int(titleParts[1])>=half) {
                WordBox box = new WordBox(int(titleParts[1]), int(titleParts[2]), int(titleParts[3]), bottomRight, word_literal.trim(), int(titleParts[6]), title, thisIndex);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            }
            totalBoxesLength = thisIndex;
            thisIndex++;
          }
        }
      }
    }
  }
  WordBox [] boxes = wordboxes.toArray(new WordBox[wordboxes.size()]);
  return boxes;
}
WordBox [] getWordHalfBoxesFromHOCR(String fname, boolean isLeft) {
  XML xml;
  ArrayList<WordBox> wordboxes= new ArrayList<WordBox>();

  xml = loadXML(fname);

  XML body = xml.getChild("body");
  XML page = body.getChild("div");


  XML [] paragraphs = page.getChildren();
  String titles = page.getString("title");
  //println(titles);

  //println(paragraphs.length);

  int xMin=1000000;
  int xMax= 0;

  int yMin = 1000000;
  int yMax = 0;

  //first lets find the width of the document to establish a cut off point
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

            int topLeftX= int(titleParts[1]);
            int topLeftY = int(titleParts[2]);
            int bottomRightX = int(titleParts[3]);
            int bottomRightY = int(titleParts[4].substring(0, titleParts[4].length()-1));
            int w = bottomRightX - topLeftX;
            int h = bottomRightY - topLeftY;

            if (topLeftX + h>xMax) {
              xMax = topLeftX;
            } else if (topLeftX <xMin) {
              xMin = topLeftX;
            }
            if (bottomRightY > yMax) {
              yMax = bottomRightY;
            } else if (topLeftY < yMin) {
              yMin = topLeftY;
            }
          }
        }
      }
    }
  }
  println("xMin: ", xMin, "; xMax: ", xMax, "; yMin: ", yMin, "; yMax: ", yMax);

  int pageWidth = xMax - xMin;
  int pageHeight = yMax - yMin;

  boolean pageIsTooBig = false;
  if (pageWidth > width * 2 || pageHeight > height) {
    pageIsTooBig = true;
  }
  int xOffSet = 300;
  int yOffSet = 300;
  float ratio =  (( width * 2) - (xOffSet * 2))/pageWidth ;          

  float yRatio =  (( height) - (yOffSet * 2))/pageHeight;

  boolean useXratio = true;

  float documentTop = yOffSet + (ratio *  (yMax-yMin));
  if (documentTop > height) {
    useXratio  =false;
  }

  if (! useXratio) {
    ratio = yRatio; 
    println("doc too tall, using y ratio", documentTop);
  } else {
    println("Doc fits, use xRatio", documentTop);
  }
  //work out how much tis has been scaled down or up and then scale it back up again



  int thisIndex =0;
  float half = width;//pageWidth/2;
  // float half = width;
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
            //          int bottomRight = int(titleParts[4].substring(0, titleParts[4].length()-1));


            //int topLeftX= xOffSet + int(ratio * (float(titleParts[1])-xMin ) );
            //int topLeftY = int(ratio * (float(titleParts[2])-yMin)  );
            //int bottomRightX = xOffSet + int(ratio * (float(titleParts[3]) -xMin)  );
            //int bottomRightY =  int(ratio *( float(titleParts[4].substring(0, titleParts[4].length()-1))-yMin)   );

            int topLeftX= (int) map(float(titleParts[1]), xMin, xMax , xOffSet, (2*width)-xOffSet  );//  xOffSet + int(ratio * (float(titleParts[1])-xMin ) );
            int topLeftY = (int) map(float(titleParts[2]), yMin, yMax , yOffSet,height -yOffSet  ); //int(ratio * (float(titleParts[2])-yMin)  );
            int bottomRightX =(int)  map(float(titleParts[3]), xMin, xMax , xOffSet, (2*width)-xOffSet  );//sxOffSet + int(ratio * (float(titleParts[3]) -xMin)  );
            int bottomRightY =(int)  map(float(titleParts[4].substring(0, titleParts[4].length()-1)), yMin, yMax , yOffSet,height - yOffSet  ); // int(ratio *( float(titleParts[4].substring(0, titleParts[4].length()-1))-yMin)   );


            //     println(topLeftX, topLeftY, bottomRightX, bottomRightY);
            //if this is the left hand side then check if the corner is on the left side of the page
            if (isLeft) {
              ///int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY,
              if (int(titleParts[1])<half) {
                WordBox box = new WordBox(topLeftX, topLeftY, bottomRightX, bottomRightY, word_literal.trim(), int(titleParts[6]), title, thisIndex, true);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            } else {
              if (int(titleParts[1])>=half) {
                WordBox box = new WordBox(topLeftX, topLeftY, bottomRightX, bottomRightY, word_literal.trim(), int(titleParts[6]), title, thisIndex, false);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            }
            totalBoxesLength = thisIndex;
            thisIndex++;
          }
        }
      }
    }
  }
  WordBox [] boxes = wordboxes.toArray(new WordBox[wordboxes.size()]);
  return boxes;
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
  int thisIndex =0;
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
            WordBox box = new WordBox(int(titleParts[1]), int(titleParts[2]), int(titleParts[3]), bottomRight, word_literal.trim(), int(titleParts[6]), title, thisIndex);
            // println(box.x, box.y, box.w, box.h, bottomRight);
            wordboxes.add(box);
            thisIndex++;
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
    if(isLeftScreen){
    Process resize = Runtime.getRuntime().exec("/usr/local/bin/python /Users/tomschofield/Dropbox/readingreading/install_v1/scripts/tfidf.py");
    
    resize.waitFor();
    int exitVal = resize.exitValue();
      //println("resized script finished", exitVal);
    arr = loadJSONArray(scriptsPath+"result.json");
    }
    else{
       Process resize = Runtime.getRuntime().exec("/usr/local/bin/python /Users/tomschofield/Dropbox/readingreading/install_v1/scripts/tfidf1.py");
    
    resize.waitFor();
    int exitVal = resize.exitValue();
          arr = loadJSONArray(scriptsPath+"result1.json");

    }
  
    tfidf = new TFIDFResult[arr.size()];
    for (int i=0; i<arr.size(); i++) {
      JSONArray pair = arr.getJSONArray(i); 
      String word = pair.getString(0);
      float val = pair.getFloat(1);
      // println(word, val);
      tfidf [i] = new TFIDFResult(word, val);
      //println(tfidf [i].word, tfidf [i].val);
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