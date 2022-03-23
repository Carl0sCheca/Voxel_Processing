import queasycam.*;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2ES2;

import java.io.*;
import java.io.BufferedInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import java.util.*;
import java.util.concurrent.*;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

QueasyCam cam;
PJOGL pgl;
GL2ES2 gl;


ConcurrentHashMap<PVector,Chunk> chunks = new ConcurrentHashMap<PVector, Chunk>();
final static int chunkSize = 16;
final static int chunkHeight = 256;

static Set<PVector> regenerateChunk = ConcurrentHashMap.newKeySet();

static Ejecutador t1 = null;

float inc = 0.01;

final static int chunkDistance = 12;
final static int MAXFPS = 60;

boolean DEBUG_CHUNKFACES = !true;

static enum block {
  AIR((short)0), 
  DIRT((short)1);

  private short id;

  private block(short id) {
    this.id = id;
  }

  public short getId() {
    return id;
  }
}

Generador e;

void setup() {
  size(800, 600, P3D);
  frameRate(MAXFPS);

  noiseSeed(0);

  e = new Generador();

  cam = new QueasyCam(this);
  cam.speed = 0.01;
  cam.sensitivity = 0.5;
  cam.position = new PVector(0, chunkHeight - 60, 0);
}

void generateTerrainChunk(int x, int z, short[][][] chunkData) {
  float zoff = z * inc * chunkSize;
  for (int j = 0; j < chunkSize; j++) {
    float xoff = x * inc * chunkSize;
    for (int i = 0; i < chunkSize; i++) {
      float altura = map(noise(xoff, 0, zoff), 0, 1, chunkHeight / 2, chunkHeight - 10);
      chunkData[i][(int)Math.ceil(altura)][j] = block.DIRT.id;

      float yoff = 0;
      for (int k = 0; k < chunkHeight; k++) {
        if (k > (int)Math.ceil(altura)) {
          float cave = noise(xoff, yoff, zoff);
          
          if (cave >= 0.5) {
            chunkData[i][k][j] = block.AIR.id;
          } else {
            chunkData[i][k][j] = block.DIRT.id;
          }
          
          
        } else {
          chunkData[i][k][j] = block.AIR.id;
        }
        yoff += inc;
      }

      xoff += inc;
    }
    zoff += inc;
  }
  
}

void generateChunk(int x, int z, short[][][] chunkData) {
  
  if (chunkData == null) {
    chunkData = new short[chunkSize][chunkHeight][chunkSize];
    if (t1 == null) {
      t1 = new Ejecutador(e, x, z, chunkData, chunks);
      t1.start();
    } else {
      if (!t1.isAlive()) {
        t1 = new Ejecutador(e, x, z, chunkData, chunks);
        t1.start();
      }
    }


    //generateTerrainChunk(x, z, chunkData);
  }
}

void generateChunk(int x, int z) {
  generateChunk(x, z, null);  
}


void stop() {
  println("salir");
}

void chunkControl() {
  int x = (int)Math.floor((cam.position.x / chunkSize));
  int z = (int)Math.floor((cam.position.z / chunkSize));
  
  //int x = 0;
  //int z = 0;
  
  for (int i = -(chunkDistance/2) + x; i < (chunkDistance/2) + x ; i++) {
    for (int j = -(chunkDistance/2) + z; j < (chunkDistance/2) + z; j++) {
      if (!chunks.containsKey(new PVector(i, 0, j))) {
        generateChunk(i, j);
      }
    }
  }
  
  ArrayList<PVector> aeliminar = new ArrayList<PVector>();
  
  for (HashMap.Entry<PVector, Chunk> p : chunks.entrySet()) {
    // dibuja los chunks
    shape(p.getValue().mesh, 0, 0);

    if (Math.abs(x - p.getKey().x) > chunkDistance / 2 || Math.abs(z - p.getKey().z) > chunkDistance / 2) {
        aeliminar.add(p.getKey());
    }
  }
  
  if (!aeliminar.isEmpty()) {
    for (PVector chunk : aeliminar) {
      chunks.remove(chunk);
    }
    System.gc();
  }
}

void draw() {
  background(0);
  hint(ENABLE_DEPTH_TEST);
  pgl = (PJOGL) beginPGL();  
  gl = pgl.gl.getGL2ES2();
  gl.glEnable(GL.GL_CULL_FACE);
  gl.glCullFace(GL.GL_BACK);


  chunkControl();

  camera();
  hint(DISABLE_DEPTH_TEST);  
  textSize(25);
  textAlign(LEFT, TOP);
  fill(255, 0, 0);
  text((int)frameRate + " fps", 0, 0);
  text("x: " + (Math.round(cam.position.x * 1000.0) / 1000.0) + " ~ z: " + Math.round(cam.position.z * 1000.0) / 1000.0 + "~ y: " + Math.round(cam.position.y * 1000.0) / 1000.0, 0, 25);
  text("Chunk: " + (int)(cam.position.x / chunkSize) + ":" + (int)(cam.position.z / chunkSize), 0, 50);
  text("Chunks cargados: " + chunks.size(), 0, 75);
  text("ChunkIN x: " + (int)(Math.abs(cam.position.x % chunkSize)) + " ~ z:" + (int)(Math.abs(cam.position.z % chunkSize)), 0, 100);
}

