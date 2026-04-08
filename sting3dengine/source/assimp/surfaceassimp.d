module surfaceassimp;

//standard library files
import std.stdio;

// Third-party libraries
import bindbc.opengl;

//project libraries
import surface;
import assimp_c_api;


class SurfaceAssimp : ISurface{
    GLuint mVBO;
    int mVertexCount;
    bool mHasUVs;

    this(aiMesh* mesh)
    {
        mHasUVs = mesh.mTextureCoords[0] !is null;
        int floatsPerVert = mHasUVs ? 8 : 6;

        GLfloat[] vboData;
        vboData.reserve(mesh.mNumFaces * 3 * floatsPerVert);

        for (uint f = 0; f < mesh.mNumFaces; f++)
        {
            auto face = mesh.mFaces[f];
            for (uint i = 0; i < face.mNumIndices; i++)
            {
                uint idx = face.mIndices[i];

                auto v = mesh.mVertices[idx];
                vboData ~= v.x;
                vboData ~= v.y;
                vboData ~= v.z;

                if (mesh.mNormals !is null)
                {
                    auto n = mesh.mNormals[idx];
                    vboData ~= n.x;
                    vboData ~= n.y;
                    vboData ~= n.z;
                }
                else
                {
                    vboData ~= 0.0f;
                    vboData ~= 1.0f;
                    vboData ~= 0.0f;
                }

                if (mHasUVs)
                {
                    auto uv = mesh.mTextureCoords[0][idx];
                    vboData ~= uv.x;
                    vboData ~= uv.y;
                }
            }
        }

        mVertexCount = cast(int)(vboData.length / floatsPerVert);
        writeln("[SurfaceAssimp] vertices=", mVertexCount,
                " hasUVs=", mHasUVs);

        glGenVertexArrays(1, &mVAO);
        glGenBuffers(1, &mVBO);

        glBindVertexArray(mVAO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER,
                     vboData.length * GLfloat.sizeof,
                     vboData.ptr,
                     GL_STATIC_DRAW);

        int stride = floatsPerVert * cast(int)GLfloat.sizeof;

        // location 0: position
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)0);

        // location 1: normal
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, stride, cast(void*)(3 * GLfloat.sizeof));

        // location 2: UV (if present)
        if (mHasUVs)
        {
            glEnableVertexAttribArray(2);
            glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, stride, cast(void*)(6 * GLfloat.sizeof));
        }

        glBindVertexArray(0);
    }

    override void Render()
    {
        glBindVertexArray(mVAO);
        glDrawArrays(GL_TRIANGLES, 0, mVertexCount);
        glBindVertexArray(0);
    }
}
