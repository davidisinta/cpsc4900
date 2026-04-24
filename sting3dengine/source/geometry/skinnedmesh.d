// // /// SkinnedSurface: vertex format with bone weights for skeletal animation.
// // /// Each vertex stores up to 4 bone influences (ID + weight).
// // /// Vertex layout: position(3) + normal(3) + uv(2) + boneIds(4) + boneWeights(4) = 16 floats
// // /// The boneIds are stored as floats but represent integer indices
// // /// (GLSL reads them as floats and casts to int, or we use ivec4 with a separate int buffer).

// // module skinnedmesh;

// // import std.stdio;
// // import std.math : sqrt;
// // import bindbc.opengl;
// // import enginecore;
// // import assimp_c_api;
// // import surface;

// // class SkinnedSurface : ISurface
// // {
// //     GLuint mVBO;
// //     int mVertexCount;
// //     float mBoundingRadius = 0.0f;

// //     /// Build a skinned surface from an Assimp mesh.
// //     /// Extracts position, normal, UV, bone IDs, and bone weights.
// //     this(aiMesh* mesh, int[string] boneIndexRemap = null)
// //     {
// //         if (mesh is null) return;

// //         mVertexCount = 0;
// //         bool hasUVs = mesh.mTextureCoords[0] !is null;

// //         // Build per-vertex bone data
// //         // Each vertex can be influenced by up to 4 bones
// //         int numVerts = cast(int)mesh.mNumVertices;
// //         int[][] vertBoneIds;
// //         float[][] vertBoneWeights;
// //         vertBoneIds.length = numVerts;
// //         vertBoneWeights.length = numVerts;

// //         foreach (ref ids; vertBoneIds) ids = [];
// //         foreach (ref wts; vertBoneWeights) wts = [];

// //         // Iterate bones and distribute weights to vertices
// //         for (uint b = 0; b < mesh.mNumBones; b++)
// //         {
// //             auto bone = mesh.mBones[b];
// //             for (uint w = 0; w < bone.mNumWeights; w++)
// //             {
// //                 uint vid = bone.mWeights[w].mVertexId;
// //                 float weight = bone.mWeights[w].mWeight;

// //                 if (vertBoneIds[vid].length < 4)
// //                 {
// //                     vertBoneIds[vid] ~= cast(int)b;
// //                     vertBoneWeights[vid] ~= weight;
// //                 }
// //             }
// //         }

// //         // Compute bounding radius
// //         float maxDistSq = 0.0f;

// //         // Build vertex buffer: unroll faces
// //         // 16 floats per vertex: pos(3) + normal(3) + uv(2) + boneIds(4) + boneWeights(4)
// //         float[] vboData;
// //         for (uint f = 0; f < mesh.mNumFaces; f++)
// //         {
// //             auto face = mesh.mFaces[f];
// //             for (uint idx = 0; idx < face.mNumIndices; idx++)
// //             {
// //                 uint vi = face.mIndices[idx];
// //                 auto v = mesh.mVertices[vi];
// //                 auto n = mesh.mNormals[vi];

// //                 // Position
// //                 vboData ~= v.x;
// //                 vboData ~= v.y;
// //                 vboData ~= v.z;

// //                 // Normal
// //                 vboData ~= n.x;
// //                 vboData ~= n.y;
// //                 vboData ~= n.z;

// //                 // UV
// //                 if (hasUVs)
// //                 {
// //                     auto uv = mesh.mTextureCoords[0][vi];
// //                     vboData ~= uv.x;
// //                     vboData ~= uv.y;
// //                 }
// //                 else
// //                 {
// //                     vboData ~= 0.0f;
// //                     vboData ~= 0.0f;
// //                 }