void keyPressed() {
  if (key == '4') {
    cam.speed = 0.001;
  } else if (key == '1') {
    cam.speed = 0.01;
  } else if (key == '2') {
    cam.speed = 0.1;
  } else if (key == '3') {
    cam.speed = 0.35;
  }

  if (key == ESC) {
    key = 0;
    noLoop();
    exit();
  }
  
  if (key == 'r') { 
    System.out.println(String.format("y: %s", cam.position.y));
  }
  
  if (key == 'f' || key == 'c') {
    int x = (int)Math.floor((cam.position.x / chunkSize));
    int z = (int)Math.floor((cam.position.z / chunkSize));
    
    int posx = (int)(Math.abs(cam.position.x % chunkSize));
    if (x < 0) {
      posx = chunkSize - 1 - posx;
    }
    int posz = (int)(Math.abs(cam.position.z % chunkSize));
    if (z < 0) {
      posz = chunkSize - 1 - posz;
    }
    
    if (key == 'f') {
      println("Pone bloque");
      Chunk elem = chunks.get(new PVector(x, 0, z));
      short chunk[][][] = elem.chunk;
      try {
        chunk[posx][(int)(cam.position.y)][posz] = 1;
      } catch (Exception e) {
        println("fuera de limites");
      }
      generateChunk(x, z, chunk);
      
    } else if (key == 'c') {
      println("Quita bloque");
      Chunk elem = chunks.get(new PVector(x, 0, z));
      short chunk[][][] = elem.chunk;
      try {
        chunk[posx][(int)(cam.position.y)][posz] = 0;
      } catch (Exception e) {
        println("fuera de limites");
      }
      
      generateChunk(x, z, chunk);
    }
  }
}


//void caraAtras(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 0, y + 0, z + 0);
//  chunkMesh.vertex(x + 0, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 1, z + 0);

//  chunkMesh.vertex(x + 0, y + 1, z + 0);
//  chunkMesh.vertex(x + 0, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 1, z + 1);
//}

//void caraFrente(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 1, y + 0, z + 0);
//  chunkMesh.vertex(x + 1, y + 1, z + 0);

//  chunkMesh.vertex(x + 1, y + 1, z + 1);
//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 1, y + 1, z + 0);
//}

//void caraArriba(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 1, y + 0, z + 0);
//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 0, z + 0);

//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 0, z + 0);
//}

//void caraAbajo(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 1, y + 1, z + 1);
//  chunkMesh.vertex(x + 0, y + 1, z + 0);
//  chunkMesh.vertex(x + 0, y + 1, z + 1);


//  chunkMesh.vertex(x + 0, y + 1, z + 0);
//  chunkMesh.vertex(x + 1, y + 1, z + 1);
//  chunkMesh.vertex(x + 1, y + 1, z + 0);
//}


//void caraIzquierda(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 1, y + 0, z + 0);
//  chunkMesh.vertex(x + 0, y + 0, z + 0);
//  chunkMesh.vertex(x + 1, y + 1, z + 0);

//  chunkMesh.vertex(x + 1, y + 1, z + 0);
//  chunkMesh.vertex(x + 0, y + 0, z + 0);
//  chunkMesh.vertex(x + 0, y + 1, z + 0);
//}

//void caraDerecha(float x, float y, float z, PShape chunkMesh) {
//  chunkMesh.vertex(x + 0, y + 0, z + 1);
//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 0, y + 1, z + 1);

//  chunkMesh.vertex(x + 0, y + 1, z + 1);
//  chunkMesh.vertex(x + 1, y + 0, z + 1);
//  chunkMesh.vertex(x + 1, y + 1, z + 1);
//}


void generateBlockChunk(short[][][] chunkData) {
  //  Bloque completo con cruz en el centro
  for (int i = 0; i < chunkSize; i++) {
    for (int j = 0; j < chunkSize; j++) {
      for (int k = 0; k < chunkHeight; k++) {
        if (k == 0 && (j == chunkSize / 2 || i == chunkSize / 2)) {
          chunkData[i][k][j] = block.AIR.id;  
        } else {
          chunkData[i][k][j] = block.DIRT.id;
        }
      }
    }
  }
}

void generacionRara(int x, int z, short[][][] chunkData) {
  float zoff = z * inc * chunkSize;
  for (int j = 0; j < chunkSize; j++) {
    float xoff = x * inc * chunkSize;
    for (int i = 0; i < chunkSize; i++) {
      float yoff = 0;
      for (int k = 0; k < chunkHeight; k++) {
        float coso = noise(xoff, yoff, zoff);

        if (coso >= 0.5) {
          //println(coso);
          chunkData[i][k][j] = block.DIRT.id;
        }
        
        yoff += inc;
      }
      xoff += inc;
    }
    zoff += inc;
  }
}
