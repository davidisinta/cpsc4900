/// Skeleton: bone hierarchy and inverse bind matrices
/// Extracted from an FBX/glTF file via Assimp.
/// The skeleton is shared across all meshes in a weapon model.
/// Animation clips reference bones by name through channels.

module skeleton;

import std.stdio;
import assimp_c_api;
import linear;

struct Skeleton
{
    string[] boneNames;
    int[] parentIndices;
    mat4[] inverseBindMatrices;
    int[string] boneIndexByName;
    mat4[] nodeLocalTransforms;

    /// Build skeleton from actual mesh bones only.
    /// This keeps the bone index space aligned with mesh vertex weights.
    void loadFromScene(const(aiScene)* scene)
    {
        if (scene is null) return;

        boneNames.length = 0;
        parentIndices.length = 0;
        inverseBindMatrices.length = 0;
        nodeLocalTransforms.length = 0;
        boneIndexByName = null;

        // Find first mesh with bones
        const(aiMesh)* skinnedMesh = null;
        for (uint i = 0; i < scene.mNumMeshes; i++)
        {
            if (scene.mMeshes[i].mNumBones > 0)
            {
                skinnedMesh = scene.mMeshes[i];
                break;
            }
        }

        if (skinnedMesh is null)
        {
            writeln("[skeleton] ERROR: no skinned mesh found");
            return;
        }

        writeln("[skeleton] extracting from mesh with ", skinnedMesh.mNumBones, " bones");

        boneNames.length = skinnedMesh.mNumBones;
        parentIndices.length = skinnedMesh.mNumBones;
        inverseBindMatrices.length = skinnedMesh.mNumBones;
        nodeLocalTransforms.length = skinnedMesh.mNumBones;
        parentIndices[] = -1;

        // Bone names + inverse bind + local bind transforms
        for (uint i = 0; i < skinnedMesh.mNumBones; i++)
        {
            auto bone = skinnedMesh.mBones[i];
            string name = cast(string)bone.mName.data[0 .. bone.mName.length].dup;

            boneNames[i] = name;
            boneIndexByName[name] = cast(int)i;
            inverseBindMatrices[i] = aiToMat4(bone.mOffsetMatrix);

            const(aiNode)* node = findNode(scene.mRootNode, name);
            if (node !is null)
                nodeLocalTransforms[i] = aiToMat4(node.mTransformation);
            else
                nodeLocalTransforms[i] = mat4.init;
        }

        // Parent indices only among actual bones
        for (uint i = 0; i < skinnedMesh.mNumBones; i++)
        {
            const(aiNode)* node = findNode(scene.mRootNode, boneNames[i]);
            if (node !is null && node.mParent !is null)
            {
                string parentName = cast(string)node.mParent.mName.data[0 .. node.mParent.mName.length];
                if (auto idx = parentName in boneIndexByName)
                    parentIndices[i] = *idx;
            }
        }

        writeln("[skeleton] loaded ", boneNames.length, " bones");
        for (uint i = 0; i < boneNames.length && i < 10; i++)
        {
            writeln("[skeleton]   [", i, "] '", boneNames[i], "' parent=", parentIndices[i]);
        }
        if (boneNames.length > 10)
            writeln("[skeleton]   ... and ", boneNames.length - 10, " more");
    }

    /// Find a node by name in the Assimp node tree (recursive)
    private static const(aiNode)* findNode(const(aiNode)* node, string name)
    {
        if (node is null) return null;

        auto nodeName = node.mName.data[0 .. node.mName.length];
        if (nodeName == name)
            return node;

        for (uint i = 0; i < node.mNumChildren; i++)
        {
            auto found = findNode(node.mChildren[i], name);
            if (found !is null)
                return found;
        }

        return null;
    }

    /// Convert Assimp matrix into the same convention used by the rest of this engine.
    /// This is the transposed/import-corrected version for the current engine math path.
    static mat4 aiToMat4(aiMatrix4x4 m)
    {
        mat4 result;
        result[0]  = m.a1; result[1]  = m.a2; result[2]  = m.a3; result[3]  = m.a4;
        result[4]  = m.b1; result[5]  = m.b2; result[6]  = m.b3; result[7]  = m.b4;
        result[8]  = m.c1; result[9]  = m.c2; result[10] = m.c3; result[11] = m.c4;
        result[12] = m.d1; result[13] = m.d2; result[14] = m.d3; result[15] = m.d4;
        return result;
    }

    /// Get bone index by name, returns -1 if not found
    int getBoneIndex(string name)
    {
        if (auto idx = name in boneIndexByName)
            return *idx;
        return -1;
    }

    /// Print full hierarchy for debugging
    void printHierarchy()
    {
        writeln("=== SKELETON HIERARCHY ===");
        writeln("  Bones: ", boneNames.length);
        for (uint i = 0; i < boneNames.length; i++)
        {
            string parentName = parentIndices[i] >= 0 ? boneNames[parentIndices[i]] : "(root)";
            writeln("  [", i, "] '", boneNames[i], "' → parent: '", parentName, "'");
        }
        writeln("==========================");
    }
}