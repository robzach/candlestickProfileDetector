import java.util.*;
import java.io.*;
import processing.pdf.*;

ArrayList<Candlestick> candlestickList = new ArrayList<Candlestick>();

String[] imageNames; // string array holding names of every .jpg file in folder defined by variable folderPath
String folderPath = "/Users/rz/Documents/CMU/IACD/candlesticks/Met_data/resizedPulledImages";
String currentImage;

PImage img;
PShape l;
PShape s; // smoothed version of l

float boundingBox = 0.95; // 1 = total image considered; 0.5 = degenerate case: only dead center point of image considered
float bestThresh = 2.0;

boolean bFileSelected = false;
boolean bShowSmoothed = false; // show smoothed line
boolean bPrintSmoothedOutput = false;
boolean bMouseThresh = false;
boolean bAutoRun = false;

float thresh = 6.0;

float fBestThreshLeft = 0.0;
float fBestThreshSmoothed = 0.0;
boolean bShowBestThreshLeft = false;

//candlestickList = new ArrayList<Candlestick>();

void setup() {
  size(850, 502);

  imageNames = loadFilenames(folderPath);
  //println(imageNames); // diagnostic to ensure the software sees all the image files in the designated folder

  //selectInput("Pick an image:", "fileSelected");
  //while (!bFileSelected) delay(10); // wait for image to be selected

  //img = loadImage("/Users/rz/Documents/CMU/IACD/candlesticks/MET_data/resizedPulledImages/1190.jpg");
  //img = loadImage("/Users/rz/Documents/CMU/IACD/candlesticks/MET_data/resizedPulledImages/1183.jpg");

  // load one random image from the folder:
  //currentImage = imageNames[(int)random(imageNames.length)];
  //String currentImageString = folderPath + '/' + currentImage; // to form the complete absolute path
  //img = loadImage(currentImageString);
}

void draw() {
  noLoop();

  //if (bMouseThresh) thresh = mouseX/20.0; // adjust threshold actively by moving mouse right and left

  for (int i = 0; i < imageNames.length; i++) {
    currentImage = imageNames[i];
    String currentImageString = folderPath + '/' + currentImage; // to form the complete absolute path
    img = loadImage(currentImageString);

    background(255);
    image(img, 0, 0);
    loadPixels();

    leftThresh(thresh);

    buildS();

    candlestickList.add(new Candlestick (smoothedCurveJaggedness(s), s, currentImage));
  }

  makePDF();
}
/*
    // bounding rectangle showing image area being considered
 rectMode(CORNERS);
 stroke(255, 255, 0);
 rect(int(img.width*(1-boundingBox)), int(img.height*(1-boundingBox)), int(img.width*boundingBox), int(img.height*boundingBox));
 */

/*
    fill(0);
 text("thresh = " + thresh, 510, 10);
 text("left vertex count = " + l.getVertexCount(), 510, 25);
 text("bounding box = " + nf(boundingBox, 1, 2), 510, 55);
 text("current left side jaggedness score = " + currentLeftJaggedness(), 510, 70);
 text("current smoothed line jaggedness score = " + smoothedCurveJaggedness(), 510, 85);
 if (bShowBestThreshLeft) { 
 text("best left side jaggedness score = " + fBestThreshLeft, 510, 100);
 text("best threshhold value = " + bestThresh, 510, 115);
 text("best smoothed threshhold score = " + fBestThreshSmoothed, 510, 130);
 } else text("push space to compute best left side jaggedness score", 510, 100);
 text("image: " + currentImage, 510, 145);
 noFill();
 */


void fileSelected(File selection) {
  img = loadImage(selection.getAbsolutePath());
  bFileSelected = true;
}

//void bestThreshLeft() {
//  println("running bestThreshLeft()");
//  float bestScore = 1000000;
//  for (float i = 2.0; i < 30.0; i+=0.2) {
//    leftThresh(i);
//    if (currentLeftJaggedness() < bestScore) { 
//      println("currentLeftJaggedness(), i = " + currentLeftJaggedness() + " " + i);
//      bestScore = currentLeftJaggedness();
//      bestThresh = i;
//    }
//  }
//  fBestThreshLeft = bestScore;
//  //thresh = bestScore;
//}

