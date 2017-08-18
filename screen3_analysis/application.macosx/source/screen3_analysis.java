import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import rita.*; 
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

public class screen3_analysis extends PApplet {






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
int backgroundColour;

boolean isLeftScreen = true;
boolean isCentreScreen = false;
RiWordNet rita;

Manager manager;
public void setup() {
  
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


public void draw() {
  background(backgroundColour);
  manager.update();
  manager.display();
}

public String [] getAllPossibleStems(String word) {
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
public boolean stringArrayContainsString(String [] arr, String word) {
  boolean contains = false;
  for (int i=0; i<arr.length; i++) {
    if (arr[i].equals(word)) contains = true;
  }
  return contains;
}
public String removePunctuation(String s) {
  String res = "";
  for (Character c : s.toCharArray()) {
    if (Character.isLetterOrDigit(c))
      res += c;
  }
  return res;
}
public void oscEvent(OscMessage theOscMessage) {
  // print("### received an osc message.");

  manager.processMessage(theOscMessage);
}
public void loadSettings() {
  XML xml;
  xml = loadXML("../settings.xml");
  cameraId = xml.getChild("cameraID").getIntContent();
  sW = xml.getChild("screenWidth").getIntContent();
  sH = xml.getChild("screenHeight").getIntContent();
  fontSize = xml.getChild("fontSize").getIntContent();
  titleFontSize = xml.getChild("titleFontSize").getIntContent();
  bodyFontSize= xml.getChild("bodyFontSize").getIntContent();



  int r = PApplet.parseInt(xml.getChild("backgroundColour").getString("r"));
  int g = PApplet.parseInt(xml.getChild("backgroundColour").getString("g"));
  int b = PApplet.parseInt(xml.getChild("backgroundColour").getString("b"));

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

public WordBox [] getWordHalfBoxesFromHOCRScaled(String fname, boolean isLeft) {
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
            int thisX = PApplet.parseInt(titleParts[1]);
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
  float half = ( (xMax-xMin) *0.5f) + xMin;
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
            int bottomRight = PApplet.parseInt(titleParts[4].substring(0, titleParts[4].length()-1));

            //if this is the left hand side then check if the corner is on the left side of the page
            if (isLeft) {
              if (PApplet.parseInt(titleParts[1])<half) {
                WordBox box = new WordBox(PApplet.parseInt(titleParts[1]), PApplet.parseInt(titleParts[2]), PApplet.parseInt(titleParts[3]), bottomRight, word_literal.trim(), PApplet.parseInt(titleParts[6]), title, thisIndex);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            } else {
              if (PApplet.parseInt(titleParts[1])>=half) {
                WordBox box = new WordBox(PApplet.parseInt(titleParts[1]), PApplet.parseInt(titleParts[2]), PApplet.parseInt(titleParts[3]), bottomRight, word_literal.trim(), PApplet.parseInt(titleParts[6]), title, thisIndex);
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
public WordBox [] getWordHalfBoxesFromHOCR(String fname, boolean isLeft) {
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

            int topLeftX= PApplet.parseInt(titleParts[1]);
            int topLeftY = PApplet.parseInt(titleParts[2]);
            int bottomRightX = PApplet.parseInt(titleParts[3]);
            int bottomRightY = PApplet.parseInt(titleParts[4].substring(0, titleParts[4].length()-1));
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

            int topLeftX= (int) map(PApplet.parseFloat(titleParts[1]), xMin, xMax , xOffSet, (2*width)-xOffSet  );//  xOffSet + int(ratio * (float(titleParts[1])-xMin ) );
            int topLeftY = (int) map(PApplet.parseFloat(titleParts[2]), yMin, yMax , yOffSet,height -yOffSet  ); //int(ratio * (float(titleParts[2])-yMin)  );
            int bottomRightX =(int)  map(PApplet.parseFloat(titleParts[3]), xMin, xMax , xOffSet, (2*width)-xOffSet  );//sxOffSet + int(ratio * (float(titleParts[3]) -xMin)  );
            int bottomRightY =(int)  map(PApplet.parseFloat(titleParts[4].substring(0, titleParts[4].length()-1)), yMin, yMax , yOffSet,height - yOffSet  ); // int(ratio *( float(titleParts[4].substring(0, titleParts[4].length()-1))-yMin)   );


            //     println(topLeftX, topLeftY, bottomRightX, bottomRightY);
            //if this is the left hand side then check if the corner is on the left side of the page
            if (isLeft) {
              ///int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY,
              if (PApplet.parseInt(titleParts[1])<half) {
                WordBox box = new WordBox(topLeftX, topLeftY, bottomRightX, bottomRightY, word_literal.trim(), PApplet.parseInt(titleParts[6]), title, thisIndex, true);
                // println(box.x, box.y, box.w, box.h, bottomRight);
                wordboxes.add(box);
                //  println(thisIndex,box.index);
              }
            } else {
              if (PApplet.parseInt(titleParts[1])>=half) {
                WordBox box = new WordBox(topLeftX, topLeftY, bottomRightX, bottomRightY, word_literal.trim(), PApplet.parseInt(titleParts[6]), title, thisIndex, false);
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

public WordBox [] getWordBoxesFromHOCR(String fname) {
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
            int bottomRight = PApplet.parseInt(titleParts[4].substring(0, titleParts[4].length()-1));
            WordBox box = new WordBox(PApplet.parseInt(titleParts[1]), PApplet.parseInt(titleParts[2]), PApplet.parseInt(titleParts[3]), bottomRight, word_literal.trim(), PApplet.parseInt(titleParts[6]), title, thisIndex);
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
            words.add(word_literal.trim().toUpperCase());
          }
        }
      }
    }
  }
  String [] ws = words.toArray(new String[words.size()]);
  return ws;
}

public TFIDFResult [] processTFIDF() {
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
  public void loadTextThird() {
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
  public void loadText() {
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
  public void makeNewText() {
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
  public void display() {
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
class WordBox {
  //int topLeftX;
  //int topLeftY;
  //int bottomRightX;
  //int bottomRightY;
  boolean hasFadedIn;

  String word;
  float conf;
  float x, y, w, h, x_n, y_n, w_n, h_n ;
  String title;
  int alpha;
  int index=0; 

  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title ) {
    x = PApplet.parseFloat(_topLeftX) ;
    y = PApplet.parseFloat(_topLeftY);
    w = PApplet.parseFloat(_bottomRightX - _topLeftX);
    h = PApplet.parseFloat(_bottomRightY - _topLeftY);
    hasFadedIn = false;

    word = _word;
    conf = _conf/100;
    title = _title;
    float ratio = 6;
    x_n = x/ratio;
    y_n = y/ratio;
    w_n = w/ratio;
    h_n = h/ratio;
  }
  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title, int _index ) {
    x = PApplet.parseFloat(_topLeftX) ;
    y = PApplet.parseFloat(_topLeftY);
    w = PApplet.parseFloat(_bottomRightX - _topLeftX);
    h = PApplet.parseFloat(_bottomRightY - _topLeftY);
    hasFadedIn = false;

    word = _word;
    conf = _conf/100;
    title = _title;
    float ratio = 6;
    x_n = x/ratio;
    y_n = y/ratio;
    w_n = w/ratio;
    h_n = h/ratio;
    index = _index;
  }
  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title, int _index, boolean isLeftHandScreen) {
   int yOffSet = 0;
    x = PApplet.parseFloat(_topLeftX)  ;
    y = PApplet.parseFloat(_topLeftY) + yOffSet;
    w = PApplet.parseFloat(_bottomRightX - _topLeftX);
    h = PApplet.parseFloat(_bottomRightY - _topLeftY);
    hasFadedIn = false;

    word = _word;
    conf = _conf/100;
    title = _title;
    float ratio = 6;
    if (isLeftHandScreen) {
      x_n = x;
      y_n = y + yOffSet;
      w_n = w;
      h_n = h;
    } else {
      x_n = x-width;
      x= x-width;
      y_n = y + yOffSet;
      w_n = w;
      h_n = h;
    }

    index = _index;
  }

  public void displayBox() {
  }
  public void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
  public void updateAlpha() {
    alpha+=30;
  }
  //void display() {
  //  fill(0, alpha);
  //  text(theword, x, y);
  //}
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
  public void resetMask() {
    inCount = 0;
    startTime = millis();
    hasFinished = false;
    loaded = false;
  }
  public void display() {
    //TODO i added this if not has finisehd - check if thsi breaks things
    if (!hasFinished) {

      if (millis() - startTime < fadeInDuration) {
        fadeInGridRandomness(grid, millis() - startTime, fadeInDuration);
      } else if (millis() - startTime >= fadeInDuration + fadeOutDuration ) {
        drawGrid(grid);
      } else {
        hasFinished = true;
      }
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
class Manager {
  //boolean inBookPresentMode = true;
  //boolean inBookJustEnteredMode = false;
  //boolean inBookStartedAnalysisMode = false;
  //boolean inAmbientMode = false;
  //boolean showHOCR =true;
  //boolean showTFIDF =false;
  //boolean showMask =false;

  //

  boolean inBookPresentMode = false;
  boolean inBookJustEnteredMode = false;
  boolean inBookStartedAnalysisMode = false;
  boolean inAmbientMode = true;
  boolean showHOCR =true;
  boolean showTFIDF =false;
  boolean showMask =false;

  int timeTillScan = 8;
  long startTime = 0;
  float currentHue;
  int direction = 1;

  float fontIndex = 0;
  float fontChangeSpeed = 0.2f;

  int currentWordIndex=0;
  PFont currentFont;

  Manager(PFont defaultFont) {
    currentFont = defaultFont;
  }

  public void update() {
    if (inBookPresentMode) {
    }
  }
  public void display() {
    if (fontIndex>=0 && fontIndex<readerFonts.length) {

      currentFont = readerFonts[PApplet.parseInt(fontIndex)];
    }
    //textFont(speedReaderFont);

    fontIndex+=fontChangeSpeed;
    if (fontIndex>=readerFonts.length-1 || fontIndex <=0) {
      fontChangeSpeed*=-1;
    }

    if (inBookJustEnteredMode) {

      drawCountDown("SCANNING IN: ", "SCANNING IN: 8", 8, speedReaderFont, fontSize/2, -30);
    } else if (inBookStartedAnalysisMode) {

      drawCountDown("", "22", 35, currentFont, 550, 120);
      // drawSpeedReader();
    } else if (inBookPresentMode) {
      if (showHOCR) {

        //TODO work out proper ratio

        PVector xDimensions = getHOCRXDimensions(boxes);
        PVector yDimensions = getHOCRYDimensions(boxes);
        float hocrWidth = xDimensions.y-xDimensions.x;        
        float hocrHeight = yDimensions.y-yDimensions.x;        

        float ratio =  (width-200)/hocrWidth;     
        //float(width)/float(height);

        // println(ratio, yDimensions, xDimensions);
        textFont(bodyFont, bodyFontSize);



        if (boxes.length>0) {

          //if we haven't finished drawing boxes
          //if (!boxes[boxes.length-1].hasFadedIn) {
          // println("word indices",currentWordIndex,totalBoxesLength);
          if (currentWordIndex<=totalBoxesLength && totalBoxesLength>0) {
            //  throb(color(0), 1);

            drawHOCR(xDimensions.x, xDimensions.y, yDimensions.x, yDimensions.y, ratio, 100, 0);
          } else {
            // println("hcor false");
            showHOCR=false;
            showMask = false;
            wordInterval *= 0.5f;
            showTFIDF=true;
          }
        }
      } else if (showTFIDF) {
        String currentWord =  getCurrentWordAllWords();

        drawTFIDF(currentWord);
      } else if (showMask) {
        drawMask();
      }
    } else if (inAmbientMode) {
      drawAmbient();
    }
  }
  public void drawMask() {
    mask.display();
  }
  public void drawSpeedReader() {
    reader.update();
    reader.display();
  }
  public void processMessage(OscMessage theOscMessage ) {

    String addrPattern = theOscMessage.addrPattern();

    //println("got osc", addrPattern);
    if (addrPattern.equals("/go")) {

      // println("received in analysis");
      tfidfResult = processTFIDF();
      boxes = getWordHalfBoxesFromHOCR(hocrPath, isLeftScreen);
      allBoxes = getWordBoxesFromHOCR(hocrPath);
      showHOCR = true;
      showMask = false;
      showTFIDF = false;
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
      //println("ambient");
      inBookPresentMode  = false;
      inBookJustEnteredMode = false;

      inBookStartedAnalysisMode = false;
      if (!inAmbientMode) {
        ai.loadTextThird();
      }
      inAmbientMode = true;
    } else if (addrPattern.equals("/justentered")) {
      if (!inBookJustEnteredMode) startTime = millis();
      inBookJustEnteredMode = true;
      inBookPresentMode  = false;  
      inAmbientMode = false;
      inBookStartedAnalysisMode = false;
    } else if (addrPattern.equals("/speedreader")) {
      currentWordIndex = theOscMessage.get(0).intValue();
    } else if (addrPattern.equals("/mask")) {
      //println("show mask");
      showHOCR = false;
      showTFIDF = false;
      showMask = true;
      mask.resetMask();
      mask.makeMask(dataPathReader+"data/grab.png");
    }
  }
  public void throb(int to, float rate) {
    float fromHue = hue(backgroundColour);
    colorMode(RGB);
    float fromSaturation = saturation(backgroundColour);
    float fromBrightness = brightness(backgroundColour);

    float toHue = brightness(to);
    pushStyle();
    colorMode(HSB);
    int currentColour = color(fromHue, fromSaturation, currentHue);

    background(currentColour);
    currentHue+=(direction*rate);

    if (currentHue>= max(fromBrightness, toHue) || currentHue<= min(fromBrightness, toHue) ) {
      direction*=-1;
    }
    // println("throbbing", currentHue);
    popStyle();
  }
  public void drawAmbient() {
    //String amb = "AMBIENT SCREEN";
    //fill(0);
    //text(amb, (width/2)-(0.5*textWidth(amb)), height/2);
    ai.display();
  }
  public void drawCountDown(String message, String widthSetMessage, int countLimit, PFont countDownFont, int fontSize, int yOffSet) {
    //String amb = "AMBIENT SCREEN";
    //text(amb, (width/2)+(0.5*textWidth(amb)), height/2);
    pushStyle();
    textFont(countDownFont, fontSize);
    fill(0);
    int currentCount = countLimit- (PApplet.parseInt(millis()- startTime   )/1000);
    if (currentCount < 0) currentCount = 0;
    String timeToScan = message+str(currentCount);
    text(timeToScan, (width/2)-(0.5f*textWidth(widthSetMessage)), yOffSet+(height/2));
    popStyle();
  }
  public void drawTFIDF() {
    float spacing = height/(tfidfResult.length+2);
    for (int i=0; i<tfidfResult.length; i++) {


      if (i>0) {
        if (tfidfResult[i-1].hasFadedIn) {
          tfidfResult[i].update();
        }
      } else {
        tfidfResult[i].update();
      }
      tfidfResult[i].display(width/2, spacing +(i*spacing));
    }
  }
  public void drawTFIDF(String word) {
    pushStyle();
    textFont(speedReaderFont);
    String [] stems = getAllPossibleStems(removePunctuation(word.trim()));
    //printArray(stems);
    for (int i=0; i<tfidfResult.length; i++) {
      // println(word, tfidfResult[i].word);
      if (stringArrayContainsString(stems, tfidfResult[i].word.toLowerCase())) {
        //println("found", tfidfResult[i].word);
        for (int j=0; j<tfidfResult.length; j++) {
          tfidfResult[j].alpha =0;
        }
        tfidfResult[i].alpha = 255;
        tfidfResult[i].fullWord = word.trim().toUpperCase();
      }
      tfidfResult[i].updateAlpha();
      fill(0, tfidfResult[i].alpha);

      // text(word.toUpperCase(),(width/2) - (0.5*textWidth(word.toUpperCase())), height/2);
      tfidfResult[i].displayFullWord((width/2), height/2);
    }
    popStyle();
  }
  public PVector getHOCRXDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minX = 100000000;
    float maxX = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.x < minX) {
        minX = box.x;
      } else if (box.x > maxX ) {
        maxX = box.x;
      }
    }
    dimensions.x = minX;
    dimensions.y = maxX;
    return dimensions;
  }
  public PVector getHOCRYDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minY = 100000000;
    float maxY = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.y < minY) {
        minY = box.y;
      } else if (box.y > maxY ) {
        maxY = box.y;
      }
    }

    dimensions.x = minY;
    dimensions.y = maxY;

    return dimensions;
  }
  public PVector getHOCRBoxWidthDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minW = 100000000;
    float maxW = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.w < minW) {
        minW = box.w;
      } else if (box.w > maxW ) {
        maxW = box.w;
      }
    }

    dimensions.x = minW;
    dimensions.y = maxW;

    return dimensions;
  }
  public PVector getHOCRBoxHeightDimensions(WordBox [] boxes) {
    PVector dimensions = new PVector(0, 0);
    float minH = 100000000;
    float maxH = 0;
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      if (box.h < minH) {
        minH = box.h;
      } else if (box.h > maxH ) {
        maxH = box.h;
      }
    }
    dimensions.x = minH;
    dimensions.y = maxH;
    return dimensions;
  }
  public String getCurrentWord() {
    String currentWord="";
    for (int i=0; i<boxes.length; i++) {
      if (boxes[i].index==currentWordIndex) {
        currentWord=boxes[i].word;
      }
    }
    return currentWord;
  }
  public String getCurrentWordAllWords() {
    String currentWord="";
    for (int i=0; i<allBoxes.length; i++) {
      if (allBoxes[i].index==currentWordIndex) {
        currentWord=allBoxes[i].word;
      }
    }
    return currentWord;
  }

  public void drawHOCR(float xMin, float xMax, float yMin, float yMax, float ratio, int offSetX, int offSetY) {
    //println("Drwaing hcr");
    for (int i=0; i<boxes.length; i++) {


      fill(0);
      noStroke();
      //float thisX =map(boxes[i].x, xMin, xMax, offSetX, width -offSetX);  
      //float thisY =  offSetY + (boxes[i].y*ratio); // map(box.y, 0, yMax*ratio, offSetY, (height*ratio)-offSetY ); 

      //float thisW =boxes[i].w *ratio;//map(box.w, xMin, xMax, offSetX, width -offSetX); 
      //float thisH =boxes[i].h*ratio;//map(box.h, yMin, yMax, offSetY, (height*ratio) ); 
      float thisX = boxes[i].x;
      float thisY = boxes[i].y;
      float thisW = boxes[i].w;
      float thisH = boxes[i].h;


      if (boxes[i].index==currentWordIndex) {
        boxes[i].updateAlpha();
        fill(255, 0, 0, boxes[i].alpha);
      } else {
        noFill();
        stroke(100, 100);
      }

      //stroke(0);
      //if (i>0) {
      //  if (boxes[i-1].hasFadedIn) {
      //    boxes[i].update();
      //    stroke(0, boxes[i].alpha);
      //  }
      //} else {
      //  boxes[i].update();
      //}
      rect(thisX, thisY, thisW, thisH);
    }
  }
  public void drawHOCRSelfAnimated(float xMin, float xMax, float yMin, float yMax, float ratio, int offSetX, int offSetY) {
    //println("Drwaing hcr");
    for (int i=0; i<boxes.length; i++) {
      WordBox box = boxes[i];
      fill(0);
      noStroke();
      float thisX =map(box.x, xMin, xMax, offSetX, width -offSetX);  
      float thisY =  offSetY + (box.y*ratio); // map(box.y, 0, yMax*ratio, offSetY, (height*ratio)-offSetY ); 

      float thisW =box.w *ratio;//map(box.w, xMin, xMax, offSetX, width -offSetX); 
      float thisH =box.h*ratio;//map(box.h, yMin, yMax, offSetY, (height*ratio) ); 
      fill(255, 0, 0, boxes[i].alpha);
      //stroke(0);
      if (i>0) {
        if (boxes[i-1].hasFadedIn) {
          boxes[i].update();
          stroke(0, boxes[i].alpha);
        }
      } else {
        boxes[i].update();
      }
      rect(thisX, thisY, thisW, thisH);
    }
  }
}
class SpeedReader {
  float wpm = 250;
  float wordInterval;
  long startTime = 0;
  int wordIndex = 0;  
  String [] words;

