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

  void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
  void display() {
    fill(0, alpha);
    text(theword, x, y);
  }
}