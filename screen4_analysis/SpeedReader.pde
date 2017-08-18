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
  void loadText(String path){
    words = splitTokens(join(loadStrings(path+"wait.txt") ," ")," ");
    printArray(words);
  }
  void update() {

    if (millis()-wordInterval>=startTime) {
      startTime=millis();
      //if (go) {

      wordIndex++;
    }


    if (wordIndex>=words.length) {
      wordIndex=0;
    }
  }

  void display() {
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
      offset+= 0.5 *(textWidth(str(thisWord.charAt(centralCharIndex))));
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
  float getCentralCharPos(String word) {

    int numChars = word.length();
    int centralCharIndex =int( numChars/2.0);
    float fCentralCharIndex = numChars/2.0;
    float centralCharPos = 0.0;
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
  String getCentralChar(String word) {

    int numChars = word.length();
    int centralCharIndex =int( numChars/2.0);
    float fCentralCharIndex = numChars/2.0;
    float centralCharPos = 0.0;
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
  int getCentralCharIndex(String word) {

    int numChars = word.length();
    int centralCharIndex =int( numChars/2.0);
    float fCentralCharIndex = numChars/2.0;
    float centralCharPos = 0.0;
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