// //                 // Bone IDs (4 floats — shader casts to int)
// //                 // for (int i = 0; i < 4; i++)
// //                 // {
// //                 //     if (i < vertBoneIds[vi].length)
// //                 //         vboData ~= cast(float)vertBoneIds[vi][i];
// //                 //     else
// //                 //         vboData ~= 0.0f;
// //                 // }
// //                 // Bone IDs (4 floats — shader casts to int)
// //                 for (int i = 0; i < 4; i++)
// //                 {
// //                     if (i < vertBoneIds[vi].length)
// //                     {
// //                         int meshBoneIdx = vertBoneIds[vi][i];
// //                         if (boneIndexRemap !is null)
// //                         {
// //                             string boneName = cast(string)mesh.mBones[meshBoneIdx].mName.data[0 .. mesh.mBones[meshBoneIdx].mName.length];
// //                             if (auto remapped = boneName in boneIndexRemap)
// //                                 vboData ~= cast(float)*remapped;
// //                             else
// //                                 vboData ~= 0.0f;
// //                         }
// //                         else
// //                             vboData ~= cast(float)meshBoneIdx;
// //                     }
// //                     else
// //                         vboData ~= 0.0f;
// //                 }

// //                 // Bone Weights (4 floats)
// //                 for (int i = 0; i < 4; i++)
// //                 {
// //                     if (i < vertBoneWeights[vi].length)
// //                         vboData ~= vertBoneWeights[vi][i];
// //                     else
// //                         vboData ~= 0.0f;
// //                 }

// //                 // Bounding radius
// //                 float distSq = v.x * v.x + v.y * v.y + v.z * v.z;
// //                 if (distSq > maxDistSq) maxDistSq = distSq;

// //                 mVertexCount++;
// //             }
// //         }

// //         mBoundingRadius = sqrt(maxDistSq);

// //         // Upload to GPU
// //         glGenVertexArrays(1, &mVAO);
// //         glBindVertexArray(mVAO);

// //         glGenBuffers(1, &mVBO);
// //         glBindBuffer(GL_ARRAY_BUFFER, mVBO);
// //         glBufferData(GL_ARRAY_BUFFER,
// //             cast(GLsizeiptr)(vboData.length * float.sizeof),
// //             vboData.ptr, GL_STATIC_DRAW);

// //         int stride = 16 * cast(int)float.sizeof;

// //         // location 0: position (3 floats)
// //         glEnableVertexAttribArray(0);
// //         glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)0);

// //         // location 1: normal (3 floats)
// //         glEnableVertexAttribArray(1);
// //         glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(3 * float.sizeof));

// //         // location 2: uv (2 floats)
// //         glEnableVertexAttribArray(2);
// //         glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)(6 * float.sizeof));

// //         // location 3: bone IDs (4 floats — shader will cast to int)
// //         glEnableVertexAttribArray(3);
// //         glVertexAttribPointer(3, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(8 * float.sizeof));

// //         // location 4: bone weights (4 floats)
// //         glEnableVertexAttribArray(4);
// //         glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(12 * float.sizeof));

// //         glBindVertexArray(0);

// //         writeln("[skinned] created surface: ", mVertexCount, " verts, ",
// //                 mesh.mNumBones, " bones, radius=", mBoundingRadius);
// //     }

// //     override void Render()
// //     {
// //         glBindVertexArray(mVAO);
// //         glDrawArrays(GL_TRIANGLES, 0, mVertexCount);
// //     }
// // }

// /// SkinnedSurface: vertex format with bone weights for skeletal animation.
// /// Each vertex stores up to 4 bone influences (ID + weight).
// /// Vertex layout:
// ///   position(3) + normal(3) + uv(2) + boneIds(4 ints) + boneWeights(4 floats)
// ///
// /// IMPORTANT:
// /// - bone IDs are uploaded as INTEGERS with glVertexAttribIPointer
// /// - weights are uploaded as floats
// /// - this avoids float/int mismatch in the skinning shader

// module skinnedmesh;

// import std.stdio;
// import std.math : sqrt;
// import bindbc.opengl;
// import enginecore;
// import assimp_c_api;
// import surface;
// import std.conv;

// class SkinnedSurface : ISurface
// {
//     GLuint mVBO;
//     int mVertexCount;
//     float mBoundingRadius = 0.0f;

