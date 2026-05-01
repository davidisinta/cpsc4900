// module assimp_c_api;

// struct aiString {
//     uint length;
//     char[1024] data;
// }

// struct aiVector3D {
//     float x, y, z;
// }

// struct aiColor4D {
//     float r, g, b, a;
// }

// struct aiFace {
//     uint mNumIndices;
//     uint* mIndices;
// }

// struct aiVertexWeight {
//     uint mVertexId;
//     float mWeight;
// }

// struct aiMatrix4x4 {
//     float a1, a2, a3, a4;
//     float b1, b2, b3, b4;
//     float c1, c2, c3, c4;
//     float d1, d2, d3, d4;
// }

// struct aiBone {
//     aiString mName;
//     uint mNumWeights;
//     aiVertexWeight* mWeights;
//     aiMatrix4x4 mOffsetMatrix;
// }

// struct aiMesh {
//     uint mPrimitiveTypes;
//     uint mNumVertices;
//     uint mNumFaces;
//     aiVector3D* mVertices;
//     aiVector3D* mNormals;
//     aiVector3D* mTangents;
//     aiVector3D* mBitangents;
//     aiColor4D*[8] mColors;
//     aiVector3D*[8] mTextureCoords;
//     uint[8] mNumUVComponents;
//     aiFace* mFaces;
//     uint mNumBones;
//     aiBone** mBones;
//     uint mMaterialIndex;
//     aiString mName;
//     uint mNumAnimMeshes;
//     void** mAnimMeshes;
//     uint mMethod;
//     aiVector3D mAABBMin;
//     aiVector3D mAABBMax;
//     aiString** mTextureCoordsNames;
// }

// struct aiNode {
//     aiString mName;
//     aiMatrix4x4 mTransformation;
//     aiNode* mParent;
//     uint mNumChildren;
//     aiNode** mChildren;
//     uint mNumMeshes;
//     uint* mMeshes;
// }

// struct aiQuaternion {
//     float w, x, y, z;
// }

// struct aiVectorKey {
//     double mTime;
//     aiVector3D mValue;
// }

// struct aiQuatKey {
//     double mTime;
//     aiQuaternion mValue;
// }

// struct aiNodeAnim {
//     aiString mNodeName;
//     uint mNumPositionKeys;
//     aiVectorKey* mPositionKeys;
//     uint mNumRotationKeys;
//     aiQuatKey* mRotationKeys;
//     uint mNumScalingKeys;
//     aiVectorKey* mScalingKeys;
//     uint mPreState;
//     uint mPostState;
// }

// struct aiAnimation {
//     aiString mName;
//     double mDuration;
//     double mTicksPerSecond;
//     uint mNumChannels;
//     aiNodeAnim** mChannels;
//     uint mNumMeshChannels;
//     void** mMeshChannels;
//     uint mNumMorphMeshChannels;
//     void** mMorphMeshChannels;
// }

// struct aiScene {
//     uint mFlags;
//     aiNode* mRootNode;
//     uint mNumMeshes;
//     aiMesh** mMeshes;
//     uint mNumMaterials;
//     void** mMaterials;
//     uint mNumAnimations;
//     aiAnimation** mAnimations;
// }

// enum : uint {
//     aiProcess_Triangulate           = 0x8,
//     aiProcess_GenNormals            = 0x20,
//     aiProcess_GenSmoothNormals      = 0x40,
//     aiProcess_FlipUVs               = 0x800000,
//     aiProcess_JoinIdenticalVertices = 0x2,
// }

// extern(C)
// {
//     const(aiScene)* aiImportFile(const(char)* path, uint flags);
//     void aiReleaseImport(const(aiScene)* scene);
//     const(char)* aiGetErrorString();
// }


module assimp_c_api;

// ------------------------------
// Core string / math types
// ------------------------------

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

struct aiQuaternion {
    float w, x, y, z;
}

struct aiMatrix4x4 {
    float a1, a2, a3, a4;
    float b1, b2, b3, b4;
    float c1, c2, c3, c4;
    float d1, d2, d3, d4;
}

// ------------------------------
// Mesh / skinning types
// ------------------------------

struct aiFace {
    uint mNumIndices;
    uint* mIndices;
}

struct aiVertexWeight {
    uint mVertexId;
    float mWeight;
}

// struct aiBone {
//     aiString mName;
//     uint mNumWeights;
//     aiVertexWeight* mWeights;
//     aiMatrix4x4 mOffsetMatrix;
// }

