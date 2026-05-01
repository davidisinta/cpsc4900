module model;

//standard library files
import std.stdio;
import std.string : toStringz, fromStringz;
import std.conv : to;

//project libraries
import assimp_c_api;
import surfaceassimp;
import geometry;
import enginecore;
import materials;
import linear;

/// A Model loaded via Assimp, following the LearnOpenGL convention.
/// Contains multiple meshes, each with its own surface and material info.
class Model
{
    /// One entry per mesh in the model
    struct SubMesh
    {
        ISurface surface;
        bool hasUVs;
        uint materialIndex;
    }

    SubMesh[] mMeshes;
    string mDirectory;

    /// Load a model from file
    this(string path)
    {
        // Extract directory for texture paths later
        auto lastSlash = path.length;
        foreach_reverse (i, c; path)
        {
            if (c == '/' || c == '\\')
            {
                lastSlash = i;
                break;
            }
        }
        mDirectory = path[0 .. lastSlash];

        loadModel(path);
    }

    /// Add all meshes to a scene tree under a parent node, using the given material.
    /// Returns the MeshNode array so caller can set model matrices.
    MeshNode[] addToScene(SceneTree sceneTree, IMaterial material, string namePrefix)
    {
        MeshNode[] nodes;
        foreach (i, submesh; mMeshes)
        {
            string nodeName = namePrefix ~ "_mesh" ~ i.to!string;
            auto node = new MeshNode(nodeName, submesh.surface, material);

            // Copy bounding radius from surface
            auto assimpSurf = cast(SurfaceAssimp)submesh.surface;
            if (assimpSurf !is null)
                node.mBoundingRadius = assimpSurf.mBoundingRadius;

            sceneTree.GetRootNode().AddChildSceneNode(node);
            nodes ~= node;
        }
        return nodes;
    }

    private void loadModel(string path)
    {
        auto scene = aiImportFile(path.toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals |
            aiProcess_JoinIdenticalVertices | aiProcess_FlipUVs);

        if (scene is null)
        {
            writeln("[Model] ERROR loading '", path, "': ", fromStringz(aiGetErrorString()));
            return;
        }

        writeln("[Model] loaded '", path, "' meshes=", scene.mNumMeshes,
                " materials=", scene.mNumMaterials);

        // Recursively walk the node tree (LearnOpenGL convention)
        processNode(scene.mRootNode, scene);

        aiReleaseImport(scene);
    }

    /// Recursively process each node and its children
    private void processNode(const(aiNode)* node, const(aiScene)* scene)
    {
        // Process each mesh in this node
        for (uint i = 0; i < node.mNumMeshes; i++)
        {
            uint meshIndex = node.mMeshes[i];
            auto mesh = scene.mMeshes[meshIndex];
            processMesh(mesh);
        }

        // Recurse into children
        for (uint i = 0; i < node.mNumChildren; i++)
        {
            processNode(node.mChildren[i], scene);
        }
    }

    /// Extract vertex data from an aiMesh and create a SurfaceAssimp
    private void processMesh(const(aiMesh)* mesh)
    {
        // Cast away const for SurfaceAssimp constructor
        auto mutableMesh = cast(aiMesh*)mesh;

        SubMesh sm;
        sm.surface = new SurfaceAssimp(mutableMesh);
        sm.hasUVs = mesh.mTextureCoords[0] !is null;
        sm.materialIndex = mesh.mMaterialIndex;
        mMeshes ~= sm;
    }


    /// Create new MeshNodes from cached mesh data.
    /// Each call produces independent nodes that can be positioned separately.
    // MeshNode[] createNodes(SceneTree sceneTree, IMaterial material, string namePrefix)
    // {
    //     import surfaceassimp;

    //     MeshNode[] nodes;
    //     foreach (i, submesh; mMeshes)
    //     {
    //         string nodeName = namePrefix ~ "_mesh" ~ i.to!string;
    //         auto node = new MeshNode(nodeName, submesh.surface, material);

    //         auto assimpSurf = cast(SurfaceAssimp)submesh.surface;
    //         if (assimpSurf !is null)
    //             node.mBoundingRadius = assimpSurf.mBoundingRadius;

    //         sceneTree.GetRootNode().AddChildSceneNode(node);
    //         nodes ~= node;
    //     }
    //     return nodes;
    // }

    MeshNode[] createNodes(SceneTree sceneTree, IMaterial material, string namePrefix, int maxMeshes = 0)
    {
        import surfaceassimp;

        MeshNode[] nodes;
        auto limit = (maxMeshes > 0 && maxMeshes < mMeshes.length) ? maxMeshes : mMeshes.length;
        
        foreach (i; 0 .. limit)
        {
            string nodeName = namePrefix ~ "_mesh" ~ i.to!string;
            auto node = new MeshNode(nodeName, mMeshes[i].surface, material);

            auto assimpSurf = cast(SurfaceAssimp)mMeshes[i].surface;
            if (assimpSurf !is null)
                node.mBoundingRadius = assimpSurf.mBoundingRadius;

            sceneTree.GetRootNode().AddChildSceneNode(node);
            nodes ~= node;
        }
        return nodes;
    }






}