float bestThreshSmoothed(PShape sh) {
  println("running bestThreshSmoothed()");
  float bestScore = 1000000;
  for (float i = 1.0; i < 30.0; i+=0.2) {
    leftThresh(i);
    if (smoothedCurveJaggedness(sh) < bestScore) { 
      println("smoothedCurveJaggedness(), i = " + smoothedCurveJaggedness(sh) + " " + i);
      bestScore = smoothedCurveJaggedness(sh);
      bestThresh = i;
    }
  }
  fBestThreshSmoothed = bestScore;
  thresh = bestThresh;
  return bestThresh;
  //leftThresh(thresh);
}

void leftThresh(float thresh) {
  l = createShape();
  l.beginShape();

  int medianWidth = 5; 
  int halfMedianWidth = medianWidth/2; // int divide!
  float neighborhoodA[] = new float[medianWidth];
  float neighborhoodB[] = new float[medianWidth]; 

  // block for finding left side edge, painted in red
  int starty = max(halfMedianWidth +1, int(img.height*(1-boundingBox)));
  int endy   = min(img.height- halfMedianWidth, int(img.height*boundingBox));
  int startx = max(halfMedianWidth +1, int(img.width*(1-boundingBox))); 
  int endx   = min(img.width- halfMedianWidth, int(img.width*0.6)); // run 60% across the image

  for (int y = starty; y < endy; y++ ) { // start in from the top
    for (int x = startx; x < endx; x++) { // start in from the left
      // Pixel location and color
      int loc = x + y*img.width;

      //neighborhoodA
      for (int dx=(0-halfMedianWidth); dx<=halfMedianWidth; dx++) {
        int locdx = loc + dx;
        color coldx = img.pixels[locdx];
        //float bridx =  brightness(coldx); 
        float bridx =  luminance(coldx); 
        neighborhoodA[dx+halfMedianWidth] = bridx;
      }
      // neighborhoodB
      for (int dx=(0-halfMedianWidth); dx<=halfMedianWidth; dx++) {
        int locdx = loc + dx -1;
        color coldx = img.pixels[locdx];
        //float bridx =  brightness(coldx); 
        float bridx =  luminance(coldx);
        neighborhoodB[dx+halfMedianWidth] = bridx;
      }

      float diff = abs(median(neighborhoodA) - median(neighborhoodB));

      // if you've found the left edge
      if (diff > thresh) {
        l.vertex(x, y); //  mark the point this happens in a contour
        break; // and jump down to the next line
      }
    }
  }
  l.endShape();
  l.setStroke(color(255, 0, 0));
  shape(l);
}

void buildS() {
  if (l.getVertexCount() > 8) { // just tests if there's the minimum needed amount of drawing done
    s = createShape();
    s.beginShape();

    for (int i = 4; i < l.getVertexCount() - 4; i++) { // go along l from its top to bottom
      int y = (int)l.getVertexY(i);
      int median[] = new int[9];
      for (int j = 0; j < 9; j++) { // list of 4 neighbors to left, self, and 4 to right
        median[j] = int(l.getVertexX(j+i-4));
      }
      median = sort(median);
      int x = median[4];

      s.vertex(x, y);
    }

    s.endShape();
    s.setStroke(color(0, 255, 0));
    shape(s);
  }
}
float currentLeftJaggedness() {
  float totalLeftJaggedness = 0;
  for (int i = 0; i < l.getVertexCount() - 1; i++) {
    totalLeftJaggedness += pow(l.getVertexX(i) - l.getVertexX(i+1), 4);
  }
  float leftJaggedness = totalLeftJaggedness / l.getVertexCount();
  return leftJaggedness;
}

float smoothedCurveJaggedness(PShape psh) {
  println("psh.getVertexX(3) = " + psh.getVertexX(3));
  println("psh.getVertexCount() = " + psh.getVertexCount());
  float totalCurveJaggedness = 0;
  for (int i = 0; i < psh.getVertexCount() - 2; i++) {
    totalCurveJaggedness += pow(psh.getVertexX(i) - psh.getVertexX(i+1), 4);
  }
  float curveJaggedness = totalCurveJaggedness / psh.getVertexCount();
  return curveJaggedness;
}

// this function copied shamelessly, unchangedly, from das Internet. Works like a charm.
String[] loadFilenames(String path) {
  File folder = new File(path);
  FilenameFilter filenameFilter = new FilenameFilter() {
    public boolean accept(File dir, String name) {
      return name.toLowerCase().endsWith(".jpg"); // change this to any extension you want
    }
  };
  return folder.list(filenameFilter);
}

