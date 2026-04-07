module assimp_c_api;

import std.string : fromStringz;

// Opaque pointer — we don't access fields directly yet
alias aiScene = void;

// Post-processing flags
enum : uint {
    aiProcess_Triangulate           = 0x8,
    aiProcess_FlipUVs               = 0x800000,
    aiProcess_GenNormals            = 0x20,
    aiProcess_GenSmoothNormals      = 0x40,
    aiProcess_JoinIdenticalVertices = 0x2,
}

extern(C)
{
    const(aiScene)* aiImportFile(const(char)* path, uint flags);
    void aiReleaseImport(const(aiScene)* scene);
    const(char)* aiGetErrorString();

    // Scene accessors
    uint aiScene_GetNumMeshes(const(aiScene)* scene);
    uint aiScene_GetNumMaterials(const(aiScene)* scene);
    uint aiScene_GetNumAnimations(const(aiScene)* scene);
}