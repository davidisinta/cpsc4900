module renderer;

import bindbc.sdl;
import bindbc.opengl;
import std.stdio;

import camera, scene, mesh, linear, frustum;

class Renderer {
    SDL_Window* mWindow;
    int mScreenWidth;
    int mScreenHeight;

    bool mFrustumCullingEnabled = true;
    int mDrawnCount = 0;
    int mCulledCount = 0;

    bool mDrawDistanceEnabled = true;
    float mDrawDistance = 200.0f;
    int mDistanceCulledCount = 0;

    this(SDL_Window* window, int width, int height) {
        mWindow = window;
        mScreenWidth = width;
        mScreenHeight = height;
    }


    void Render(SceneTree s, Camera c, double frameDt) {
        mDrawnCount = 0;
        mCulledCount = 0;
        mDistanceCulledCount = 0;

        s.SetCamera(c);

        mat4 vp = c.mProjectionMatrix * c.mViewMatrix;
        FrustumPlane[6] planes = extractFrustumPlanes(vp);

        traverseNode(s.GetRootNode(), planes, c.mEyePosition);

        // Performance logging every 5 seconds
        static int logFrameCount = 0;
        static double logTimer = 0.0;
        static int drawnSum = 0;
        static int culledSum = 0;
        static int distCulledSum = 0;

        logFrameCount++;
        drawnSum += mDrawnCount;
        culledSum += mCulledCount;
        distCulledSum += mDistanceCulledCount;
        logTimer += frameDt;

        if (logTimer >= 5.0)
        {
            int avgDrawn = drawnSum / logFrameCount;
            int avgCulled = culledSum / logFrameCount;
            int avgDistCulled = distCulledSum / logFrameCount;
            int avgFps = cast(int)(logFrameCount / logTimer);

            writeln("=== PERF REPORT ===");
            writeln("  Frustum Culling: ", mFrustumCullingEnabled ? "ON" : "OFF");
            writeln("  Draw Distance: ", mDrawDistanceEnabled ? "ON" : "OFF", " (", mDrawDistance, " units)");
            writeln("  Avg Drawn: ", avgDrawn);
            writeln("  Avg Frustum Culled: ", avgCulled);
            writeln("  Avg Distance Culled: ", avgDistCulled);
            writeln("  Total: ", avgDrawn + avgCulled + avgDistCulled);
            writeln("  Avg FPS (5s): ", avgFps);
            writeln("===================");

            logFrameCount = 0;
            logTimer = 0.0;
            drawnSum = 0;
            culledSum = 0;
            distCulledSum = 0;
        }
    }

    private void traverseNode(ISceneNode node, FrustumPlane[6] planes, vec3 cameraPos) {
        MeshNode meshNode = cast(MeshNode)node;

        if (meshNode !is null) {
            vec3 center = vec3(
                meshNode.mModelMatrix[3],
                meshNode.mModelMatrix[7],
                meshNode.mModelMatrix[11]
            );

            // Frustum culling
            if (mFrustumCullingEnabled && meshNode.mBoundingRadius > 0.0f) {
                if (!isSphereInFrustum(planes, center, meshNode.mBoundingRadius)) {
                    mCulledCount++;
                    // Still recurse children
                    foreach (child; node.mChildren)
                        traverseNode(child, planes, cameraPos);
                    return;
                }
            }

            // Draw distance cutoff
            if (mDrawDistanceEnabled && meshNode.mBoundingRadius > 0.0f) {
                float dx = center.x - cameraPos.x;
                float dy = center.y - cameraPos.y;
                float dz = center.z - cameraPos.z;
                float distSq = dx*dx + dy*dy + dz*dz;

                if (distSq > mDrawDistance * mDrawDistance) {
                    mDistanceCulledCount++;
                    foreach (child; node.mChildren)
                        traverseNode(child, planes, cameraPos);
                    return;
                }
            }

            meshNode.Update();
            mDrawnCount++;
        }

        foreach (child; node.mChildren) {
            traverseNode(child, planes, cameraPos);
        }
    }
}
