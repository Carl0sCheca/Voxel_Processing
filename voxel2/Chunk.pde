import java.io.*;

static class Chunk implements Serializable {
  private short chunk[][][];
  private transient PShape mesh;

  private boolean generated;
  
  public Chunk(PShape mesh, short[][][] chunk) {
    generated = true;
    this.mesh = mesh;
    this.chunk = chunk;
  }
  
  public short[][][] getChunk() {
    return chunk;
  }
  
  public boolean getGenerated() {
    return generated;
  }


  public void setChunk(short[][][] chunk) {
    this.chunk = chunk;
  }

  public void setGenerated(boolean value) {
    generated = value;
  }
  
  public PShape getMesh() {
    return mesh;
  }

}
