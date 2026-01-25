// import graphics_app;

// void main(string[] args)
// {
//     GraphicsApp app = GraphicsApp(4,1);
//     app.Loop();
// }






import graphics_app;
import std.stdio;
import std.string : toStringz;

extern(C)
{
    struct aiScene;
    const(aiScene)* aiImportFile(const char*, uint);
    void aiReleaseImport(const(aiScene)*);
}

// smallest possible flag
enum uint aiProcess_Triangulate = 0x8;

void main(string[] args)
{
    // ---- ASSIMP LINK TEST ----
    auto scene = aiImportFile("assets/basic.obj".toStringz(), aiProcess_Triangulate);

    if (scene is null)
    {
        writeln("[ASSIMP] linked, but failed to load model (file missing or invalid)");
    }
    else
    {
        writeln("[ASSIMP] SUCCESS — Assimp is linked and working");
        aiReleaseImport(scene);
    }
    // --------------------------

    GraphicsApp app = GraphicsApp(4, 1);
    app.Loop();
}
