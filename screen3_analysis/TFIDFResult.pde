class TFIDFResult {
  String word;
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
  void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
}