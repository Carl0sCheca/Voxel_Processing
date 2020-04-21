import org.nustaq.kson.*;
import org.nustaq.logging.*;
import org.nustaq.net.*;
import org.nustaq.offheap.*;
import org.nustaq.offheap.bytez.*;
import org.nustaq.offheap.bytez.bytesource.*;
import org.nustaq.offheap.bytez.malloc.*;
import org.nustaq.offheap.bytez.niobuffers.*;
import org.nustaq.offheap.bytez.onheap.*;
import org.nustaq.offheap.structs.*;
import org.nustaq.offheap.structs.structtypes.*;
import org.nustaq.offheap.structs.unsafeimpl.*;
import org.nustaq.serialization.*;
import org.nustaq.serialization.annotations.*;
import org.nustaq.serialization.coders.*;
import org.nustaq.serialization.minbin.*;
import org.nustaq.serialization.serializers.*;
import org.nustaq.serialization.simpleapi.*;
import org.nustaq.serialization.util.*;

import queasycam.*;
import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2ES2;

import java.io.*;
import java.io.BufferedInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import java.util.*;
import java.util.concurrent.ConcurrentLinkedQueue;

QueasyCam cam;
PJOGL pgl;
GL2ES2 gl;


static FSTConfiguration conf = FSTConfiguration.createDefaultConfiguration();

HashMap<PVector,Chunk> chunks = new HashMap<PVector, Chunk>();
static int chunkSize = 16;
static int chunkHeight = 256;

float inc = 0.01;

static int chunkDistance = 16;

boolean DEBUG_CHUNKFACES = true;


ConcurrentLinkedQueue<HashMap.Entry<PVector, Chunk>> toSerializeQueue = new ConcurrentLinkedQueue<HashMap.Entry<PVector, Chunk>>();
ConcurrentLinkedQueue<PVector> toDeSerializeQueue = new ConcurrentLinkedQueue<PVector>();

Thread serializador;
Thread deserializador;

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

