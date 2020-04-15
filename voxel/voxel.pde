import queasycam.*;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2ES2;

QueasyCam cam;
PJOGL pgl;
GL2ES2 gl;

color madera = color(166, 91, 12);
color hojas = color(13, 128, 0);

int chunk[][][];
int chunkSize = 22;
int chunkHeight = 256;

int alturaAgua = 195;

float posicionx = 0;
float posicionz = 0;
float velocidad = 0;
long seed = 0;

enum block {
  AIR(0), 
  DIRT(1),
  WATER(2),
  MADERA(3),
  HOJAS(4);
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
  cam.speed = 0.01;
  cam.sensitivity = 0.5;
  cam.position = new PVector(0, chunkHeight-22, 0);
  
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
  

  generateWorld();
}


void generateArbol(int x, int y, int z) {

  
  // Tronco
  for (int i = 0; i < 5; i++) {
    if (y - i > 0) {
      chunk[x][y - i][z] = block.MADERA.getBlock();
    }
  }
  
  // Hojas
  for (int i = -1; i < 2; i++) {
    for (int j = -1; j < 2; j++) {
      for (int k = 0; k < 3; k++) {
        if (x + i < chunkSize && x + i >= 0 && z + j < chunkSize && z + j >= 0 && y - k - 4 >= 0) {
          chunk[x + i][y - k - 4][z + j] = block.HOJAS.getBlock();
        }
      }
    }
  }

  
}

void caraAtras(float x, float y, float z) {
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 0, y + 1, z + 0);
  
  vertex(x + 0, y + 1, z + 0);
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 0, y + 1, z + 1);
}

void caraFrente(float x, float y, float z) {
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 1, y + 0, z + 0);
  vertex(x + 1, y + 1, z + 0);
  
  vertex(x + 1, y + 1, z + 1);
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 1, y + 1, z + 0);
}

void caraArriba(float x, float y, float z) {
  vertex(x + 1, y + 0, z + 0);
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 0, y + 0, z + 0);
  
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 0, y + 0, z + 0);
}

void caraAbajo(float x, float y, float z) {
  vertex(x + 1, y + 1, z + 1);
  vertex(x + 0, y + 1, z + 0);
  vertex(x + 0, y + 1, z + 1);
  
  
  vertex(x + 0, y + 1, z + 0);
  vertex(x + 1, y + 1, z + 1);
  vertex(x + 1, y + 1, z + 0);
}


void caraIzquierda(float x, float y, float z) {
  vertex(x + 1, y + 0, z + 0);
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 1, y + 1, z + 0);
  
  vertex(x + 1, y + 1, z + 0);
  vertex(x + 0, y + 0, z + 0);
  vertex(x + 0, y + 1, z + 0);
}

void caraDerecha(float x, float y, float z) {
  vertex(x + 0, y + 0, z + 1);
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 0, y + 1, z + 1);
  
  vertex(x + 0, y + 1, z + 1);
  vertex(x + 1, y + 0, z + 1);
  vertex(x + 1, y + 1, z + 1);
}

ArrayList<PVector> listaArboles;

void generateWorld() {
  posicionx += velocidad;
  
  listaArboles = new ArrayList<PVector>();
  
  noiseSeed(seed);
  randomSeed(seed);

  float yoff = posicionx;
  for (int j = 0; j < chunkSize; j++) {
    float xoff = posicionz;
    for (int i = 0; i < chunkSize; i++) {
      float altura = map(noise(xoff, yoff), 0, 1, chunkHeight / 2, chunkHeight - 10);
      chunk[i][(int)Math.floor(altura)][j] = block.DIRT.getBlock();
      
      for (int k = 0; k < chunkHeight; k++) {
        if (k > (int)Math.floor(altura)) {
          chunk[i][k][j] = block.DIRT.getBlock();
        } else {
          chunk[i][k][j] = block.AIR.getBlock();
        }
      }


      if ((int)Math.floor(altura) < alturaAgua) {
        float valor = altura - (int)altura;
        
        if (valor > .04 && valor < .05) {
          listaArboles.add(new PVector(i, (int)Math.floor(altura), j));
        }
      }
      


      xoff += 0.01;
    }
    yoff += 0.01;
  }
  
  for (PVector arbol : listaArboles) {
    generateArbol((int)arbol.x, (int)arbol.y, (int)arbol.z);
  }
  
  for (int i = 0; i < chunkSize; i++) {
    for (int j = 0; j < chunkSize; j++) {
      if (chunk[i][alturaAgua][j] == block.AIR.getBlock()) {
        chunk[i][alturaAgua][j] = block.WATER.getBlock();
      }
    }
  }
  

}

void renderWorld() {
  for (int i = 0; i < chunkSize; i++) {
    for (int j = 0; j < chunkSize; j++) {
      for (int k = 0; k < chunkHeight; k++) {
        if (chunk[i][k][j] != block.AIR.getBlock()) {
          cubo(i, k, j);
        }
      }
    }
  }
}