//     /// Build a skinned surface from an Assimp mesh.
//     /// Extracts position, normal, UV, bone IDs, and bone weights.
//     this(aiMesh* mesh, int[string] boneIndexRemap = null)
//     {
//         if (mesh is null) return;

//         mVertexCount = 0;
//         bool hasUVs = mesh.mTextureCoords[0] !is null;

//         int numVerts = cast(int)mesh.mNumVertices;

//         // Per-vertex influences
//         int[][] vertBoneIds;
//         float[][] vertBoneWeights;
//         vertBoneIds.length = numVerts;
//         vertBoneWeights.length = numVerts;

//         foreach (ref ids; vertBoneIds) ids = [];
//         foreach (ref wts; vertBoneWeights) wts = [];

//         // Gather up to 4 bone influences per vertex
//         for (uint b = 0; b < mesh.mNumBones; b++)
//         {
//             auto bone = mesh.mBones[b];
//             for (uint w = 0; w < bone.mNumWeights; w++)
//             {
//                 uint vid = bone.mWeights[w].mVertexId;
//                 float weight = bone.mWeights[w].mWeight;

//                 if (vid >= numVerts) continue;

//                 if (vertBoneIds[vid].length < 4)
//                 {
//                     vertBoneIds[vid] ~= cast(int)b;
//                     vertBoneWeights[vid] ~= weight;
//                 }
//             }
//         }

//         // One-time debug: inspect first few vertices before upload
//         writeln("=== SKINNED VERTEX DEBUG ===");
//         for (int i = 0; i < 5 && i < numVerts; i++)
//         {
//             string idsStr;
//             string wtsStr;

//             for (int j = 0; j < 4; j++)
//             {
//                 int idVal = (j < vertBoneIds[i].length) ? vertBoneIds[i][j] : 0;
//                 float wtVal = (j < vertBoneWeights[i].length) ? vertBoneWeights[i][j] : 0.0f;

//                 if (j > 0)
//                 {
//                     idsStr ~= ",";
//                     wtsStr ~= ",";
//                 }
//                 idsStr ~= idVal.to!string;
//                 wtsStr ~= wtVal.to!string;
//             }

//             writeln("v", i, " raw boneIDs=", idsStr, " raw weights=", wtsStr);
//         }
//         writeln("============================");

//         float maxDistSq = 0.0f;

//         // Interleaved vertex data:
//         // pos(3) + normal(3) + uv(2) + boneIds(4 ints) + boneWeights(4 floats)
//         float[] floatData;
//         int[] boneIdData; // only for debug visibility before packing

//         for (uint f = 0; f < mesh.mNumFaces; f++)
//         {
//             auto face = mesh.mFaces[f];
//             for (uint idx = 0; idx < face.mNumIndices; idx++)
//             {
//                 uint vi = face.mIndices[idx];
//                 auto v = mesh.mVertices[vi];
//                 auto n = mesh.mNormals[vi];

//                 // Position
//                 floatData ~= v.x;
//                 floatData ~= v.y;
//                 floatData ~= v.z;

//                 // Normal
//                 floatData ~= n.x;
//                 floatData ~= n.y;
//                 floatData ~= n.z;

//                 // UV
//                 if (hasUVs)
//                 {
//                     auto uv = mesh.mTextureCoords[0][vi];
//                     floatData ~= uv.x;
//                     floatData ~= uv.y;
//                 }
//                 else
//                 {
//                     floatData ~= 0.0f;
//                     floatData ~= 0.0f;
//                 }

//                 // Bone IDs: keep as ints conceptually, but pack into raw bytes later
//                 for (int i = 0; i < 4; i++)
//                 {
//                     int outId = 0;

//                     if (i < vertBoneIds[vi].length)
//                     {
//                         int meshBoneIdx = vertBoneIds[vi][i];

