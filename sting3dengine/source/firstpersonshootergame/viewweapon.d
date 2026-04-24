/// ViewWeapon: First-person animated weapon rendered at camera offset.
/// Owns the skeleton, animation clips, animator, skinned surfaces,
/// and handles rendering independently of the world scene.
///
/// Usage:
///   - Created during Setup()
///   - Updated each frame after camera moves
///   - Rendered after world scene, before HUD
///
/// Controls (for testing):
///   1 = idle, 2 = fire, 3 = reload, 4 = draw, 5 = walk

module viewweapon;

import std.stdio;
import std.string : toStringz;

import bindbc.opengl;
import enginecore;
import linear;
import assimp_c_api;
import assimp;
import geometry;
import materials;
import animation;

class ViewWeapon
{
    // Animation system
    Skeleton mSkeleton;
    Animator mAnimator;
    AnimationClip[string] mClips;
    string mCurrentClipName;

    double mDebugAccum = 0.0;

    // Rendering
    SkinnedSurface[] mSurfaces;
    string[] mMeshNames;
    IMaterial mMaterial;
    GLuint mShaderProgram;
    GLint mBoneUniformLoc;
    GLint mModelUniformLoc;
    GLint mViewUniformLoc;
    GLint mProjUniformLoc;
    GLint mTexUniformLoc;
    GLint mLightUniformLoc;

    // Camera attachment
    Camera mCamera;

    //hands pos
    // float mExtraRotX = -1.0708f;
    // float mExtraRotY = 0f;
    // float mExtraRotZ = 0f;
    // float mWeaponScale = 0.14f;

    // float mOffsetRight = 0.15f;
    // float mOffsetUp = -0.15f;
    // float mOffsetFwd = -0.3f;

    float   mOffsetRight = 0.01f;
  float mOffsetUp = -0.15f;
  float mOffsetFwd = -0.16f;
  float mExtraRotX = 0.7292f;
  float mExtraRotY = -3.1f;
  float mExtraRotZ = -0.15f;
  float mWeaponScale = 0.14f;

    // State
    bool mReady = false;

