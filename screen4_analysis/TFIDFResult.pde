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

  void display(float x, float y) {
    fill(0, alpha);
    if (word!=null)   text(word, x-(textWidth(word)/2), y);
  }
  void displayFullWord(float x, float y) {
    fill(255,0,0,alpha);
    rect(0,0,width,height);
    fill(0, alpha);
    if (fullWord!=null)   text(fullWord, x-(textWidth(fullWord)/2), y);
  }
  void updateAlpha(){
    alpha-=5;
  }
  void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
}