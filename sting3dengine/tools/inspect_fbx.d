/// FBX / glTF Asset Inspector (Final)
/// ==================================
/// Standalone tool to inspect 3D model files for:
///   - meshes, materials, textures
///   - bones and unique bone list
///   - animations and channels
///   - node hierarchy
///   - FPS-relevant named nodes like camera / Weapon / Muzzle / Slide
///
/// BUILD:
///   ldc2 tools/inspect_fbx.d source/assimp/assimp_c_api.d \
///       -L-L/opt/homebrew/lib -L-lassimp -of=tools/inspect_fbx
///
/// RUN:
///   ./tools/inspect_fbx <path_to_fbx_or_gltf>
///   ./tools/inspect_fbx <path_to_fbx_or_gltf> --full-tree
///
/// EXAMPLE:
///   ./tools/inspect_fbx assets/weapons/glock/Glock.fbx
///
/// NOTES:
///   - This inspects raw source assets.
///   - If your project overrides materials in code, the FBX material/texture refs
///     may not exactly match in-game runtime materials.
///   - This file assumes your assimp_c_api.d includes:
///       aiMaterial
///       aiTexture
///       scene.mNumTextures / scene.mTextures
///       aiGetMaterialString
///       aiGetMaterialTextureCount
///       aiGetMaterialTexture

import std.stdio;
import std.string : toStringz;
import std.algorithm : sort, canFind;
import std.array : appender;
import std.conv : to;
import std.math : min, max;
import assimp_c_api;
import std.math : min, max;
import std.string : toStringz, toLower;

// ------------------------------
// Texture type labels
// ------------------------------

struct TextureSlotDesc {
    string name;
    uint typeId;
}

immutable TextureSlotDesc[] gTextureSlots = [
    TextureSlotDesc("DIFFUSE",           aiTextureType_DIFFUSE),
    TextureSlotDesc("SPECULAR",          aiTextureType_SPECULAR),
    TextureSlotDesc("AMBIENT",           aiTextureType_AMBIENT),
    TextureSlotDesc("EMISSIVE",          aiTextureType_EMISSIVE),
    TextureSlotDesc("HEIGHT",            aiTextureType_HEIGHT),
    TextureSlotDesc("NORMALS",           aiTextureType_NORMALS),
    TextureSlotDesc("SHININESS",         aiTextureType_SHININESS),
    TextureSlotDesc("OPACITY",           aiTextureType_OPACITY),
    TextureSlotDesc("DISPLACEMENT",      aiTextureType_DISPLACEMENT),
    TextureSlotDesc("LIGHTMAP",          aiTextureType_LIGHTMAP),
    TextureSlotDesc("REFLECTION",        aiTextureType_REFLECTION),
    TextureSlotDesc("BASE_COLOR",        aiTextureType_BASE_COLOR),
    TextureSlotDesc("NORMAL_CAMERA",     aiTextureType_NORMAL_CAMERA),
    TextureSlotDesc("EMISSION_COLOR",    aiTextureType_EMISSION_COLOR),
    TextureSlotDesc("METALNESS",         aiTextureType_METALNESS),
    TextureSlotDesc("DIFFUSE_ROUGHNESS", aiTextureType_DIFFUSE_ROUGHNESS),
    TextureSlotDesc("AMBIENT_OCCLUSION", aiTextureType_AMBIENT_OCCLUSION),
];

immutable string[] gImportantFpsNodes = [
    "camera",
    "Weapon",
    "Muzzle",
    "EjectionPort",
    "Ejection_Port",
    "Slide",
    "Magazine",
    "Magazine2",
    "Shell_bone",
    "Shell",
    "Bolt",
    "Receiver",
    "Grip",
    "ArmsMale",
    "ArmsFemale"
];

// ------------------------------
// Main
// ------------------------------

