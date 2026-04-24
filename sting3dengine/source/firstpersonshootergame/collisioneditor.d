module collisioneditor;

import std.stdio;
import std.string : toStringz;
import std.math : abs, sqrt;
import std.conv : to;
import bindbc.opengl;
import bindbc.sdl;
import enginecore;
import linear;
import editor;

class CollisionEditor
{
    float[4][] mBoxes;
    string[] mBoxLabels;

    bool mEditorActive = false;
    bool mShowBoxes = true;
    int mSelectedBox = -1;
    float mBoxHeight = 3.0f;
    float mStep = 0.5f;
    bool[] mBoxSaved;

    GLuint mVAO, mVBO;
    GLuint mShaderProgram;
    GLint mModelLoc, mViewLoc, mProjLoc, mColorLoc;
    bool mInitialized = false;

    Camera mCamera;
    int mCollidingBox = -1;

    SDL_Cursor* mBlankCursor;
    SDL_Cursor* mArrowCursor;

    void init(Camera camera)
    {
        mCamera = camera;

        Pipeline debugPipeline = new Pipeline("debug_box",
            "./pipelines/debug_box/debug_box.vert",
            "./pipelines/debug_box/debug_box.frag");
        mShaderProgram = Pipeline.sPipeline["debug_box"];

        glUseProgram(mShaderProgram);
        mModelLoc = glGetUniformLocation(mShaderProgram, "uModel");
        mViewLoc = glGetUniformLocation(mShaderProgram, "uView");
        mProjLoc = glGetUniformLocation(mShaderProgram, "uProjection");
        mColorLoc = glGetUniformLocation(mShaderProgram, "uColor");

        float[] lines = buildWireframeCube();
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER,
            cast(GLsizeiptr)(lines.length * float.sizeof),
            lines.ptr, GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
        glBindVertexArray(0);

        mArrowCursor = SDL_CreateSystemCursor(SDL_SYSTEM_CURSOR_ARROW);
        auto blankData = new ubyte[4];
        blankData[] = 0;
        auto blankSurface = SDL_CreateRGBSurfaceFrom(
            blankData.ptr, 1, 1, 32, 4,
            0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
        if (blankSurface !is null)
        {
            mBlankCursor = SDL_CreateColorCursor(blankSurface, 0, 0);
            SDL_FreeSurface(blankSurface);
        }

        mInitialized = true;
        writeln("[collision-editor] initialized");
    }

    void addBox(float minX, float minZ, float maxX, float maxZ, string label = "")
    {
        mBoxes ~= [minX, minZ, maxX, maxZ];
        if (label == "")
            mBoxLabels ~= "box_" ~ (cast(int)mBoxes.length - 1).to!string;
        else
            mBoxLabels ~= label;
            mBoxSaved ~= false;
        mCamera.addCollisionBox(minX, minZ, maxX, maxZ);
    }

    void deleteBox(int idx)
    {
        if (idx < 0 || idx >= mBoxes.length) return;

        // Remove from local arrays
        for (int i = idx; i < cast(int)mBoxes.length - 1; i++)
        {
            mBoxes[i] = mBoxes[i + 1];
            mBoxLabels[i] = mBoxLabels[i + 1];
            mBoxSaved[i] = mBoxSaved[i + 1];
        }
        mBoxes.length -= 1;
        mBoxLabels.length -= 1;
        mBoxSaved.length -= 1;

        // Rebuild camera collision boxes from scratch
        mCamera.mCollisionBoxes.length = 0;
        foreach (box; mBoxes)
            mCamera.addCollisionBox(box[0], box[1], box[2], box[3]);

        if (mSelectedBox >= mBoxes.length)
            mSelectedBox = cast(int)mBoxes.length - 1;

        writeln("[collision-editor] deleted box ", idx, ", remaining: ", mBoxes.length);
    }

    void handleInput(int key)
    {
        const(ubyte)* keys = SDL_GetKeyboardState(null);
        if (key == SDLK_e && (keys[SDL_SCANCODE_LCTRL] || keys[SDL_SCANCODE_RCTRL]))
        {
            // mEditorActive = !mEditorActive;

            mEditorActive = !mEditorActive;
            mCamera.mEditorMode = mEditorActive;
            if (mEditorActive)
            {
                if (mArrowCursor !is null) SDL_SetCursor(mArrowCursor);
            }
            else
            {
                if (mBlankCursor !is null) SDL_SetCursor(mBlankCursor);
            }
            writeln("[collision-editor] ", mEditorActive ? "ENABLED" : "DISABLED");
            return;
        }

        if (!mEditorActive) return;

        switch (key)
        {
            case SDLK_p: printAllBoxes(); break;
            case SDLK_F4: mShowBoxes = !mShowBoxes; break;
            default: break;
        }
    }

    bool isActive() { return mEditorActive; }

    void syncToCamera(int idx)
    {
        if (idx >= 0 && idx < mCamera.mCollisionBoxes.length)
            mCamera.mCollisionBoxes[idx] = mBoxes[idx];
    }

    void updateCollisionState()
    {
        mCollidingBox = -1;
        float px = mCamera.mEyePosition.x;
        float pz = mCamera.mEyePosition.z;
        float margin = 0.5f;
        foreach (i, box; mBoxes)
        {
            if (px + margin > box[0] && px - margin < box[2] &&
                pz + margin > box[1] && pz - margin < box[3])
            {
                mCollidingBox = cast(int)i;
                break;
            }
        }
    }

    int findClosestBox()
    {
        if (mBoxes.length == 0) return -1;
        float px = mCamera.mEyePosition.x;
        float pz = mCamera.mEyePosition.z;
        int closest = 0;
        float bestDist = float.max;
        foreach (i, box; mBoxes)
        {
            float cx = (box[0] + box[2]) * 0.5f;
            float cz = (box[1] + box[3]) * 0.5f;
            float dx = px - cx;
            float dz = pz - cz;
            float dist = dx * dx + dz * dz;
            if (dist < bestDist) { bestDist = dist; closest = cast(int)i; }
        }
        return closest;
    }

    /// Helper: slider with +/- buttons
    bool sliderWithButtons(const(char)* label, float* val, float vmin, float vmax)
    {
        bool changed = false;

        igPushItemWidth(160);
        if (igSliderFloat(label, val, vmin, vmax, "%.2f", 0))
            changed = true;
        igPopItemWidth();

        igSameLine(0, 4);
        // Build unique button IDs from label
        char[64] minusId;
        char[64] plusId;
        import core.stdc.stdio : snprintf;
        snprintf(minusId.ptr, 64, "-##%s", label);
        snprintf(plusId.ptr, 64, "+##%s", label);

        if (igButton(minusId.ptr, 20, 20))
        {
            *val -= mStep;
            if (*val < vmin) *val = vmin;
            changed = true;
        }
        igSameLine(0, 2);
        if (igButton(plusId.ptr, 20, 20))
        {
            *val += mStep;
            if (*val > vmax) *val = vmax;
            changed = true;
        }
        return changed;
    }

    void renderGUI(int screenWidth, int screenHeight)
    {
        if (!mEditorActive) return;

        igSetNextWindowPos(cast(float)screenWidth - 340, 40, 2, 0, 0);
        igSetNextWindowBgAlpha(0.94f);
        igBegin("Collision Box Editor", null, ImGuiWindowFlags_AlwaysAutoResize);

        // ==== Header ====
        ImVec4 cyan = ImVec4(0.3f, 0.9f, 1.0f, 1.0f);
        igTextColored(cyan, "== COLLISION BOX EDITOR ==");
        igText("CTRL+E close | P print all | F4 toggle vis");
        igSeparator();

        // ==== Step Size ====
        igText("Step Size:");
        igSameLine(0, 5);
        igPushItemWidth(80);
        igSliderFloat("##step", &mStep, 0.05f, 5.0f, "%.2f", 0);
        igPopItemWidth();
        igSameLine(0, 4);
        if (igButton("0.1##st", 30, 20)) mStep = 0.1f;
        igSameLine(0, 2);
        if (igButton("0.25##st", 35, 20)) mStep = 0.25f;
        igSameLine(0, 2);
        if (igButton("0.5##st", 30, 20)) mStep = 0.5f;
        igSameLine(0, 2);
        if (igButton("1.0##st", 30, 20)) mStep = 1.0f;

        igSeparator();

        // ==== Navigation ====
        ImVec4 green = ImVec4(0.4f, 1.0f, 0.4f, 1.0f);
        igTextColored(green, "Navigation");
        igText("Boxes: %d", cast(int)mBoxes.length);

        if (igButton("< Prev##nav", 65, 24))
        {
            if (mBoxes.length > 0)
                mSelectedBox = mSelectedBox <= 0 ? cast(int)mBoxes.length - 1 : mSelectedBox - 1;
        }
        igSameLine(0, 3);
        if (igButton("Next >##nav", 65, 24))
        {
            if (mBoxes.length > 0)
                mSelectedBox = (mSelectedBox + 1) % cast(int)mBoxes.length;
        }
        igSameLine(0, 3);
        if (igButton("Closest##nav", 65, 24))
            mSelectedBox = findClosestBox();
        igSameLine(0, 3);
        if (igButton("+ New##nav", 60, 24))
        {
            float cx = mCamera.mEyePosition.x;
            float cz = mCamera.mEyePosition.z;
            addBox(cx - 3, cz - 3, cx + 3, cz + 3, "new_" ~ (cast(int)mBoxes.length).to!string);
            mSelectedBox = cast(int)mBoxes.length - 1;
        }

        igSeparator();

        // ==== Selected Box ====
        if (mSelectedBox >= 0 && mSelectedBox < mBoxes.length)
        {
            ImVec4 yellow = ImVec4(1, 1, 0, 1);
            igTextColored(yellow, "Box %d: '%s'", mSelectedBox, mBoxLabels[mSelectedBox].toStringz);

            // ---- Edges ----
            ImVec4 orange = ImVec4(1.0f, 0.7f, 0.3f, 1.0f);
            igTextColored(orange, "Edges:");

            float centerX = (mBoxes[mSelectedBox][0] + mBoxes[mSelectedBox][2]) * 0.5f;
            float centerZ = (mBoxes[mSelectedBox][1] + mBoxes[mSelectedBox][3]) * 0.5f;
            bool changed = false;

            if (sliderWithButtons("Left (minX)##e", &mBoxes[mSelectedBox][0],
                    centerX - 60, mBoxes[mSelectedBox][2] - 0.5f))
                changed = true;
            if (sliderWithButtons("Right (maxX)##e", &mBoxes[mSelectedBox][2],
                    mBoxes[mSelectedBox][0] + 0.5f, centerX + 60))
                changed = true;
            if (sliderWithButtons("Near (minZ)##e", &mBoxes[mSelectedBox][1],
                    centerZ - 60, mBoxes[mSelectedBox][3] - 0.5f))
                changed = true;
            if (sliderWithButtons("Far (maxZ)##e", &mBoxes[mSelectedBox][3],
                    mBoxes[mSelectedBox][1] + 0.5f, centerZ + 60))
                changed = true;

            if (changed) syncToCamera(mSelectedBox);

            igSeparator();

            // ---- Move ----
            igTextColored(orange, "Move:");
            float cx = (mBoxes[mSelectedBox][0] + mBoxes[mSelectedBox][2]) * 0.5f;
            float cz = (mBoxes[mSelectedBox][1] + mBoxes[mSelectedBox][3]) * 0.5f;

            float newCx = cx;
            float newCz = cz;

            if (sliderWithButtons("Center X##m", &newCx, cx - 40, cx + 40))
            {
                float dx = newCx - cx;
                mBoxes[mSelectedBox][0] += dx;
                mBoxes[mSelectedBox][2] += dx;
                syncToCamera(mSelectedBox);
            }
            if (sliderWithButtons("Center Z##m", &newCz, cz - 40, cz + 40))
            {
                float dz = newCz - cz;
                mBoxes[mSelectedBox][1] += dz;
                mBoxes[mSelectedBox][3] += dz;
                syncToCamera(mSelectedBox);
            }

            igSeparator();

            // ---- Size ----
            igTextColored(orange, "Size:");
            float width = mBoxes[mSelectedBox][2] - mBoxes[mSelectedBox][0];
            float depth = mBoxes[mSelectedBox][3] - mBoxes[mSelectedBox][1];
            float newWidth = width;
            float newDepth = depth;

            if (sliderWithButtons("Width (X)##s", &newWidth, 0.5f, 60.0f))
            {
                float diff = (newWidth - width) * 0.5f;
                mBoxes[mSelectedBox][0] -= diff;
                mBoxes[mSelectedBox][2] += diff;
                syncToCamera(mSelectedBox);
            }
            if (sliderWithButtons("Depth (Z)##s", &newDepth, 0.5f, 60.0f))
            {
                float diff = (newDepth - depth) * 0.5f;
                mBoxes[mSelectedBox][1] -= diff;
                mBoxes[mSelectedBox][3] += diff;
                syncToCamera(mSelectedBox);
            }

            igSeparator();

            // ---- Info ----
            igText("  center: (%.2f, %.2f)", 
                    (mBoxes[mSelectedBox][0] + mBoxes[mSelectedBox][2]) * 0.5f,
                    (mBoxes[mSelectedBox][1] + mBoxes[mSelectedBox][3]) * 0.5f);
            igText("  size:   %.2f x %.2f",
                    mBoxes[mSelectedBox][2] - mBoxes[mSelectedBox][0],
                    mBoxes[mSelectedBox][3] - mBoxes[mSelectedBox][1]);

            igSeparator();

            // ---- Actions ----
            igTextColored(orange, "Actions:");
            if (igButton("Duplicate##act", 80, 24))
            {
                auto box = mBoxes[mSelectedBox];
                addBox(box[0] + 2, box[1] + 2, box[2] + 2, box[3] + 2,
                       mBoxLabels[mSelectedBox] ~ "_copy");
                mSelectedBox = cast(int)mBoxes.length - 1;
            }
            igSameLine(0, 3);
            if (igButton("Snap Here##act", 80, 24))
            {
                float pcx = mCamera.mEyePosition.x;
                float pcz = mCamera.mEyePosition.z;
                float ddx = pcx - (mBoxes[mSelectedBox][0] + mBoxes[mSelectedBox][2]) * 0.5f;
                float ddz = pcz - (mBoxes[mSelectedBox][1] + mBoxes[mSelectedBox][3]) * 0.5f;
                mBoxes[mSelectedBox][0] += ddx;
                mBoxes[mSelectedBox][2] += ddx;
                mBoxes[mSelectedBox][1] += ddz;
                mBoxes[mSelectedBox][3] += ddz;
                syncToCamera(mSelectedBox);
            }
            igSameLine(0, 3);
            igSameLine(0, 3);
            if (mBoxSaved[mSelectedBox])
            {
                ImVec4 blue = ImVec4(0.3f, 0.5f, 1.0f, 1.0f);
                igTextColored(blue, "SAVED");
            }
            else
            {
                if (igButton("Save##act", 50, 24))
                {
                    mBoxSaved[mSelectedBox] = true;
                    auto box = mBoxes[mSelectedBox];
                    writeln("=== SAVED BOX ", mSelectedBox, " ===");
                    writeln("  mCollisionEditor.addBox(",
                            box[0], "f, ", box[1], "f, ",
                            box[2], "f, ", box[3], "f, \"",
                            mBoxLabels[mSelectedBox], "\");");
                    writeln("========================");
                }
            }

            // Delete button — red colored, separate row
            igSeparator();
            ImVec4 red = ImVec4(1, 0.2f, 0.2f, 1);
            igTextColored(red, "Danger:");
            igSameLine(0, 5);
            if (igButton("DELETE Box##del", 120, 26))
            {
                writeln("[collision-editor] deleting box ", mSelectedBox, " '", mBoxLabels[mSelectedBox], "'");
                deleteBox(mSelectedBox);
            }
        }
        else
        {
            igText("No box selected.");
            igText("Click 'Next', 'Closest', or '+ New'.");
        }

        igSeparator();

        // ==== Global ====
        if (igButton("Print ALL##global", 100, 26))
            printAllBoxes();
        igSameLine(0, 3);
        if (igButton(mShowBoxes ? "Hide##vis" : "Show##vis", 60, 26))
            mShowBoxes = !mShowBoxes;

        // Collision warning
        if (mCollidingBox >= 0)
        {
            igSeparator();
            ImVec4 red = ImVec4(1, 0, 0, 1);
            igTextColored(red, "!! COLLIDING: box %d !!", mCollidingBox);
        }

        // Camera position for reference
        igSeparator();
        ImVec4 dim = ImVec4(0.6f, 0.6f, 0.6f, 1.0f);
        igTextColored(dim, "Camera: (%.1f, %.1f)", mCamera.mEyePosition.x, mCamera.mEyePosition.z);

        igEnd();
    }

    void render()
    {
        if (!mInitialized || !mShowBoxes || mBoxes.length == 0) return;

        updateCollisionState();

        glUseProgram(mShaderProgram);
        glUniformMatrix4fv(mViewLoc, 1, GL_TRUE, mCamera.mViewMatrix.DataPtr());
        glUniformMatrix4fv(mProjLoc, 1, GL_TRUE, mCamera.mProjectionMatrix.DataPtr());

        glBindVertexArray(mVAO);
        glLineWidth(2.0f);
        glDisable(GL_DEPTH_TEST);

        foreach (i, box; mBoxes)
        {
            float cx = (box[0] + box[2]) * 0.5f;
            float cz = (box[1] + box[3]) * 0.5f;
            float hw = (box[2] - box[0]) * 0.5f;
            float hd = (box[3] - box[1]) * 0.5f;

            mat4 model = MatrixMakeTranslation(vec3(cx, mBoxHeight * 0.5f, cz))
                       * MatrixMakeScale(vec3(hw, mBoxHeight * 0.5f, hd));
            glUniformMatrix4fv(mModelLoc, 1, GL_TRUE, model.DataPtr());

            // if (cast(int)i == mCollidingBox)
            //     glUniform3f(mColorLoc, 1.0f, 0.0f, 0.0f);
            // else if (cast(int)i == mSelectedBox)
            //     glUniform3f(mColorLoc, 1.0f, 1.0f, 0.0f);
            // else
            //     glUniform3f(mColorLoc, 0.0f, 1.0f, 0.0f);

            if (cast(int)i == mCollidingBox)
                glUniform3f(mColorLoc, 1.0f, 0.0f, 0.0f);       // red = colliding
            else if (cast(int)i == mSelectedBox)
                glUniform3f(mColorLoc, 1.0f, 1.0f, 0.0f);       // yellow = selected
            else if (mBoxSaved[i])
                glUniform3f(mColorLoc, 0.3f, 0.5f, 1.0f);       // blue = saved
            else
                glUniform3f(mColorLoc, 0.0f, 1.0f, 0.0f);       // green = unsaved

            glDrawArrays(GL_LINES, 0, 24);
        }

        glEnable(GL_DEPTH_TEST);
        glBindVertexArray(0);
    }

    void printAllBoxes()
    {
        writeln("=== ALL COLLISION BOXES ===");
        foreach (i, box; mBoxes)
        {
            writeln("  mCollisionEditor.addBox(",
                    box[0], "f, ", box[1], "f, ",
                    box[2], "f, ", box[3], "f, \"",
                    mBoxLabels[i], "\");");
        }
        writeln("===========================");
    }

    private static float[] buildWireframeCube()
    {
        float[] v;
        v ~= [-1,-1,-1,  1,-1,-1];
        v ~= [ 1,-1,-1,  1,-1, 1];
        v ~= [ 1,-1, 1, -1,-1, 1];
        v ~= [-1,-1, 1, -1,-1,-1];
        v ~= [-1, 1,-1,  1, 1,-1];
        v ~= [ 1, 1,-1,  1, 1, 1];
        v ~= [ 1, 1, 1, -1, 1, 1];
        v ~= [-1, 1, 1, -1, 1,-1];
        v ~= [-1,-1,-1, -1, 1,-1];
        v ~= [ 1,-1,-1,  1, 1,-1];
        v ~= [ 1,-1, 1,  1, 1, 1];
        v ~= [-1,-1, 1, -1, 1, 1];
        return v;
    }
}
