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
  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title ) {
    x = float(_topLeftX) ;
    y = float(_topLeftY);
    w = float(_bottomRightX - _topLeftX);
    h = float(_bottomRightY - _topLeftY);
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
  void displayBox() {
  }
  void update() {
    alpha+=30; 
    if (alpha>=255) {
      hasFadedIn= true;
    }
  }
  //void display() {
  //  fill(0, alpha);
  //  text(theword, x, y);
  //}
}