void main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Usage: inspect_fbx <model_file> [--full-tree]");
        writeln("Example: ./tools/inspect_fbx assets/weapons/glock/Glock.fbx");
        return;
    }

    string path = args[1];
    bool fullTree = args.length >= 3 && args[2] == "--full-tree";

    writeln("Loading: ", path);

    auto scene = aiImportFile(path.toStringz,
        aiProcess_Triangulate |
        aiProcess_GenNormals |
        aiProcess_FlipUVs);

    if (scene is null)
    {
        writeln("ERROR: Failed to load file.");
        writeln("  Assimp says: ", cStringToString(aiGetErrorString()));
        return;
    }

    writeln();
    writeln("========================================");
    writeln("  FILE: ", path);
    writeln("========================================");
    writeln("  Meshes:            ", scene.mNumMeshes);
    writeln("  Materials:         ", scene.mNumMaterials);
    writeln("  Animations:        ", scene.mNumAnimations);
    writeln("  Embedded Textures: ", scene.mNumTextures);
    writeln();

    printEmbeddedTextures(scene);
    printMaterials(scene);
    printMeshes(scene);
    printUniqueBones(scene);
    printAnimations(scene);

    writeln("--- IMPORTANT FPS NODE CHECKS ---");
    foreach (target; gImportantFpsNodes)
    {
        auto node = findNodeByName(scene.mRootNode, target);
        if (node !is null)
            writeln("  FOUND:   '", target, "'  path=", buildNodePath(scene.mRootNode, target));
        else
            writeln("  MISSING: '", target, "'");
    }
    writeln();

    writeln("--- NODE TREE ", fullTree ? "(FULL)" : "(depth 2)", " ---");
    printNode(scene.mRootNode, 0, fullTree ? int.max : 2);

    writeln();
    writeln("========================================");
    writeln("  DONE");
    writeln("========================================");

    aiReleaseImport(scene);
}

// ------------------------------
// String helpers
// ------------------------------

string aiStringToString(aiString s)
{
    size_t len = cast(size_t)s.length;
    if (len == 0) return "";
    return cast(string)s.data[0 .. len];
}

string safeAiStringToString(const(aiString)* s)
{
    if (s is null) return "";
    size_t len = cast(size_t)s.length;
    if (len == 0) return "";
    return cast(string)s.data[0 .. len];
}

string cStringToString(const(char)* cstr)
{
    if (cstr is null) return "";
    size_t len = 0;
    while (cstr[len] != '\0') ++len;
    return cast(string)cstr[0 .. len];
}

string textureTypeName(uint typeId)
{
    foreach (slot; gTextureSlots)
    {
        if (slot.typeId == typeId) return slot.name;
    }
    return "UNKNOWN(" ~ typeId.to!string ~ ")";
}


string guessAssetFamily(string name)
{
    auto n = name.toLower();

    if (n.canFind("concrete") ||
        n.canFind("surrounding_wall") ||
        n.canFind("building_01") ||
        n.canFind("building_02") ||
        n.canFind("building_03") ||
        n.canFind("building_04") ||
        n.canFind("building_05") ||
        n.canFind("building_06") ||
        n.canFind("building_07") ||
        n.canFind("building_08"))
    {
        return "CONCRETE_GRAY";
    }

    if (n.canFind("metal_cabin") ||
        n.canFind("metal_wall") ||
        n.canFind("corrugated") ||
        n.canFind("metal_beam") ||
        n.canFind("metal_support"))
    {
        return "METAL_BLUE_GRAY";
    }

    if (n.canFind("barrel") ||
        n.canFind("pallet") ||
        n.canFind("target") ||
        n.canFind("sand_bag") ||
        n.canFind("decal"))
    {
        return "PROP_OR_DECAL";
    }

    return "UNKNOWN_CHECK_IN_BLENDER";
}


// ------------------------------
// Embedded textures
// ------------------------------

void printEmbeddedTextures(const(aiScene)* scene)
{
    writeln("--- EMBEDDED TEXTURES ---");
    if (scene.mNumTextures == 0)
    {
        writeln("  (none)");
        writeln();
        return;
    }

    for (uint i = 0; i < scene.mNumTextures; i++)
    {
        auto tex = scene.mTextures[i];
        string fmt;
        foreach (j; 0 .. 8)
        {
            if (tex.achFormatHint[j] == 0) break;
            fmt ~= cast(char)tex.achFormatHint[j];
        }

        writeln("  Embedded Texture ", i, ":");
        writeln("    Width:       ", tex.mWidth);
        writeln("    Height:      ", tex.mHeight);
        writeln("    FormatHint:  ", fmt.length ? fmt : "(none)");
        if (tex.mHeight == 0)
            writeln("    Storage:     compressed blob");
        else
            writeln("    Storage:     raw texel data");
    }
    writeln();
}

// ------------------------------
// Materials
// ------------------------------

