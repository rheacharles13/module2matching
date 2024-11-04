import processing.serial.*;

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

int canvasSize = 500;
int analogMax = 4095;

PImage img1, img2;  // Two halves of the image to load

float img1Pos, img2Pos;
boolean isMatched = false;
boolean buttonPressed = false; // State of the button
boolean buttonState = false;   // Additional variable to track button state

// Image counter to cycle through t1.jpg, t2.jpg, etc.
int imageCounter = 1;

void setup() {
  size(640, 360);
  noStroke();

  // Setup serial port
  printArray(Serial.list());
  String portName = Serial.list()[2]; // Select the correct port
  myPort = new Serial(this, portName, 9600);

  // Initialize first round of images
  loadImages();

  // Scale factor to fit images to canvas
  float scaleFactor = min((float)width / img1.width, (float)(height / 2) / img1.height);

  // Ensure the random position keeps the image within the screen
  float img1Width = img1.width * scaleFactor;
  img1Pos = random(-img1Width / 2, width - img1Width / 2); // Random position for top half
}

void draw() {
  background(255);

  // Read joystick data if available
  if (myPort.available() > 0) {  
    val = myPort.readStringUntil('\n');
  }

  val = trim(val);
  if (val != null && !val.equals("")) {
    int[] xyzp = int(split(val, ','));

    if (xyzp.length == 4) {
      int x = xyzp[0];
      int y = xyzp[1];
      int z = xyzp[2];  // Button
      int p = xyzp[3];  // Potentiometer

      // Map joystick X value to directly control the x-position of the bottom half
      img2Pos = map(x, 0, analogMax, -width / 2, width / 2);

      // Handle button press (to move to the next round)
      if (z == 1 && !buttonPressed) {
        buttonPressed = true;
        buttonState = true; // Button is currently pressed
        moveToNextRound(); // Switch to the next round (load next images)
      }
      if (z == 0) {
        buttonPressed = false;
        buttonState = false; // Button is released
      }

      float hue = map(p, 0, analogMax, 0, 255);
      colorMode(HSB, 255);
      tint(hue, 150, 255);  // Apply a tint with hue based on potentiometer value
    }
  }

  // Calculate scaling to fit the canvas while maintaining aspect ratio
  float scaleFactor = min((float)width / img1.width, (float)(height / 2) / img1.height);

  // Display the first half of the image (random position, scaled)
  float img1Width = img1.width * scaleFactor;
  float img1Height = img1.height * scaleFactor;
  image(img1, img1Pos, 0, img1Width, img1Height);

  // Display the second half of the image (directly controlled by joystick, scaled)
  float img2Width = img2.width * scaleFactor;
  float img2Height = img2.height * scaleFactor;
  image(img2, img2Pos, height / 2, img2Width, img2Height);

  // Real-time check for match (based on x-coordinates of top and bottom image halves)
  checkMatch();

  // Show match result in real time
  if (isMatched) {
    fill(0, 255, 0);  // Green text for matched
    textSize(32);
    textAlign(CENTER);
    text("Matched!", width / 2, height / 2 + 100);
  } else {
    fill(255, 0, 0);  // Red text for not matched
    textSize(32);
    textAlign(CENTER);
    text("Not Matched!", width / 2, height / 2 + 100);
  }
}

void checkMatch() {
  // Compare horizontal positions (x-coordinates) of both image halves
  if (abs(img1Pos - img2Pos) < 50) {  // Adjust tolerance as needed
    isMatched = true;
  } else {
    isMatched = false;
  }
}

void moveToNextRound() {
  // Cycle through the image pairs: t1.jpg & b1.jpg, t2.jpg & b2.jpg, etc.
  imageCounter++;
  if (imageCounter > 4) {
    imageCounter = 1;  // Restart after the last image pair
  }
  loadImages();  // Load the next set of images
}

void loadImages() {
  // Load the next pair of top and bottom images based on imageCounter
  img1 = loadImage("/Users/rheacharles/Downloads/module2images/t" + imageCounter + ".jpg");
  img2 = loadImage("/Users/rheacharles/Downloads/module2images/b" + imageCounter + ".jpg");
  
  // Reset random position for the top half
  float scaleFactor = min((float)width / img1.width, (float)(height / 2) / img1.height);
  float img1Width = img1.width * scaleFactor;
  img1Pos = random(-img1Width / 2, width - img1Width / 2); // Random position for top half
}