//                         if (boneIndexRemap !is null)
//                         {
//                             string boneName = cast(string)mesh.mBones[meshBoneIdx].mName.data[0 .. mesh.mBones[meshBoneIdx].mName.length];
//                             if (auto remapped = boneName in boneIndexRemap)
//                                 outId = *remapped;
//                             else
//                                 outId = 0;
//                         }
//                         else
//                         {
//                             outId = meshBoneIdx;
//                         }
//                     }

//                     boneIdData ~= outId;
//                 }

//                 // Bone Weights
//                 for (int i = 0; i < 4; i++)
//                 {
//                     if (i < vertBoneWeights[vi].length)
//                         floatData ~= vertBoneWeights[vi][i];
//                     else
//                         floatData ~= 0.0f;
//                 }

//                 float distSq = v.x * v.x + v.y * v.y + v.z * v.z;
//                 if (distSq > maxDistSq) maxDistSq = distSq;

//                 mVertexCount++;
//             }
//         }

//         // Debug remapped IDs for first few final vertices
//         writeln("=== SKINNED VERTEX DEBUG (POST-REMAP) ===");
//         for (int i = 0; i < 5 && i < mVertexCount; i++)
//         {
//             int base = i * 4;
//             if (base + 3 < boneIdData.length)
//             {
//                 writeln("v", i, " boneIDs=",
//                     boneIdData[base + 0], ",",
//                     boneIdData[base + 1], ",",
//                     boneIdData[base + 2], ",",
//                     boneIdData[base + 3]);
//             }
//         }
//         writeln("=========================================");

//         mBoundingRadius = sqrt(maxDistSq);

//         // Build raw interleaved byte buffer:
//         // 8 floats, 4 ints, 4 floats
//         ubyte[] vboBytes;
//         vboBytes.length = mVertexCount * (8 * float.sizeof + 4 * int.sizeof + 4 * float.sizeof);

//         size_t writeOffset = 0;
//         size_t floatCursor = 0;
//         size_t boneCursor = 0;

//         foreach (vertexIndex; 0 .. mVertexCount)
//         {
//             // pos(3) + normal(3) + uv(2) => 8 floats
//             for (int k = 0; k < 8; k++)
//             {
//                 auto p = cast(ubyte*)(&floatData[floatCursor++]);
//                 vboBytes[writeOffset .. writeOffset + float.sizeof] = p[0 .. float.sizeof];
//                 writeOffset += float.sizeof;
//             }

//             // bone ids => 4 ints
//             for (int k = 0; k < 4; k++)
//             {
//                 auto p = cast(ubyte*)(&boneIdData[boneCursor++]);
//                 vboBytes[writeOffset .. writeOffset + int.sizeof] = p[0 .. int.sizeof];
//                 writeOffset += int.sizeof;
//             }

//             // bone weights => 4 floats
//             for (int k = 0; k < 4; k++)
//             {
//                 auto p = cast(ubyte*)(&floatData[floatCursor++]);
//                 vboBytes[writeOffset .. writeOffset + float.sizeof] = p[0 .. float.sizeof];
//                 writeOffset += float.sizeof;
//             }
//         }

//         // Upload to GPU
//         glGenVertexArrays(1, &mVAO);
//         glBindVertexArray(mVAO);

//         glGenBuffers(1, &mVBO);
//         glBindBuffer(GL_ARRAY_BUFFER, mVBO);
//         glBufferData(
//             GL_ARRAY_BUFFER,
//             cast(GLsizeiptr)vboBytes.length,
//             vboBytes.ptr,
//             GL_STATIC_DRAW
//         );

//         // stride = 8 floats + 4 ints + 4 floats
//         int stride = cast(int)(8 * float.sizeof + 4 * int.sizeof + 4 * float.sizeof);

//         // location 0: position (3 floats)
//         glEnableVertexAttribArray(0);
//         glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)0);

//         // location 1: normal (3 floats)
//         glEnableVertexAttribArray(1);
//         glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(3 * float.sizeof));

//         // location 2: uv (2 floats)
//         glEnableVertexAttribArray(2);
//         glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)(6 * float.sizeof));