// function to calculate median of any float array
float median(float[] array) {
  int n = array.length;
  array = sort(array);    
  if (n%2==0) {
    return ((array[(n/2)-1] + array[(n/2)]) / 2);
  } else return (array[n/2]);
}

void makePDF() {

  Collections.sort(candlestickList); // order candlesticks from least to most jagged outline

  int pdfWidth = candlestickList.size() * 200 + 400;
  PGraphics pdf = createGraphics(pdfWidth, 500, PDF, "squigglylines.pdf");
  pdf.beginDraw();
  pdf.background(255);
  pdf.fill(0);

  for (int i = 0; i < candlestickList.size(); i++) {
    PShape d; // copy of s to use for making drawing
    d = createShape();
    d.beginShape();
    Candlestick stick = candlestickList.get(i);

    for (int j = 0; j < stick.shape.getVertexCount(); j++) {
      float x = stick.shape.getVertexX(j);
      float y = stick.shape.getVertexY(j);
      float xOffset = stick.shape.getVertexX(0);
      float yOffset = stick.shape.getVertexY(0);
      d.vertex(x - xOffset, y - yOffset + 50);
    }

    d.scale(scaleValue(d));
    d.strokeWeight(0.25);
    d.stroke(0);

    pdf.translate(200, 0); // moves next squiggle 200 to the right; pushMatrix and popMatrix don't seem to matter for pdf rendering?
    //pdf.text(stick.filename + '\n' + stick.jaggedness, 0, 10);
    pdf.shape(d);
  }


  /*
  PShape d; // copy of s to use for making drawing
   d = createShape();
   d.beginShape();
   for (int i = 0; i < s.getVertexCount(); i++) {
   float x = s.getVertexX(i);
   float y = s.getVertexY(i);
   d.vertex(x, y);
   }
   d.strokeWeight(0.25);
   d.stroke(0);
   pdf.shape(d);
   */

  pdf.dispose();
  pdf.endDraw();
  println("made PDF");
}

float luminance(color col) {
  float lum = 0.2126*red(col) + 0.7152*green(col) + 0.0722*blue(col);
  return lum;
}

float scaleValue(PShape sh) {
  float shHeight = sh.getVertexY(sh.getVertexCount()-1) - sh.getVertexY(0);
  float scaleValue = 400 / shHeight;
  return scaleValue;
}

void keyPressed() {
  //if (key == CODED) {
  //  if (keyCode == UP) boundingBox += 0.01; // up arrow enlarges bounding box (area where analysis is done)
  //  if (keyCode == DOWN) boundingBox -= 0.01; // down arrow shrinks bounding box
  //  boundingBox = constrain(boundingBox, 0.51, 0.99);
  //}

  //if (key == 'l') {
  //  bShowBestThreshLeft = true;
  //  bestThreshLeft();
  //  float vertices[] = new float[l.getVertexCount()];
  //  for (int i = 0; i < l.getVertexCount(); i++) vertices[i] = l.getVertexX(i);
  //  //candlestickList.add(new Candlestick (smoothedCurveJaggedness(), l.getVertexCount(), vertices, currentImage));
  //  candlestickList.add(new Candlestick (smoothedCurveJaggedness(s), s, currentImage));
  //}

  //if (key == ' ') {
  //  bShowBestThreshLeft = true;
  //  bestThreshSmoothed();
  //}

  //if (key == 's') bShowSmoothed = !bShowSmoothed;

  //if (key == 'm') bMouseThresh = !bMouseThresh;

  //if (key == 'p') {
  //  bPrintSmoothedOutput = true;
  //}

  if (key == 'z') makePDF();

  if (key == 'n') {
    currentImage = imageNames[(int)random(imageNames.length)];
    String currentImageString = folderPath + '/' + currentImage; // to form the complete absolute path
    img = loadImage(currentImageString);
  }

  // big G for "go"
  if (key == 'G') {
    bAutoRun = true;
    for (int i = 0; i < 5; i++) {
      currentImage = imageNames[i];
      String currentImageString = folderPath + '/' + currentImage; // to form the complete absolute path
      img = loadImage(currentImageString);

      bShowBestThreshLeft = true;
      //bestThreshLeft();
      candlestickList.add(new Candlestick (smoothedCurveJaggedness(s), s, currentImage));
    }
    makePDF();
  }
}