  SpeedReader(String [] _words, float _wordInterval) {
    words = _words;
    wordInterval = _wordInterval;
    startTime=millis();
  }
  SpeedReader(float _wordInterval) {
    wordInterval = _wordInterval;
    startTime=millis();
  }
  public void loadText(String path){
    words = splitTokens(join(loadStrings(path+"wait.txt") ," ")," ");
    printArray(words);
  }
  public void update() {

    if (millis()-wordInterval>=startTime) {
      startTime=millis();
      //if (go) {

      wordIndex++;
    }


    if (wordIndex>=words.length) {
      wordIndex=0;
    }
  }

  public void display() {
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
class TFIDFResult {
  String word;
  String fullWord;
  float val;
  boolean hasFadedIn;
  int alpha;
  TFIDFResult(String _word, float _val) {
    word = _word.toUpperCase();
    val = _val;
  }

  public void display(float x, float y) {
    fill(0, alpha);
    if (word!=null)   text(word, x-(textWidth(word)/2), y);
  }
  public void displayFullWord(float x, float y) {
    fill(255,0,0,alpha);
    rect(0,0,width,height);
    fill(0, alpha);
    if (fullWord!=null)   text(fullWord, x-(textWidth(fullWord)/2), y);
  }
  public void updateAlpha(){
    alpha-=5;
  }
  public void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
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
  public void settings() {  fullScreen(1); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--hide-stop", "screen3_analysis" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