    void init(Camera camera, string modelPath, string texturePath)
    {
        mCamera = camera;

        new Pipeline("skinned_textured",
            "./pipelines/skinned_textured/skinned_textured.vert",
            "./pipelines/skinned_textured/skinned_textured.frag");

        mShaderProgram = Pipeline.sPipeline["skinned_textured"];

        writeln("[viewweapon] shader program id=", mShaderProgram);

        GLint numUniforms;
        glGetProgramiv(mShaderProgram, GL_ACTIVE_UNIFORMS, &numUniforms);
        writeln("[viewweapon] active uniforms: ", numUniforms);
        for (int i = 0; i < numUniforms; i++)
        {
            char[256] name;
            GLsizei length;
            GLint size;
            GLenum type;
            glGetActiveUniform(mShaderProgram, cast(GLuint)i, 256, &length, &size, &type, name.ptr);
            GLint loc = glGetUniformLocation(mShaderProgram, name.ptr);
            writeln("[viewweapon]   uniform ", i, ": '", name[0 .. length], "' loc=", loc, " size=", size);
        }

        GLint linkStatus;
        glGetProgramiv(mShaderProgram, GL_LINK_STATUS, &linkStatus);
        writeln("[viewweapon] link status: ", linkStatus);

        if (linkStatus == GL_FALSE)
        {
            GLint logLen;
            glGetProgramiv(mShaderProgram, GL_INFO_LOG_LENGTH, &logLen);
            if (logLen > 0)
            {
                char[] log;
                log.length = logLen;
                glGetProgramInfoLog(mShaderProgram, logLen, null, log.ptr);
                writeln("[viewweapon] LINK ERROR: ", log);
            }
        }

        glUseProgram(mShaderProgram);
        mBoneUniformLoc = glGetUniformLocation(mShaderProgram, "uBones");
        mModelUniformLoc = glGetUniformLocation(mShaderProgram, "uModel");
        mViewUniformLoc = glGetUniformLocation(mShaderProgram, "uView");
        mProjUniformLoc = glGetUniformLocation(mShaderProgram, "uProjection");
        mTexUniformLoc = glGetUniformLocation(mShaderProgram, "uTexture");
        mLightUniformLoc = glGetUniformLocation(mShaderProgram, "uLightPos");

        writeln("[viewweapon] shader uniforms: bones=", mBoneUniformLoc,
                " model=", mModelUniformLoc, " view=", mViewUniformLoc,
                " proj=", mProjUniformLoc, " tex=", mTexUniformLoc,
                " light=", mLightUniformLoc);

        auto scene = aiImportFile(modelPath.toStringz,
            aiProcess_Triangulate | aiProcess_GenNormals | aiProcess_FlipUVs);

        if (scene is null)
        {
            writeln("[viewweapon] ERROR: failed to load ", modelPath);
            return;
        }

        mSkeleton.loadFromScene(scene);

        writeln("[viewweapon] skeleton bones=", mSkeleton.boneNames.length);
        for (uint i = 0; i < scene.mNumMeshes; i++)
        {
            auto mesh = scene.mMeshes[i];
            auto meshName = cast(string)mesh.mName.data[0 .. mesh.mName.length];
            writeln("[viewweapon] mesh '", meshName, "' mNumBones=", mesh.mNumBones);
        }

        mAnimator.init(&mSkeleton);

        mMaterial = new LitTexturedMaterial("skinned_textured", texturePath);

        for (uint i = 0; i < scene.mNumMeshes; i++)
        {
            auto mesh = scene.mMeshes[i];
            auto meshName = cast(string)mesh.mName.data[0 .. mesh.mName.length];

            if (meshName == "ArmsFemale") continue;
            if (meshName == "LeupoldRedDot") continue;
            if (meshName == "LeupoldRedDotGlass") continue;
            if (meshName == "Supressor") continue;

            writeln("[viewweapon] loading mesh: ", meshName);
            auto surf = new SkinnedSurface(cast(aiMesh*)mesh, mSkeleton.boneIndexByName);
            mSurfaces ~= surf;
            mMeshNames ~= meshName.dup;
        }

        aiReleaseImport(scene);

        writeln("[viewweapon] loaded ", mSurfaces.length, " meshes, ",
                mSkeleton.boneNames.length, " bones");

        mReady = true;
    }


    /// Adjust weapon position/rotation with keys for tuning
    // void handleTuning(int key)
    // {
    //     import bindbc.sdl;
    //     float step = 0.02f;
    //     float rotStep = 0.05f;

    //     switch (key)
    //     {
    //         case SDLK_UP:    mOffsetUp += step; break;
    //         case SDLK_DOWN:  mOffsetUp -= step; break;
    //         case SDLK_LEFT:  mOffsetRight -= step; break;
    //         case SDLK_RIGHT: mOffsetRight += step; break;
    //         case SDLK_PAGEUP:   mOffsetFwd += step; break;
    //         case SDLK_PAGEDOWN: mOffsetFwd -= step; break;
    //         case SDLK_j: mExtraRotY -= rotStep; break;  // yaw left
    //         case SDLK_l: mExtraRotY += rotStep; break;  // yaw right
    //         case SDLK_i: mExtraRotX -= rotStep; break;  // pitch up
    //         case SDLK_k: mExtraRotX += rotStep; break;  // pitch down
    //         case SDLK_u: mExtraRotZ -= rotStep; break;  // roll left
    //         case SDLK_o: mExtraRotZ += rotStep; break;  // roll right
    //         case SDLK_EQUALS: mWeaponScale += 0.01f; break;  // + scale up
    //         case SDLK_MINUS:  mWeaponScale -= 0.01f; break;  // - scale down
    //         case SDLK_8:
    //             writeln("=== WEAPON TUNING SAVED ===");
    //             writeln("  mOffsetRight = ", mOffsetRight, "f;");
    //             writeln("  mOffsetUp = ", mOffsetUp, "f;");
    //             writeln("  mOffsetFwd = ", mOffsetFwd, "f;");
    //             writeln("  mExtraRotX = ", mExtraRotX, "f;");
    //             writeln("  mExtraRotY = ", mExtraRotY, "f;");
    //             writeln("  mExtraRotZ = ", mExtraRotZ, "f;");
    //             writeln("  mWeaponScale = ", mWeaponScale, "f;");
    //             writeln("===========================");
    //             break;
    //         default: break;
    //     }
    // }