void setup() {
  size(800, 600, P3D);
  frameRate(1000);

  noiseSeed(0);

  conf.registerClass(short[][][].class);
  conf.registerClass(short[][].class);
  conf.registerClass(short[].class);
  conf.registerClass(Chunk.class);
  

  cam = new QueasyCam(this);
  cam.speed = 0.01;
  cam.sensitivity = 0.5;
  cam.position = new PVector(0, chunkHeight-22, 0);
  
  //serializador = new Thread(new Runnable() {
  //  public void run() {
  //    while (true) {
  //      try {
  //        Thread.sleep(5000);
  //        if (!toSerializeQueue.isEmpty()) {
  //          for (HashMap.Entry<PVector, Chunk> map : toSerializeQueue) {
  //            serializar(map.getValue(), map.getKey());
  //            toSerializeQueue.remove(map);
  //          }
  //        }
  //      } catch (Exception e) {
  //        println(e);
  //      }
  //    }
  //  }
  //});
  
  //deserializador = new Thread(new Runnable() {
  //  public void run() {
  //    while (true) {
  //      try {
  //        Thread.sleep(6000);
  //        if (!toDeSerializeQueue.isEmpty()) {
  //          for (PVector pos : toDeSerializeQueue) {
  //            Chunk a = deserializar(pos);
  //            generateChunk((int)pos.x, (int)pos.z, a.getChunk());
  //            toDeSerializeQueue.remove(pos);
  //          }
  //        }
  //      } catch (Exception e) {
  //        println(e);
  //      }
  //    }
  //  }
  //});
  
  //serializador.start();
  //deserializador.start();
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
    generateTerrainChunk(x, z, chunkData);
    //generateBlockChunk(chunkData);
  }
  
  PShape chunkMesh = createShape();
  chunkMesh.beginShape(TRIANGLE);
  chunkMesh.noStroke();
  //chunkMesh.stroke(0);

  for (int i = 0; i < chunkSize; i++) {
    for (int j = 0; j < chunkSize; j++) {
      for (int k = 0; k < chunkHeight; k++) {
        if (chunkData[i][k][j] == block.AIR.id) continue;


        if (k + 1 == chunkSize && DEBUG_CHUNKFACES || k + 1 < chunkHeight && chunkData[i][k + 1][j] == block.AIR.id) {
          chunkMesh.fill(255, 0, 0);
          caraAbajo((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }

        if (k - 1 == -1 || k - 1 >= 0 && chunkData[i][k - 1][j] == block.AIR.id) {
          chunkMesh.fill(0, 255, 0);
          caraArriba((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }


        if (j - 1 == -1 && DEBUG_CHUNKFACES || j - 1 >= 0 && chunkData[i][k][j - 1] == block.AIR.id) {
          chunkMesh.fill(0, 0, 255);
          caraIzquierda((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }


        if (j + 1 == chunkSize && DEBUG_CHUNKFACES || j + 1 < chunkSize && chunkData[i][k][j + 1] == block.AIR.id) {
          chunkMesh.fill(255, 0, 255);
          caraDerecha((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }

        if (i - 1 == -1 && DEBUG_CHUNKFACES || i - 1 >= 0 && chunkData[i - 1][k][j] == block.AIR.id) {
          chunkMesh.fill(255, 255, 0);
          caraAtras((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }

        if (i + 1 == chunkSize && DEBUG_CHUNKFACES || i + 1 < chunkSize && chunkData[i + 1][k][j] == block.AIR.id) {
          chunkMesh.fill(255, 174, 0);
          caraFrente((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
        }
      }
    }
  }
  chunkMesh.endShape();
  
  Chunk chunk = new Chunk(chunkMesh, chunkData);
  chunks.put(new PVector(x,0,z), chunk);
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
  
  for (int i = -(chunkDistance/2) + x; i < (chunkDistance/2) + x ; i++) {
    for (int j = -(chunkDistance/2) + z; j < (chunkDistance/2) + z; j++) {
      if (!chunks.containsKey(new PVector(i, 0, j))) {
        File f = dataFile(i + "_" + j + ".bin");
        boolean exists = f.isFile();
        if (!exists) {
          generateChunk(i, j);
        } else {
          //toDeSerializeQueue.add(new PVector(i, 0, j));
          //Chunk chunk = deserializar(new PVector(i, 0, j));
          //generateChunk(i, j, chunk.getChunk());
        }
      }
    }
  }
}

void draw() {
  background(0);
  hint(ENABLE_DEPTH_TEST);
  //pgl = (PJOGL) beginPGL();  
  //gl = pgl.gl.getGL2ES2();
  //gl.glEnable(GL.GL_CULL_FACE);
  //gl.glCullFace(GL.GL_BACK);


  chunkControl();


  ArrayList<PVector> aeliminar = new ArrayList<PVector>();
  
  for (HashMap.Entry<PVector, Chunk> p : chunks.entrySet()) {
    shape(p.getValue().mesh, 0, 0);
    
    int x = (int)Math.floor((cam.position.x / chunkSize));
    int z = (int)Math.floor((cam.position.z / chunkSize));
    if (Math.abs(x - p.getKey().x) > chunkDistance / 2 || Math.abs(z - p.getKey().z) > chunkDistance / 2) {
        aeliminar.add(p.getKey());
        //serializar(p.getValue(), p.getKey());
        toSerializeQueue.add(p);
    }
  }
  
  if (!aeliminar.isEmpty()) {
    for (PVector chunk : aeliminar) {
      chunks.remove(chunk);
    }
    System.gc();
  }

  camera();
  hint(DISABLE_DEPTH_TEST);  
  textSize(25);
  textAlign(LEFT, TOP);
  fill(255, 0, 0);
  text((int)frameRate + " fps", 0, 0);
  text("x: " + (Math.round(cam.position.x * 1000.0) / 1000.0) + " ~ z: " + Math.round(cam.position.z * 1000.0) / 1000.0, 0, 25);
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
    //serializador.interrupt();
    //deserializador.interrupt();
    //for (HashMap.Entry<PVector, Chunk> p : chunks.entrySet()) {
    //  serializar(p.getValue(), p.getKey());
    //}
    exit();
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
      //serializar(elem, new PVector((int)(Math.abs(cam.position.x % chunkSize)), (int)(Math.abs(cam.position.z % chunkSize))));
      
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
      //serializar(elem, new PVector((int)(Math.abs(cam.position.x % chunkSize)), (int)(Math.abs(cam.position.z % chunkSize))));
    }
  }
}


void serializar(Chunk chunk, PVector pos) {
  //try {    
  //  FileOutputStream file = new FileOutputStream(sketchPath("data/") + (int)pos.x + "_" + (int)pos.z + ".bin");
  //  ObjectOutputStream out = new ObjectOutputStream(file); 
      
  //  out.writeObject(chunk); 
      
  //  out.close(); 
  //  file.close(); 
  //} catch(IOException ex) { 
  //  System.out.println(ex); 
  //}
  
  try {
    FileOutputStream file = new FileOutputStream(sketchPath("data/") + (int)pos.x + "_" + (int)pos.z + ".bin");
    FSTObjectOutput out = new FSTObjectOutput(file);
    out.writeObject(chunk, Chunk.class);
    out.close();
  } catch(Exception e) { 
    println(e); 
  }
}

Chunk deserializar(PVector pos) {
  Chunk chunk = null; 
 
  //try {    
  //  FileInputStream file = new FileInputStream(sketchPath("data/") + (int)pos.x + "_" + (int)pos.z + ".bin"); 
  //  ObjectInputStream in = new ObjectInputStream(file); 
      
    
  //  chunk = (Chunk)in.readObject(); 
      
  //  in.close(); 
  //  file.close();
  
  //} catch(IOException ex) { 
  //  println("IOException is caught"); 
  //} catch(ClassNotFoundException ex) { 
  //  println("ClassNotFoundException is caught"); 
  //}
  
  try {
    FileInputStream file = new FileInputStream(sketchPath("data/") + (int)pos.x + "_" + (int)pos.z + ".bin");
    FSTObjectInput in = new FSTObjectInput(file);
    chunk = (Chunk)in.readObject(Chunk.class);
    in.close();
  } catch (Exception e) {
    println(e);
  }
  
  return chunk;
}


void caraAtras(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 0, y + 0, z + 0);
  chunkMesh.vertex(x + 0, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 1, z + 0);

  chunkMesh.vertex(x + 0, y + 1, z + 0);
  chunkMesh.vertex(x + 0, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 1, z + 1);
}

void caraFrente(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 1, y + 0, z + 0);
  chunkMesh.vertex(x + 1, y + 1, z + 0);

  chunkMesh.vertex(x + 1, y + 1, z + 1);
  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 1, y + 1, z + 0);
}

void caraArriba(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 1, y + 0, z + 0);
  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 0, z + 0);

  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 0, z + 0);
}

void caraAbajo(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 1, y + 1, z + 1);
  chunkMesh.vertex(x + 0, y + 1, z + 0);
  chunkMesh.vertex(x + 0, y + 1, z + 1);


  chunkMesh.vertex(x + 0, y + 1, z + 0);
  chunkMesh.vertex(x + 1, y + 1, z + 1);
  chunkMesh.vertex(x + 1, y + 1, z + 0);
}


void caraIzquierda(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 1, y + 0, z + 0);
  chunkMesh.vertex(x + 0, y + 0, z + 0);
  chunkMesh.vertex(x + 1, y + 1, z + 0);

  chunkMesh.vertex(x + 1, y + 1, z + 0);
  chunkMesh.vertex(x + 0, y + 0, z + 0);
  chunkMesh.vertex(x + 0, y + 1, z + 0);
}

void caraDerecha(float x, float y, float z, PShape chunkMesh) {
  chunkMesh.vertex(x + 0, y + 0, z + 1);
  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 0, y + 1, z + 1);

  chunkMesh.vertex(x + 0, y + 1, z + 1);
  chunkMesh.vertex(x + 1, y + 0, z + 1);
  chunkMesh.vertex(x + 1, y + 1, z + 1);
}


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
