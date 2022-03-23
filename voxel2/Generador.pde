
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

class Generador {
  private final Lock queueLock = new ReentrantLock();
  
  public void exec(int x, int z, short[][][] chunkData, ConcurrentHashMap<PVector,Chunk> chunks) {
    queueLock.lock();
    
    try {
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

      chunkGenerar(x, z, chunkData, chunks);
      
      for (PVector p : voxel2.regenerateChunk) {
        Chunk c = chunks.get(p);
        if (c == null) {
          continue;
        }
        if (!c.getGenerated()) {
          c.setGenerated(true);
          chunkGenerar((int)p.x, (int)p.z, c.chunk, chunks);
        }
      }
      voxel2.regenerateChunk.clear();
    } finally {
      queueLock.unlock();
    }
  }
  
  void chunkGenerar(int x, int z, short[][][] chunkData, ConcurrentHashMap<PVector,Chunk> chunks) {
    PShape chunkMesh = createShape();
    chunkMesh.beginShape(TRIANGLE);
    chunkMesh.noStroke();
    
    for (int i = 0; i < chunkSize; i++) {
      for (int j = 0; j < chunkSize; j++) {
        for (int k = 0; k < chunkHeight; k++) {
          if (chunkData[i][k][j] == block.AIR.id) continue;
  
  
          if (k + 1 == chunkHeight && DEBUG_CHUNKFACES || k + 1 < chunkHeight && chunkData[i][k + 1][j] == block.AIR.id || k + 1 == chunkHeight ) {
            chunkMesh.fill(255, 0, 0);
            caraAbajo((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
          }
  
          if (k - 1 == -1 || k - 1 >= 0 && chunkData[i][k - 1][j] == block.AIR.id) {
            chunkMesh.fill(0, 255, 0);
            caraArriba((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
          }
  
  
          PVector dir = new PVector(x, 0, z - 1);
          if (j - 1 == -1 || j - 1 >= 0 && chunkData[i][k][j - 1] == block.AIR.id) {        
            if (j - 1 >= 0 && chunkData[i][k][j - 1] == block.AIR.id || j - 1 == -1 && !chunks.containsKey(dir)) {
              chunkMesh.fill(0, 0, 255);
              caraIzquierda((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
            } else if (j - 1 == -1 && chunks.containsKey(dir)) {
              Chunk chunk = chunks.get(dir);
               if (chunk.chunk[i][k][(((j - 1) % 16) + 16) % 16] == block.AIR.id) {
                 chunkMesh.fill(0, 0, 255);
                 caraIzquierda((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
               }
               chunk.setGenerated(false);
               voxel2.regenerateChunk.add(new PVector(x, 0, z - 1));
            }
          }
          
          dir = new PVector(x, 0, z + 1);
          if (j + 1 == chunkSize || j + 1 < chunkSize && chunkData[i][k][j + 1] == block.AIR.id) {
            if (j + 1 < chunkSize && chunkData[i][k][j + 1] == block.AIR.id || j + 1 == chunkSize && !chunks.containsKey(dir)) {
              chunkMesh.fill(255, 0, 255);
              caraDerecha((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
            } else if (j + 1 == chunkSize && chunks.containsKey(dir)) {
              Chunk chunk = chunks.get(dir);
               if (chunk.chunk[i][k][(((j + 1) % 16) + 16) % 16] == block.AIR.id) {
                 chunkMesh.fill(255, 0, 255);
                 caraDerecha((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
               }
              chunk.setGenerated(false);
              voxel2.regenerateChunk.add(new PVector(x, 0, z + 1));
            }
          }
  
          dir = new PVector(x - 1, 0, z);
          if (i - 1 == -1 || i - 1 >= 0 && chunkData[i - 1][k][j] == block.AIR.id) {
            if (i - 1 >= 0 && chunkData[i - 1][k][j] == block.AIR.id || i - 1 == -1 && !chunks.containsKey(dir)) {
              chunkMesh.fill(255, 255, 0);
              caraAtras((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
            } else if (i - 1 == -1 && chunks.containsKey(dir)) {
              Chunk chunk = chunks.get(dir);
               if (chunk.chunk[(((i - 1) % 16) + 16) % 16][k][j] == block.AIR.id) {
                chunkMesh.fill(255, 255, 0);
                caraAtras((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
               }
               chunk.setGenerated(false);
               voxel2.regenerateChunk.add(new PVector(x - 1, 0, z));
            }
          }
  
          dir = new PVector(x + 1, 0, z);
          if (i + 1 == chunkSize || i + 1 < chunkSize && chunkData[i + 1][k][j] == block.AIR.id) {
            if (i + 1 < chunkSize && chunkData[i + 1][k][j] == block.AIR.id || i + 1 == chunkSize && !chunks.containsKey(dir)) {
              chunkMesh.fill(255, 174, 0);
              caraFrente((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
            } else if (i + 1 == chunkSize && chunks.containsKey(dir)) {
              Chunk chunk = chunks.get(dir);
               if (chunk.chunk[(((i + 1) % 16) + 16) % 16][k][j] == block.AIR.id) {
                chunkMesh.fill(255, 174, 0);
                caraFrente((x * chunkSize) + i, k, (z * chunkSize) + j, chunkMesh);
               }
              chunk.setGenerated(false);
              voxel2.regenerateChunk.add(new PVector(x + 1, 0, z));
            }
          }
        }
      }
    }
    chunkMesh.endShape();
    
    Chunk chunk = new Chunk(chunkMesh, chunkData);
    chunks.put(new PVector(x,0,z), chunk); 
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

}
