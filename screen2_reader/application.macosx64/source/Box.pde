class WordBox {
  //int topLeftX;
  //int topLeftY;
  //int bottomRightX;
  //int bottomRightY;
  String word;
  float conf;
  float x, y, w, h, x_n, y_n, w_n, h_n ;
  String title;

  WordBox(int _topLeftX, int _topLeftY, int _bottomRightX, int _bottomRightY, String _word, int _conf, String _title ) {
    x = float(_topLeftX) ;
    y = float(_topLeftY);
    w = float(_bottomRightX - _topLeftX);
    h = float(_bottomRightY - _topLeftY);
    word = _word;
    conf = _conf/100;
    title = _title;
    float ratio = 300/72;
    x_n = x/ratio;
    y_n = y/ratio;
    w_n = w/ratio;
    h_n = h/ratio;
  }
  void displayBox(){
    
  }
}