void printMaterials(const(aiScene)* scene)
{
    writeln("--- MATERIALS ---");
    if (scene.mNumMaterials == 0)
    {
        writeln("  (none)");
        writeln();
        return;
    }

    for (uint i = 0; i < scene.mNumMaterials; i++)
    {
        auto mat = scene.mMaterials[i];
        string matName = getMaterialName(mat);
        if (matName.length == 0)
            matName = "(unnamed material)";

        writeln("  Material ", i, ": '", matName, "'");

        bool printedAnyTex = false;
        foreach (slot; gTextureSlots)
        {
            uint count = aiGetMaterialTextureCount(mat, slot.typeId);
            if (count == 0) continue;

            printedAnyTex = true;
            writeln("    ", slot.name, ": count=", count);

            for (uint t = 0; t < count; t++)
            {
                aiString texPath;
                uint mapping = 0;
                uint uvIndex = 0;
                float blend = 1.0f;
                uint op = 0;
                uint mapMode = 0;
                uint flags = 0;

                int ret = aiGetMaterialTexture(
                    mat,
                    slot.typeId,
                    t,
                    &texPath,
                    &mapping,
                    &uvIndex,
                    &blend,
                    &op,
                    &mapMode,
                    &flags
                );

                string path = safeAiStringToString(&texPath);
                string embeddedNote = (path.length > 0 && path[0] == '*')
                    ? " (embedded texture ref)"
                    : "";

                writeln("      [", t, "] path='", path, "'",
                        " uvIndex=", uvIndex,
                        " blend=", blend,
                        " flags=", flags,
                        embeddedNote,
                        ret == aiReturn_SUCCESS ? "" : " [query-failed]");
            }
        }

        if (!printedAnyTex)
            writeln("    Textures: none referenced in material");

        writeln();
    }
}

string getMaterialName(const(aiMaterial)* mat)
{
    aiString outName;
    int ret = aiGetMaterialString(mat, "?mat.name".toStringz, 0, 0, &outName);
    if (ret != aiReturn_SUCCESS) return "";
    return safeAiStringToString(&outName);
}

// ------------------------------
// Meshes
// ------------------------------

void printMeshes(const(aiScene)* scene)
{
    writeln("--- MESHES ---");
    uint totalVerts = 0;
    uint totalBones = 0;
    uint totalFaces = 0;

    for (uint i = 0; i < scene.mNumMeshes; i++)
    {
        auto mesh = scene.mMeshes[i];
        string meshName = aiStringToString(mesh.mName);
        writeln("    ArtFamily:     ", guessAssetFamily(meshName));

        string matName = "(invalid)";
        if (mesh.mMaterialIndex < scene.mNumMaterials)
            matName = getMaterialName(scene.mMaterials[mesh.mMaterialIndex]);

        writeln("  Mesh ", i, ": '", meshName, "'");
        writeln("    MaterialIndex: ", mesh.mMaterialIndex);
        writeln("    MaterialName:  '", matName, "'");
        writeln("    Vertices:      ", mesh.mNumVertices);
        writeln("    Faces:         ", mesh.mNumFaces);
        writeln("    Bones:         ", mesh.mNumBones);
        writeln("    Has UVs:       ", mesh.mTextureCoords[0] !is null);
        writeln("    Has Normals:   ", mesh.mNormals !is null);

        totalVerts += mesh.mNumVertices;
        totalBones += mesh.mNumBones;
        totalFaces += mesh.mNumFaces;

        if (mesh.mNumVertices > 0 && mesh.mVertices !is null)
        {
            auto aabb = computeMeshAABB(mesh);
            writeln("    AABB Min:      (", aabb[0], ", ", aabb[1], ", ", aabb[2], ")");
            writeln("    AABB Max:      (", aabb[3], ", ", aabb[4], ", ", aabb[5], ")");
        }

        if (mesh.mNumBones > 0)
        {
            writeln("    Bone list:");
            for (uint b = 0; b < mesh.mNumBones && b < 30; b++)
            {
                auto bone = mesh.mBones[b];
                auto boneName = aiStringToString(bone.mName);
                writeln("      [", b, "] '", boneName, "' weights=", bone.mNumWeights);
            }
            if (mesh.mNumBones > 30)
                writeln("      ... and ", mesh.mNumBones - 30, " more bones");
        }
    }

    writeln();
    writeln("  Total vertices: ", totalVerts);
    writeln("  Total faces:    ", totalFaces);
    writeln("  Total bones:    ", totalBones);
    writeln();
}

double[6] computeMeshAABB(const(aiMesh)* mesh)
{
    double minX = double.infinity;
    double minY = double.infinity;
    double minZ = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    double maxZ = -double.infinity;

    for (uint v = 0; v < mesh.mNumVertices; v++)
    {
        auto p = mesh.mVertices[v];
        minX = min(minX, cast(double)p.x);
        minY = min(minY, cast(double)p.y);
        minZ = min(minZ, cast(double)p.z);
        maxX = max(maxX, cast(double)p.x);
        maxY = max(maxY, cast(double)p.y);
        maxZ = max(maxZ, cast(double)p.z);
    }

    return [minX, minY, minZ, maxX, maxY, maxZ];
}

// ------------------------------
// Unique bones
// ------------------------------

