class Ejecutador extends Thread{

  Generador e;
  int x;
  int z;
  short[][][] chunkData;
  ConcurrentHashMap<PVector,Chunk> chunks;
  
  public Ejecutador(Generador e, int x, int z, short[][][] chunkData, ConcurrentHashMap<PVector,Chunk> chunks) {
    this.e = e;
    this.x = x;
    this.z = z;
    this.chunkData = chunkData;
    this.chunks = chunks;
  }
  
  public void run(){
    e.exec(this.x, this.z, this.chunkData, this.chunks);
  }
}