    void handleTuning(int key)
    {
        import bindbc.sdl;
        float step = 0.02f;
        float rotStep = 0.05f;

        switch (key)
        {
            case SDLK_5: mOffsetUp += step; break;
            case SDLK_6: mOffsetUp -= step; break;
            case SDLK_7: mOffsetRight -= step; break;
            case SDLK_9: mOffsetRight += step; break;
            case SDLK_0: mOffsetFwd += step; break;
            case SDLK_MINUS: mOffsetFwd -= step; break;
            case SDLK_t: mExtraRotX -= rotStep; break;  // pitch up
            case SDLK_g: mExtraRotX += rotStep; break;  // pitch down
            case SDLK_y: mExtraRotY -= rotStep; break;  // yaw left
            case SDLK_h: mExtraRotY += rotStep; break;  // yaw right
            case SDLK_b: mExtraRotZ -= rotStep; break;  // roll left
            case SDLK_n: mExtraRotZ += rotStep; break;  // roll right
            case SDLK_EQUALS: mWeaponScale += 0.01f; break;
            case SDLK_LEFTBRACKET: mWeaponScale -= 0.01f; break;
            case SDLK_8:
                writeln("=== WEAPON TUNING SAVED ===");
                writeln("  mOffsetRight = ", mOffsetRight, "f;");
                writeln("  mOffsetUp = ", mOffsetUp, "f;");
                writeln("  mOffsetFwd = ", mOffsetFwd, "f;");
                writeln("  mExtraRotX = ", mExtraRotX, "f;");
                writeln("  mExtraRotY = ", mExtraRotY, "f;");
                writeln("  mExtraRotZ = ", mExtraRotZ, "f;");
                writeln("  mWeaponScale = ", mWeaponScale, "f;");
                writeln("===========================");
                break;
            default: break;
        }
    }

    void loadClip(string path, string clipName, bool loadAndPlay = false)
    {
        AnimationClip clip;
        clip.loadFromFile(path, clipName);
        mClips[clipName] = clip;

        if (loadAndPlay)
            playClip(clipName, true);
    }

    void playClip(string name, bool loop = false)
    {
        if (auto clip = name in mClips)
        {
            mCurrentClipName = name;
            mAnimator.play(clip, loop);
            writeln("[viewweapon] playing '", name, "' loop=", loop);
        }
        else
        {
            writeln("[viewweapon] WARNING: clip '", name, "' not found");
        }
    }

    void update(double deltaTime)
    {
        if (!mReady) return;

        // mAnimator.update(deltaTime);

        if (mAnimator.mFinished && mCurrentClipName != "idle")
        {
            playClip("idle", true);
        }

        mDebugAccum += deltaTime;
        if (mDebugAccum >= 5.0)
        {
            mDebugAccum = 0.0;
            writeln("[viewweapon/update] clip=", mCurrentClipName,
                    " bones=", mSkeleton.boneNames.length,
                    " meshes=", mSurfaces.length,
                    " scale=", mWeaponScale);
        }
    }

    void handleInput(int key)
    {
        // testing hooks if needed later
    }

    // void render()
    // {
    //     if (!mReady) return;

    //     glUseProgram(mShaderProgram);
    //     glDisable(GL_DEPTH_TEST);

    //     vec3 camPos = mCamera.mEyePosition;
    //     vec3 fwd = Normalize(mCamera.mForwardVector);
    //     vec3 right = Normalize(mCamera.mRightVector);
    //     vec3 up = Normalize(mCamera.mUpVector);

