import queasycam.*;
QueasyCam cam;

color marron = color(219, 105, 29); 

int chunk[][][];
int chunkSize = 16;
int chunkHeight = 256;

float posicion;


enum block {
  AIR(0), 
  DIRT(1);
  private final int value;
  
  private block(int value) {
    this.value = value;
  }
  
  public int getBlock() {
    return value;
  }
}

void setup() {
  size(800, 600, P3D);
  
  cam = new QueasyCam(this);
  cam.speed = 0.01;              // default is 3
  cam.sensitivity = 0.5;      // default is 2
  cam.position = new PVector(0, chunkHeight-22, 0);
  
  posicion = 0;

  background(0);
  frameRate(1000);
  
  chunk = new int[chunkSize][chunkHeight][chunkSize];
  
  //Cubo sin terreno
  //for (int i = 0; i < chunkSize; i++) {
  //  for (int j = 0; j < chunkSize; j++) {
  //    for (int k = 0; k < chunkHeight; k++) {
  //      //if (k > chunkHeight - 20) {
  //      //  chunk[i][k][j] = block.DIRT.getBlock();
  //      //} else {
  //      //  chunk[i][k][j] = block.AIR.getBlock();
  //      //}
        
  //      //float altura = noise(i,k,j);
  //      //boolean tierra = false;
  //    }
  //  } 
  //}
  

  generateWorld(false);


}

void caraAtras(float x, float y, float z) {
    //fill(marron);
    fill(100, 25, 164);
    vertex(x + 0, y + 0, z + 0);
    vertex(x + 0, y + 0, z + 1);
    vertex(x + 0, y + 1, z + 0);
    
    vertex(x + 0, y + 0, z + 1);
    vertex(x + 0, y + 1, z + 0);
    vertex(x + 0, y + 1, z + 1);
}

void caraFrente(float x, float y, float z) {
    //fill(marron);
    fill(25, 100, 164);
    vertex(x + 1, y + 0, z + 1);
    vertex(x + 1, y + 0, z + 0);
    vertex(x + 1, y + 1, z + 0);
    
    vertex(x + 1, y + 0, z + 1);
    vertex(x + 1, y + 1, z + 1);
    vertex(x + 1, y + 1, z + 0);
}

void caraArriba(float x, float y, float z) {
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 1, y + 0, z + 0);
  vertex(x + 1, y + 0, z + 1);
  
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 1, y + 0, z + 1);
}

void caraAbajo(float x, float y, float z) {
  fill(marron);
  vertex(x + 0, y + 1, z + 0);
  vertex(x + 1, y + 1, z + 1);
  vertex(x + 0, y + 1, z + 1);
  
  vertex(x + 0, y + 1, z + 0);
  vertex(x + 1, y + 1, z + 1);
  vertex(x + 1, y + 1, z + 0);
}


void caraIzquierda(float x, float y, float z) {
  //fill(marron);
  fill(164, 100, 25);
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 1, y + 0, z + 0);
  vertex(x + 1, y + 1, z + 0);
  
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 1, y + 1, z + 0);
  vertex(x + 0, y + 1, z + 0);
}

void caraDerecha(float x, float y, float z) {
  fill(marron);
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 0, y + 1, z + 1);
  
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 0, y + 1, z + 1);
  vertex(x + 1, y + 1, z + 1);
}

void generateWorld(boolean moving) {
  if (moving) {
    posicion += 0.001;
  } else {
    posicion = 0;
  }

  float yoff = posicion;
  for (int i = 0; i < chunkSize; i++) {
    float xoff = 0;
    for (int j = 0; j < chunkSize; j++) {
      float altura = map(noise(xoff, yoff), 0, 1, chunkHeight / 2, 0);
      chunk[i][(int)Math.floor(altura)][j] = block.DIRT.getBlock();
      for (int k = (int)Math.floor(altura) + 1; k < chunkHeight; k++) {
        chunk[i][k][j] = block.DIRT.getBlock();
      }
      
      xoff += 0.01;
    } 
    yoff += 0.01;
  }
  

}

void renderWorld(boolean moving) {
  for (int i = 0; i < chunkSize; i++) {
    for (int j = 0; j < chunkSize; j++) {
      for (int k = 0; k < chunkHeight; k++) {
        if (chunk[i][k][j] == block.DIRT.getBlock()) {
          cubo(i, k, j, color(0, 255, 0));
          if (moving) {
            chunk[i][k][j] = block.AIR.getBlock();
          }
        }
      }
    }
  }
}


void cubo(float x, float y, float z, color c) {
  beginShape(TRIANGLES);
  
  
  // ABAJO
  if (/*y + 1 == chunkHeight ||*/ (y > 0 && y + 1 < chunkHeight && chunk[(int)x][(int)y + 1][(int)z] == block.AIR.getBlock())) {
    caraAbajo(x, y, z);
  }

      
  // ARRIBA
  if (/*y - 1 == -1 ||*/ (y >= 0 && y < chunkHeight && chunk[(int)x][(int)y - 1][(int)z] == block.AIR.getBlock())) {
    fill(c);
    caraArriba(x, y, z);
  }

  
  
  // IZQUIERDA: si se descomenta, hay que poner z >= 0 en la condicion, asi en todas y en los z + 1 < chunksize, quitar el + 1
  if (/*z - 1 == -1 ||*/ (z > 0 && z < chunkSize && chunk[(int)x][(int)y][(int)z - 1] == block.AIR.getBlock())) {
    caraIzquierda(x, y, z);
  }


  // DERECHA
  if (/*z + 1 == chunkSize ||*/ (z > 0 && z + 1 < chunkSize && chunk[(int)x][(int)y][(int)z + 1] == block.AIR.getBlock())) {
    caraDerecha(x, y, z); 
  }
  
    
  // ATRAS
  if (/*x - 1 == -1 ||*/ (x > 0 && x < chunkSize && chunk[(int)x - 1][(int)y][(int)z] == block.AIR.getBlock())) {
    caraAtras(x, y, z); 
  }


  // FRENTE
  if (/*x + 1 == chunkSize ||*/ (x > 0 && x + 1 < chunkSize && chunk[(int)x + 1][(int)y][(int)z] == block.AIR.getBlock())) {
    caraFrente(x, y, z); 
  }
  
  
  endShape();
}


void draw() {
  background(0); //<>//
  hint(ENABLE_DEPTH_TEST);
  noStroke();

  
  renderWorld(false);

  camera();
  hint(DISABLE_DEPTH_TEST);  
  textSize(50);
  textAlign(LEFT,TOP);
  fill(255,0,0);
  text(frameRate, 0, 0);
}

void keyPressed() {
  if (key == '1') {
    cam.speed = 0.01; 
  } else if (key == '2') {
    cam.speed = 0.1;
  } else if (key == '3') {
    cam.speed = 0.35;
  }
  
  if (cam.position.x >= 0 && cam.position.z >= 0 && cam.position.x < chunkSize && cam.position.z < chunkSize && cam.position.y >= 0 && cam.position.y < chunkHeight) {
    if (key == 'f') {
      println("coloca bloque");
      chunk[(int)cam.position.x][(int)cam.position.y][(int)cam.position.z] = block.DIRT.getBlock();
    }
    if (key == 'c') {
      println("quita bloque");
      chunk[(int)cam.position.x][(int)cam.position.y][(int)cam.position.z] = block.AIR.getBlock();
    }
  }

}