//         // location 3: bone IDs (4 INTS)
//         glEnableVertexAttribArray(3);
//         glVertexAttribIPointer(3, 4, GL_INT, stride, cast(void*)(8 * float.sizeof));

//         // location 4: bone weights (4 floats)
//         glEnableVertexAttribArray(4);
//         glVertexAttribPointer(
//             4,
//             4,
//             GL_FLOAT,
//             GL_FALSE,
//             stride,
//             cast(void*)(8 * float.sizeof + 4 * int.sizeof)
//         );

//         glBindVertexArray(0);

//         writeln("[skinned] created surface: ", mVertexCount, " verts, ",
//                 mesh.mNumBones, " bones, radius=", mBoundingRadius);
//     }

//     override void Render()
//     {
//         glBindVertexArray(mVAO);
//         glDrawArrays(GL_TRIANGLES, 0, mVertexCount);
//     }
// }


/// SkinnedSurface: vertex format with bone weights for skeletal animation.
/// Each vertex stores up to 4 bone influences (ID + weight).
/// Vertex layout: position(3) + normal(3) + uv(2) + boneIds(4) + boneWeights(4) = 16 floats
/// The boneIds are stored as ints reinterpreted as float bits for glVertexAttribIPointer.

module skinnedmesh;

import std.stdio;
import std.math : sqrt;
import bindbc.opengl;
import enginecore;
import assimp_c_api;
import surface;

class SkinnedSurface : ISurface
{
    GLuint mVBO;
    int mVertexCount;
    float mBoundingRadius = 0.0f;