    //     vec3 weaponOffset = vec3(0.18f, -0.18f, 0.30f);
    //     vec3 weaponPos = camPos + right * weaponOffset.x
    //                             + up    * weaponOffset.y
    //                             + fwd   * weaponOffset.z;

    //     mat4 camRotation = mat4.init;
    //     camRotation[0]  = right.x;
    //     camRotation[1]  = right.y;
    //     camRotation[2]  = right.z;
    //     camRotation[3]  = 0;
    //     camRotation[4]  = up.x;
    //     camRotation[5]  = up.y;
    //     camRotation[6]  = up.z;
    //     camRotation[7]  = 0;
    //     camRotation[8]  = -fwd.x;
    //     camRotation[9]  = -fwd.y;
    //     camRotation[10] = -fwd.z;
    //     camRotation[11] = 0;

    //     mat4 translation = MatrixMakeTranslation(weaponPos);
    //     mat4 scale = MatrixMakeScale(vec3(mWeaponScale, mWeaponScale, mWeaponScale));
    //     mat4 modelMatrix = translation * camRotation * scale;

    //     if (mModelUniformLoc >= 0)
    //         glUniformMatrix4fv(mModelUniformLoc, 1, GL_TRUE, modelMatrix.DataPtr());
    //     if (mViewUniformLoc >= 0)
    //         glUniformMatrix4fv(mViewUniformLoc, 1, GL_TRUE, mCamera.mViewMatrix.DataPtr());
    //     if (mProjUniformLoc >= 0)
    //         glUniformMatrix4fv(mProjUniformLoc, 1, GL_TRUE, mCamera.mProjectionMatrix.DataPtr());

    //     if (mBoneUniformLoc >= 0)
    //     {
    //         float[] boneData;
    //         boneData.length = mAnimator.mBoneMatrices.length * 16;
    //         for (uint i = 0; i < mAnimator.mBoneMatrices.length; i++)
    //         {
    //             boneData[i * 16 .. (i + 1) * 16] = mAnimator.mBoneMatrices[i].Data();
    //         }

    //         glUniformMatrix4fv(
    //             mBoneUniformLoc,
    //             cast(int)mAnimator.mBoneMatrices.length,
    //             GL_TRUE,
    //             boneData.ptr
    //         );
    //     }

    //     static double renderDebugAccum = 0.0;
    //     renderDebugAccum += 1.0 / 60.0;
    //     if (renderDebugAccum >= 5.0)
    //     {
    //         renderDebugAccum = 0.0;
    //         writeln("[viewweapon/render] meshes=", mSurfaces.length,
    //                 " clip=", mCurrentClipName,
    //                 " scale=", mWeaponScale,
    //                 " bonesUniform=", mBoneUniformLoc,
    //                 " weaponPos=", weaponPos.x, ",", weaponPos.y, ",", weaponPos.z);
    //     }

    //     if (mTexUniformLoc >= 0)
    //         glUniform1i(mTexUniformLoc, 0);
    //     if (mLightUniformLoc >= 0)
    //         glUniform3f(mLightUniformLoc, 0.0f, 100.0f, 0.0f);

    //     glActiveTexture(GL_TEXTURE0);
    //     mMaterial.Update();
    //     glUseProgram(mShaderProgram);

    //     // Re-upload after possible program switch in material
    //     if (mModelUniformLoc >= 0)
    //         glUniformMatrix4fv(mModelUniformLoc, 1, GL_TRUE, modelMatrix.DataPtr());
    //     if (mViewUniformLoc >= 0)
    //         glUniformMatrix4fv(mViewUniformLoc, 1, GL_TRUE, mCamera.mViewMatrix.DataPtr());
    //     if (mProjUniformLoc >= 0)
    //         glUniformMatrix4fv(mProjUniformLoc, 1, GL_TRUE, mCamera.mProjectionMatrix.DataPtr());
    //     if (mTexUniformLoc >= 0)
    //         glUniform1i(mTexUniformLoc, 0);
    //     if (mLightUniformLoc >= 0)
    //         glUniform3f(mLightUniformLoc, 0.0f, 100.0f, 0.0f);

