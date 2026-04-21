module littexturedmaterial;

import pipeline, materials;
import stb_image;
import bindbc.opengl;
import std.stdio;
import std.string : toStringz;

class LitTexturedMaterial : IMaterial
{
    GLuint mTextureID;

    this(string pipelineName, string texturePath)
    {
        super(pipelineName);
        loadTexturePNG(texturePath);
    }

    void loadTexturePNG(string path)
    {
        int w, h, channels;
        stbi_set_flip_vertically_on_load(1);
        auto data = stbi_load(path.toStringz, &w, &h, &channels, 0);

        if (data is null)
        {
            writeln("[LitTexturedMaterial] FAILED to load: ", path);
            return;
        }

        writeln("[LitTexturedMaterial] loaded: ", path, " ", w, "x", h, " ch=", channels);

        GLenum format = GL_RGB;
        if (channels == 4) format = GL_RGBA;
        if (channels == 1) format = GL_RED;

        glGenTextures(1, &mTextureID);
        glBindTexture(GL_TEXTURE_2D, mTextureID);

        glTexImage2D(GL_TEXTURE_2D, 0, format, w, h, 0, format, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

        stbi_image_free(data);
    }

    // override void Update()
    // {
    //     PipelineUse(mPipelineName);

    //     if ("uTexture" in mUniformMap)
    //     {
    //         glActiveTexture(GL_TEXTURE0);
    //         glBindTexture(GL_TEXTURE_2D, mTextureID);
    //         mUniformMap["uTexture"].Set(0);
    //     }
    // }

    override void Update()
    {
        PipelineUse(mPipelineName);

        // Always bind our texture before drawing
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, mTextureID);

        if ("uTexture" in mUniformMap)
        {
            mUniformMap["uTexture"].Set(0);
        }
    }
}