void cubo(float x, float y, float z) {
  beginShape(TRIANGLES);
  
  // ABAJO
  if (chunk[(int)x][(int)y][(int)z] == block.WATER.getBlock()) {
    fill(0, 149, 255, 100);
    caraAbajo(x, y, z);
  } else if ((y + 1 == chunkHeight && y > 0 && chunk[(int)x][(int)y][(int)z] == block.AIR.getBlock()) || (y >= 0 && y + 1 < chunkHeight && chunk[(int)x][(int)y + 1][(int)z] == block.AIR.getBlock())) {
    selectBlock(x, y, z, color(219, 105, 29));
    caraAbajo(x, y, z);
  }

      
  // ARRIBA
  if ((y - 1 == -1 && chunk[(int)x][(int)y][(int)z] == block.AIR.getBlock()) || (y - 1 == -1 && chunk[(int)x][(int)y][(int)z] == block.WATER.getBlock()) || (y >= 0 && y <= chunkHeight && chunk[(int)x][(int)y - 1][(int)z] == block.AIR.getBlock())) {
    if(chunk[(int)x][(int)y][(int)z] == block.DIRT.getBlock()) {
      fill(0, 255, 0);
    } else if (chunk[(int)x][(int)y][(int)z] == block.WATER.getBlock()) {
      fill(0, 149, 255, 100);
    } else {
      selectBlock(x,y,z, color(0, 255, 0));
    }
    caraArriba(x, y, z);
  }

  
  
  // IZQUIERDA
  if ((z - 1 == -1 && chunk[(int)x][(int)y][(int)z] == block.AIR.getBlock()) || (z > 0 && z <= chunkSize && chunk[(int)x][(int)y][(int)z - 1] == block.AIR.getBlock())) {
    selectBlock(x, y, z, color(164, 100, 25));
    caraIzquierda(x, y, z);
  }


  // DERECHA
  if ((z + 1 == chunkSize && chunk[(int)x][(int)y][(int)z] == block.AIR.getBlock()) || (z >= 0 && z + 1 < chunkSize && chunk[(int)x][(int)y][(int)z + 1] == block.AIR.getBlock())) {
    selectBlock(x, y, z, color(219, 105, 29));
    caraDerecha(x, y, z); 
  }
  
    
  // ATRAS
  if ((x - 1 == -1 && chunk[(int)x][(int)y][(int)z] == block.AIR.getBlock()) || (x > 0 && x <= chunkSize && chunk[(int)x - 1][(int)y][(int)z] == block.AIR.getBlock())) {
    selectBlock(x, y, z, color(100, 25, 164)); // morado
    caraAtras(x, y, z); 
  }


  // FRENTE
  if ((x + 1 == chunkSize && chunk[(int)x - 1][(int)y][(int)z] == block.AIR.getBlock()) || (x >= 0 && x + 1 < chunkSize && chunk[(int)x + 1][(int)y][(int)z] == block.AIR.getBlock())) {
    selectBlock(x, y, z, color(25, 100, 164)); // azul
    caraFrente(x, y, z); 
  }
  
  
  endShape();
}


void selectBlock(float x, float y, float z, color normal) {
    if (chunk[(int)x][(int)y][(int)z] == block.DIRT.getBlock()) {
      fill(normal);
    } else if (chunk[(int)x][(int)y][(int)z] == block.MADERA.getBlock()) {
      fill(madera);
    } else if (chunk[(int)x][(int)y][(int)z] == block.HOJAS.getBlock()) {
      fill(hojas);
    }
}


void draw() {
  background(0); //<>//
  hint(ENABLE_DEPTH_TEST);
  noStroke();
  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();
  gl.glEnable(GL.GL_CULL_FACE);
  gl.glCullFace(GL.GL_BACK);


  renderWorld();
  if (velocidad != 0) {
    generateWorld();
  }
  

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
      if (chunk[(int)cam.position.x][(int)cam.position.y][(int)cam.position.z] == block.AIR.getBlock()) {
        println("pone bloque");
        chunk[(int)cam.position.x][(int)cam.position.y][(int)cam.position.z]= block.DIRT.getBlock();
      } else {
        println("ya hay un bloque ahi");
      }
    }
    if (key == 'c') {
      println("quita bloque");
      chunk[(int)cam.position.x][(int)cam.position.y][(int)cam.position.z] = block.AIR.getBlock();
    }
  }
  
  if (key == 'v') {
    println(cam.position.y);
  }
  
  if (key == 'x') {
    velocidad += 0.01;
  } else if (key == 'z') {
    velocidad -= 0.01;
  }
  
  if (key == '.') {
    posicionx += 0.01;
    generateWorld();
  } else if (key == ',') {
    posicionx -= 0.01;
    generateWorld();
  } else if (key == 'o') {
    posicionz += 0.01;
    generateWorld();
  } else if (key == 'p') {
    posicionz -= 0.01;
    generateWorld();
  }

}