    //     if (mBoneUniformLoc >= 0)
    //     {
    //         float[] boneData;
    //         boneData.length = mAnimator.mBoneMatrices.length * 16;
    //         for (uint i = 0; i < mAnimator.mBoneMatrices.length; i++)
    //         {
    //             boneData[i * 16 .. (i + 1) * 16] = mAnimator.mBoneMatrices[i].Data();
    //         }

    //         glUniformMatrix4fv(
    //             mBoneUniformLoc,
    //             cast(int)mAnimator.mBoneMatrices.length,
    //             GL_TRUE,
    //             boneData.ptr
    //         );
    //     }

    //     foreach (surf; mSurfaces)
    //     {
    //         surf.Render();
    //     }

    //     glEnable(GL_DEPTH_TEST);
    // }


    void render()
    {
        if (!mReady) return;

        glUseProgram(mShaderProgram);

        // Disable depth test so weapon always renders on top
        glDisable(GL_DEPTH_TEST);
        glClear(GL_DEPTH_BUFFER_BIT);  // add this line


        // Build model matrix in VIEW SPACE
        // The weapon is placed relative to the camera, so we only need
        // offset + rotation + scale. The view matrix handles camera orientation.
        mat4 extraRot = MatrixMakeXRotation(mExtraRotX)
                      * MatrixMakeYRotation(mExtraRotY)
                      * MatrixMakeZRotation(mExtraRotZ);

        mat4 offset = MatrixMakeTranslation(vec3(mOffsetRight, mOffsetUp, mOffsetFwd));
        mat4 scale = MatrixMakeScale(vec3(mWeaponScale, mWeaponScale, mWeaponScale));

        mat4 modelMatrix = offset * extraRot * scale;

        // Upload matrices — use IDENTITY for view so weapon is in camera space
        mat4 identityView = mat4.init;
        glUniformMatrix4fv(mModelUniformLoc, 1, GL_TRUE, modelMatrix.DataPtr());
        glUniformMatrix4fv(mViewUniformLoc, 1, GL_TRUE, identityView.DataPtr());
        glUniformMatrix4fv(mProjUniformLoc, 1, GL_TRUE, mCamera.mProjectionMatrix.DataPtr());

        // Upload bone matrices
        if (mBoneUniformLoc >= 0)
        {
            float[] boneData;
            boneData.length = mAnimator.mBoneMatrices.length * 16;
            for (uint i = 0; i < mAnimator.mBoneMatrices.length; i++)
            {
                boneData[i * 16 .. (i + 1) * 16] = mAnimator.mBoneMatrices[i].Data();
            }
            glUniformMatrix4fv(
                mBoneUniformLoc,
                cast(int)mAnimator.mBoneMatrices.length,
                GL_TRUE,
                boneData.ptr);
        }

        // Upload texture
        if (mTexUniformLoc >= 0)
            glUniform1i(mTexUniformLoc, 0);

        // Upload light position
        if (mLightUniformLoc >= 0)
            glUniform3f(mLightUniformLoc, 0.0f, 100.0f, 0.0f);

        // Bind texture
        glActiveTexture(GL_TEXTURE0);
        mMaterial.Update();
        glUseProgram(mShaderProgram);

        // Draw meshes
        foreach (surf; mSurfaces)
        {
            surf.Render();
        }

        // Re-enable depth test
        glEnable(GL_DEPTH_TEST);
    }









    void playFire()
    {
        playClip("fire", false);
    }

    void playReload()
    {
        playClip("reload", false);
    }

    void playDraw()
    {
        playClip("draw", false);
    }

    void setWalking(bool walking)
    {
        if (walking && mCurrentClipName == "idle")
        {
            playClip("walk", true);
        }
        else if (!walking && mCurrentClipName == "walk")
        {
            playClip("idle", true);
        }
    }
}
