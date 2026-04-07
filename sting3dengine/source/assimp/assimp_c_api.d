module assimp_c_api;

struct aiString {
    uint length;
    char[1024] data;
}

struct aiVector3D {
    float x, y, z;
}

struct aiColor4D {
    float r, g, b, a;
}

struct aiFace {
    uint mNumIndices;
    uint* mIndices;
}

struct aiVertexWeight {
    uint mVertexId;
    float mWeight;
}

struct aiMatrix4x4 {
    float a1, a2, a3, a4;
    float b1, b2, b3, b4;
    float c1, c2, c3, c4;
    float d1, d2, d3, d4;
}

struct aiBone {
    aiString mName;
    uint mNumWeights;
    aiVertexWeight* mWeights;
    aiMatrix4x4 mOffsetMatrix;
}

struct aiMesh {
    uint mPrimitiveTypes;
    uint mNumVertices;
    uint mNumFaces;
    aiVector3D* mVertices;
    aiVector3D* mNormals;
    aiVector3D* mTangents;
    aiVector3D* mBitangents;
    aiColor4D*[8] mColors;
    aiVector3D*[8] mTextureCoords;
    uint[8] mNumUVComponents;
    aiFace* mFaces;
    uint mNumBones;
    aiBone** mBones;
    uint mMaterialIndex;
    aiString mName;
    uint mNumAnimMeshes;
    void** mAnimMeshes;
    uint mMethod;
    // aiAABB is two aiVector3D (min + max)
    aiVector3D mAABBMin;
    aiVector3D mAABBMax;
    aiString** mTextureCoordsNames;
}

struct aiNode {
    aiString mName;
    aiMatrix4x4 mTransformation;
    aiNode* mParent;
    uint mNumChildren;
    aiNode** mChildren;
    uint mNumMeshes;
    uint* mMeshes;
}

struct aiScene {
    uint mFlags;
    aiNode* mRootNode;
    uint mNumMeshes;
    aiMesh** mMeshes;
    uint mNumMaterials;
    void** mMaterials;
    uint mNumAnimations;
    void** mAnimations;
}

enum : uint {
    aiProcess_Triangulate           = 0x8,
    aiProcess_GenNormals            = 0x20,
    aiProcess_GenSmoothNormals      = 0x40,
    aiProcess_FlipUVs               = 0x800000,
    aiProcess_JoinIdenticalVertices = 0x2,
}

extern(C)
{
    const(aiScene)* aiImportFile(const(char)* path, uint flags);
    void aiReleaseImport(const(aiScene)* scene);
    const(char)* aiGetErrorString();
}