    /// Build a skinned surface from an Assimp mesh.
    /// Extracts position, normal, UV, bone IDs, and bone weights.
    /// boneIndexRemap: maps bone names to skeleton node indices (optional)
    this(aiMesh* mesh, int[string] boneIndexRemap = null)
    {
        if (mesh is null) return;

        mVertexCount = 0;
        bool hasUVs = mesh.mTextureCoords[0] !is null;

        int numVerts = cast(int)mesh.mNumVertices;

        // Per-vertex bone data (up to 4 influences)
        int[][] vertBoneIds;
        float[][] vertBoneWeights;
        vertBoneIds.length = numVerts;
        vertBoneWeights.length = numVerts;

        foreach (ref ids; vertBoneIds) ids = [];
        foreach (ref wts; vertBoneWeights) wts = [];

        // Iterate bones and distribute weights to vertices
        for (uint b = 0; b < mesh.mNumBones; b++)
        {
            auto bone = mesh.mBones[b];
            string boneName = cast(string)bone.mName.data[0 .. bone.mName.length];

            // Determine the bone index to store
            int boneIdx = cast(int)b;
            if (boneIndexRemap !is null)
            {
                if (auto remapped = boneName in boneIndexRemap)
                    boneIdx = *remapped;
            }

            for (uint w = 0; w < bone.mNumWeights; w++)
            {
                uint vid = bone.mWeights[w].mVertexId;
                float weight = bone.mWeights[w].mWeight;

                if (vertBoneIds[vid].length < 4)
                {
                    vertBoneIds[vid] ~= boneIdx;
                    vertBoneWeights[vid] ~= weight;
                }
            }
        }

        // === DEBUG 1: Check bone weight sums for first 5 weighted vertices ===
        int debugPrinted = 0;
        for (int vi = 0; vi < numVerts && debugPrinted < 5; vi++)
        {
            if (vertBoneWeights[vi].length > 0)
            {
                float sum = 0.0f;
                foreach (w; vertBoneWeights[vi]) sum += w;

                string idsStr = "";
                foreach (id; vertBoneIds[vi])
                {
                    if (idsStr.length > 0) idsStr ~= ",";
                    import std.conv : to;
                    idsStr ~= id.to!string;
                }

                string wtsStr = "";
                foreach (w; vertBoneWeights[vi])
                {
                    if (wtsStr.length > 0) wtsStr ~= ",";
                    import std.conv : to;
                    wtsStr ~= w.to!string;
                }

                writeln("[skinned-dbg1] v", vi,
                    " boneIDs=[", idsStr, "]",
                    " weights=[", wtsStr, "]",
                    " sum=", sum);
                debugPrinted++;
            }
        }

        // Compute bounding radius
        float maxDistSq = 0.0f;

        // Track bone ID range
        int minBoneId = int.max;
        int maxBoneId = int.min;

        // Build vertex buffer: unroll faces
        // 16 floats per vertex: pos(3) + normal(3) + uv(2) + boneIds(4 as int bits) + boneWeights(4)
        float[] vboData;
        for (uint f = 0; f < mesh.mNumFaces; f++)
        {
            auto face = mesh.mFaces[f];
            for (uint idx = 0; idx < face.mNumIndices; idx++)
            {
                uint vi = face.mIndices[idx];
                auto v = mesh.mVertices[vi];
                auto n = mesh.mNormals[vi];

                // Position
                vboData ~= v.x;
                vboData ~= v.y;
                vboData ~= v.z;

                // Normal
                vboData ~= n.x;
                vboData ~= n.y;
                vboData ~= n.z;

                // UV
                if (hasUVs)
                {
                    auto uv = mesh.mTextureCoords[0][vi];
                    vboData ~= uv.x;
                    vboData ~= uv.y;
                }
                else
                {
                    vboData ~= 0.0f;
                    vboData ~= 0.0f;
                }

                // Bone IDs (4 ints stored as raw bits in float slots)
                for (int i = 0; i < 4; i++)
                {
                    int boneId = -1;
                    if (i < vertBoneIds[vi].length)
                        boneId = vertBoneIds[vi][i];

                    // Track range
                    if (boneId >= 0)
                    {
                        if (boneId < minBoneId) minBoneId = boneId;
                        if (boneId > maxBoneId) maxBoneId = boneId;
                    }

                    vboData ~= *cast(float*)&boneId;
                }

                // Bone Weights (4 floats)
                for (int i = 0; i < 4; i++)
                {
                    if (i < vertBoneWeights[vi].length)
                        vboData ~= vertBoneWeights[vi][i];
                    else
                        vboData ~= 0.0f;
                }

                // Bounding radius
                float distSq = v.x * v.x + v.y * v.y + v.z * v.z;
                if (distSq > maxDistSq) maxDistSq = distSq;

                mVertexCount++;
            }
        }

        mBoundingRadius = sqrt(maxDistSq);

        // === DEBUG 2: Bone ID range ===
        writeln("[skinned-dbg2] bone id range: ", minBoneId, " .. ", maxBoneId,
                " (skeleton has ", boneIndexRemap !is null ? cast(int)boneIndexRemap.length : mesh.mNumBones, " bones)");

        // Upload to GPU
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);

        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER,
            cast(GLsizeiptr)(vboData.length * float.sizeof),
            vboData.ptr, GL_STATIC_DRAW);

        int stride = 16 * cast(int)float.sizeof;

        // location 0: position (3 floats)
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)0);

        // location 1: normal (3 floats)
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(3 * float.sizeof));

        // location 2: uv (2 floats)
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)(6 * float.sizeof));

        // location 3: bone IDs (4 ints — using glVertexAttribIPointer)
        glEnableVertexAttribArray(3);
        glVertexAttribIPointer(3, 4, GL_INT, stride, cast(void*)(8 * float.sizeof));

        // location 4: bone weights (4 floats)
        glEnableVertexAttribArray(4);
        glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, stride, cast(void*)(12 * float.sizeof));

        glBindVertexArray(0);

        writeln("[skinned] created surface: ", mVertexCount, " verts, ",
                mesh.mNumBones, " bones, radius=", mBoundingRadius);
    }

    override void Render()
    {
        glBindVertexArray(mVAO);
        glDrawArrays(GL_TRIANGLES, 0, mVertexCount);
    }
}
