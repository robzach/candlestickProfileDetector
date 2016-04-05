class Candlestick implements Comparable {
  float jaggedness;
  PShape shape;
  String filename;

  Candlestick(float j, PShape p, String f) {
    jaggedness = j;
    shape = p;
    filename = f;
  }

  int compareTo (Object compareCandlestick) {
    int result = 0;
    if (jaggedness > ((Candlestick)compareCandlestick).jaggedness) {
      result = 1;
    } else if (jaggedness < ((Candlestick)compareCandlestick).jaggedness) {
      result = -1;
    }

    return result;
  }
}


/*
class Candlestick implements Comparable {
  float jaggedness;
  int nPoints;
  float xValues[];
  String filename;

  Candlestick(float j, int n, float points[], String f) {
    jaggedness = j;
    xValues = new float[n];
    filename = f;
  }

  int compareTo (Object compareCandlestick) {
    int result = 0;
    if (jaggedness > ((Candlestick)compareCandlestick).jaggedness) {
      result = 1;
    } else if (jaggedness < ((Candlestick)compareCandlestick).jaggedness) {
      result = -1;
    }

    return result;
  }
}
*/