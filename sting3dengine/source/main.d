import graphicsengine;

void main(string[] args)
{
    // Set up the engine, and run main loop (Engine has edit mode and play mode, which plays a game within the engine)
    GraphicsEngine app = new GraphicsEngine(4,1);
    app.Loop();
}
