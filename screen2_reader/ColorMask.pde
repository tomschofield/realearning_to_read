class ColorMask {
  PImage target;
  color [][] grid;
  color [][] ugrid;
  color [][] dgrid;
  float numFadeInFrames = 500;
  int numFadeOutFrames = 400;
  long startTime = 0;
  long fadeInDuration = 5000;
  long fadeOutDuration = 5000;

  boolean hasFinished = false;
  float inCount = 0;
  float ratio = 0.9;
  boolean loaded = false;
  ColorMask() {
  }
  void makeMask(String path) {
    PImage source= loadImage(path);
    grid  = getColourMask(source);
    loaded = true;
  }
  void startMaskCounter() {
    inCount = 0;
    startTime = millis();
  }
  void resetMask() {

    hasFinished = false;
    loaded = false;
  }
  void display() {
   // println("millis() - startTime", millis() - startTime);
    if (millis() - startTime < fadeInDuration) {
      fadeInGridRandomness(grid, millis() - startTime, fadeInDuration);
   //   println("fading in:");
    } else if (millis() - startTime >= fadeInDuration &&  millis() - startTime < fadeInDuration + fadeOutDuration ) {
      drawGrid(grid);
    //  println("drawing grid:");
    } else {
      hasFinished = true;
    //  println("finished:");
    }
    //inCount++;
  }
  void displayFrames() {

    if (inCount<numFadeInFrames) {
      fadeInGridRandomness(grid, inCount, numFadeInFrames);
    } else if (inCount > numFadeInFrames + numFadeOutFrames ) {
      drawGrid(grid);
    } else {
      hasFinished = true;
    }
    inCount++;
  }

  void fadeInGridRandomness(color [][] grid, float inCount, float numFadeInFrames) {
    pushStyle();
    noStroke();
    color fadFromColour = color (255);
    float ratio = 0.9;
    float xSpace = width/grid.length;
    float ySpace = height/grid[0].length;
    for (int i=0; i<grid.length; i++) {
      for (int j=0; j<grid[i].length; j++) {
        color c = grid[i][j];
        float redDifference = red(c)-red(fadFromColour);
        float greenDifference = green(c)-green(fadFromColour);
        float blueDifference = blue(c)-blue(fadFromColour);

        float nr = red(fadFromColour) + ( ((ratio * redDifference) +  ( (1-ratio)*random(redDifference))) * (inCount/numFadeInFrames));
        float ng = green(fadFromColour) + ( ((ratio * greenDifference) +  ( (1-ratio)*random(greenDifference))) * (inCount/numFadeInFrames));
        float nb = blue(fadFromColour) + ( ((ratio * blueDifference) +  ( (1-ratio)*random(blueDifference))) * (inCount/numFadeInFrames));

        color nc = color(nr, ng, nb);
        fill(nc);
        rect(i * xSpace, j *ySpace, xSpace, ySpace);
      }
    }
    popStyle();
  }
  void drawGrid(color [][] grid) {
    pushStyle();
    noStroke();
    float xSpace = width/grid.length;
    float ySpace = height/grid[0].length;
    for (int i=0; i<grid.length; i++) {
      for (int j=0; j<grid[i].length; j++) {
        color c = grid[i][j];

        fill(c);
        rect(i * xSpace, j *ySpace, xSpace, ySpace);
      }
    }
    popStyle();
  }
  color [][] getColourMask(PImage im) {
    float ratio = float(height)/float(width);
    int w = 50;
    int h  =int( w*ratio);

    color [][] grid = new int[w][h];
    PImage mask;

    if (isLeftScreen) {
      mask = im.get( int( im.width/4)-(w/2), int(im.height/4)-(h/2), w, h);
    } else if (isCentreScreen) {
      mask = im.get( int( im.width/4)-(w/2), int(im.height/2)-(h/2), w, h);
    } else {
      mask = im.get( int( im.width/4)-(w/2), int(im.height/3)-(h/2), w, h);
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