struct aiBone {
    aiString mName;
    uint mNumWeights;
    aiNode* mArmature;    // added — skeleton conversion node
    aiNode* mNode;        // added — bone node in scene
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
    aiVector3D mAABBMin;
    aiVector3D mAABBMax;
    aiString** mTextureCoordsNames;
}

// ------------------------------
// Node hierarchy / animation types
// ------------------------------

struct aiNode {
    aiString mName;
    aiMatrix4x4 mTransformation;
    aiNode* mParent;
    uint mNumChildren;
    aiNode** mChildren;
    uint mNumMeshes;
    uint* mMeshes;
}

struct aiVectorKey {
    double mTime;
    aiVector3D mValue;
}

struct aiQuatKey {
    double mTime;
    aiQuaternion mValue;
}

struct aiNodeAnim {
    aiString mNodeName;
    uint mNumPositionKeys;
    aiVectorKey* mPositionKeys;
    uint mNumRotationKeys;
    aiQuatKey* mRotationKeys;
    uint mNumScalingKeys;
    aiVectorKey* mScalingKeys;
    uint mPreState;
    uint mPostState;
}

struct aiAnimation {
    aiString mName;
    double mDuration;
    double mTicksPerSecond;
    uint mNumChannels;
    aiNodeAnim** mChannels;
    uint mNumMeshChannels;
    void** mMeshChannels;
    uint mNumMorphMeshChannels;
    void** mMorphMeshChannels;
}

// ------------------------------
// Material / texture types
// ------------------------------

// Opaque material type: we only ever pass pointers to Assimp APIs.
struct aiMaterial {}

struct aiTexel {
    ubyte b, g, r, a;
}

// If your Assimp version complains about mFilename, remove that field.
// Most current builds include it.
struct aiTexture {
    uint mWidth;
    uint mHeight;
    char[9] achFormatHint;
    aiTexel* pcData;
    aiString mFilename;
}

// ------------------------------
// Scene
// ------------------------------

struct aiScene {
    uint mFlags;
    aiNode* mRootNode;

    uint mNumMeshes;
    aiMesh** mMeshes;

    uint mNumMaterials;
    aiMaterial** mMaterials;

    uint mNumAnimations;
    aiAnimation** mAnimations;

    uint mNumTextures;
    aiTexture** mTextures;
}

// ------------------------------
// Post-process flags
// ------------------------------

enum : uint {
    aiProcess_CalcTangentSpace       = 0x1,
    aiProcess_JoinIdenticalVertices  = 0x2,
    aiProcess_Triangulate            = 0x8,
    aiProcess_GenNormals             = 0x20,
    aiProcess_GenSmoothNormals       = 0x40,
    aiProcess_FlipUVs                = 0x800000,
}

// ------------------------------
// Material / texture enums
// ------------------------------

enum : int {
    aiReturn_SUCCESS     = 0,
    aiReturn_FAILURE     = -1,
    aiReturn_OUTOFMEMORY = -3,
}

enum : uint {
    aiTextureType_NONE               = 0,
    aiTextureType_DIFFUSE            = 1,
    aiTextureType_SPECULAR           = 2,
    aiTextureType_AMBIENT            = 3,
    aiTextureType_EMISSIVE           = 4,
    aiTextureType_HEIGHT             = 5,
    aiTextureType_NORMALS            = 6,
    aiTextureType_SHININESS          = 7,
    aiTextureType_OPACITY            = 8,
    aiTextureType_DISPLACEMENT       = 9,
    aiTextureType_LIGHTMAP           = 10,
    aiTextureType_REFLECTION         = 11,
    aiTextureType_BASE_COLOR         = 12,
    aiTextureType_NORMAL_CAMERA      = 13,
    aiTextureType_EMISSION_COLOR     = 14,
    aiTextureType_METALNESS          = 15,
    aiTextureType_DIFFUSE_ROUGHNESS  = 16,
    aiTextureType_AMBIENT_OCCLUSION  = 17,
}

// ------------------------------
// Assimp C API
// ------------------------------

extern(C)
{
    const(aiScene)* aiImportFile(const(char)* path, uint flags);
    void aiReleaseImport(const(aiScene)* scene);
    const(char)* aiGetErrorString();

    // Material queries
    int aiGetMaterialString(
        const(aiMaterial)* pMat,
        const(char)* pKey,
        uint type,
        uint index,
        aiString* pOut
    );

    uint aiGetMaterialTextureCount(
        const(aiMaterial)* pMat,
        uint type
    );

    int aiGetMaterialTexture(
        const(aiMaterial)* pMat,
        uint type,
        uint index,
        aiString* path,
        uint* mapping,
        uint* uvindex,
        float* blend,
        uint* op,
        uint* mapmode,
        uint* flags
    );
}