void printUniqueBones(const(aiScene)* scene)
{
    auto names = appender!(string[])();

    for (uint i = 0; i < scene.mNumMeshes; i++)
    {
        auto mesh = scene.mMeshes[i];
        for (uint b = 0; b < mesh.mNumBones; b++)
        {
            string name = aiStringToString(mesh.mBones[b].mName);
            if (!names.data.canFind(name))
                names.put(name);
        }
    }

    auto arr = names.data;
    sort(arr);

    writeln("--- UNIQUE BONES ---");
    writeln("  Unique bone count: ", arr.length);
    foreach (i, name; arr)
    {
        if (i < 80)
            writeln("    [", i, "] ", name);
    }
    if (arr.length > 80)
        writeln("    ... and ", arr.length - 80, " more unique bones");
    writeln();
}

// ------------------------------
// Animations
// ------------------------------

void printAnimations(const(aiScene)* scene)
{
    writeln("--- ANIMATIONS ---");
    if (scene.mNumAnimations == 0)
    {
        writeln("  (none)");
        writeln();
        return;
    }

    for (uint i = 0; i < scene.mNumAnimations; i++)
    {
        auto anim = scene.mAnimations[i];
        string name = aiStringToString(anim.mName);

        double fps = cast(double)anim.mTicksPerSecond;
        if (fps == 0.0) fps = 25.0;

        double durationTicks = cast(double)anim.mDuration;
        double durationSeconds = durationTicks / fps;
        double approxFrames = durationSeconds * fps;

        writeln("  Animation ", i, ": '", name.length ? name : "(unnamed)", "'");
        writeln("    Duration (ticks):  ", durationTicks);
        writeln("    Ticks/sec:         ", fps);
        writeln("    Duration (sec):    ", durationSeconds);
        writeln("    Approx frames:     ", approxFrames);
        writeln("    Channels:          ", anim.mNumChannels);

        for (uint c = 0; c < anim.mNumChannels && c < 20; c++)
        {
            auto ch = anim.mChannels[c];
            auto chName = aiStringToString(ch.mNodeName);
            writeln("      Channel ", c, ": '", chName, "'",
                    " posKeys=", ch.mNumPositionKeys,
                    " rotKeys=", ch.mNumRotationKeys,
                    " scaleKeys=", ch.mNumScalingKeys);
        }
        if (anim.mNumChannels > 20)
            writeln("      ... and ", anim.mNumChannels - 20, " more channels");

        writeln("    Important animated nodes:");
        foreach (target; gImportantFpsNodes)
        {
            bool found = false;
            for (uint c = 0; c < anim.mNumChannels; c++)
            {
                auto ch = anim.mChannels[c];
                auto chName = aiStringToString(ch.mNodeName);
                if (chName == target)
                {
                    found = true;
                    writeln("      FOUND channel: '", target, "'",
                            " posKeys=", ch.mNumPositionKeys,
                            " rotKeys=", ch.mNumRotationKeys,
                            " scaleKeys=", ch.mNumScalingKeys);
                    break;
                }
            }
            if (!found)
                writeln("      missing channel: '", target, "'");
        }

        writeln();
    }
}

// ------------------------------
// Node tree + search
// ------------------------------

void printNode(const(aiNode)* node, int depth, int maxDepth)
{
    if (node is null || depth > maxDepth) return;

    string indent;
    foreach (_; 0 .. depth) indent ~= "  ";

    auto name = aiStringToString(node.mName);
    writeln(indent, "'", name, "' meshes=", node.mNumMeshes,
            " children=", node.mNumChildren);

    for (uint i = 0; i < node.mNumChildren; i++)
        printNode(node.mChildren[i], depth + 1, maxDepth);
}

const(aiNode)* findNodeByName(const(aiNode)* node, string targetName)
{
    if (node is null) return null;

    auto nodeName = aiStringToString(node.mName);
    if (nodeName == targetName)
        return node;

    foreach (i; 0 .. node.mNumChildren)
    {
        auto found = findNodeByName(node.mChildren[i], targetName);
        if (found !is null)
            return found;
    }

    return null;
}

string buildNodePath(const(aiNode)* node, string targetName)
{
    string[] path;
    if (!buildNodePathRecursive(node, targetName, path))
        return "(not found)";

    string result;
    foreach (i, p; path)
    {
        if (i > 0) result ~= "/";
        result ~= p;
    }
    return result;
}

bool buildNodePathRecursive(const(aiNode)* node, string targetName, ref string[] outPath)
{
    if (node is null) return false;

    string name = aiStringToString(node.mName);
    outPath ~= name;

    if (name == targetName)
        return true;

    foreach (i; 0 .. node.mNumChildren)
    {
        if (buildNodePathRecursive(node.mChildren[i], targetName, outPath))
            return true;
    }

    outPath.length = outPath.length - 1;
    return false;
}