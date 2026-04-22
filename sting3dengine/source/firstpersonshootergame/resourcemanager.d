/// Centralized asset cache
/// Loads models, textures, and sounds once, returns cached handles on repeat requests

module resourcemanager;

import std.stdio;
import std.string : toStringz, fromStringz;

import assimp;
import enginecore;

class ResourceManager
{
    /// Cache of already-imported Assimp scenes by file path
    /// We store the extracted mesh data, not the raw aiScene
    /// (because aiScene gets released after import)
    Model[string] mModelCache;

    /// Get or load a Model from a file path
    Model getModel(string path)
    {
        if (auto cached = path in mModelCache)
        {
            return *cached;
        }

        auto model = new Model(path);
        mModelCache[path] = model;
        writeln("[resource] cached model: ", path, " (", model.mMeshes.length, " meshes)");
        return model;
    }

    /// Report cache stats
    void printStats()
    {
        writeln("=== RESOURCE CACHE ===");
        writeln("  Models cached: ", mModelCache.length);
        foreach (path, model; mModelCache)
        {
            writeln("    ", path, " → ", model.mMeshes.length, " meshes");
        }
        writeln("======================");
    }
}