/// Animator: plays animation clips on a skeleton.
/// Each frame, the animator:
///   1. Advances the current time
///   2. For each bone, finds the two nearest keyframes and interpolates
///   3. Walks the bone hierarchy: child = parent × local
///   4. Applies inverse bind matrix: final = global × inverseBindPose
///   5. Produces a mat4[] array ready for the skinning shader

module animator;

import std.stdio;
import std.math : sqrt, acos, sin, abs;
import linear;
import skeleton;
import animationclip;

struct Animator
{
    Skeleton* mSkeleton;
    AnimationClip* mCurrentClip;
    double mCurrentTime = 0.0;
    bool mLooping = false;
    bool mPlaying = false;
    bool mFinished = false;

    mat4[] mBoneMatrices;      // final skinning matrices (sent to shader)
    mat4[] mGlobalTransforms;  // world-space bone transforms (for gameplay queries)

    void init(Skeleton* skel)
    {
        mSkeleton = skel;
        mBoneMatrices.length = skel.boneNames.length;
        mGlobalTransforms.length = skel.boneNames.length;

        // Initialize to identity
        foreach (ref m; mBoneMatrices)
            m = mat4.init;
        foreach (ref m; mGlobalTransforms)
            m = mat4.init;
    }

    void play(AnimationClip* clip, bool loop = false)
    {
        mCurrentClip = clip;
        mCurrentTime = 0.0;
        mLooping = loop;
        mPlaying = true;
        mFinished = false;
    }

    void stop()
    {
        mPlaying = false;
    }

    /// Advance animation time and compute bone matrices
    void update(double deltaTime)
    {
        if (!mPlaying || mCurrentClip is null || mSkeleton is null)
            return;

        // Advance time in ticks
        mCurrentTime += deltaTime * mCurrentClip.ticksPerSecond;

        if (mCurrentTime >= mCurrentClip.duration)
        {
            if (mLooping)
            {
                // Wrap around
                while (mCurrentTime >= mCurrentClip.duration)
                    mCurrentTime -= mCurrentClip.duration;
            }
            else
            {
                mCurrentTime = mCurrentClip.duration - 0.001;
                mFinished = true;
                mPlaying = false;
            }
        }

        computeBoneMatrices();
    }

    /// Get the bone world matrix for gameplay queries (e.g. muzzle position)
    mat4 getBoneWorldMatrix(string boneName)
    {
        int idx = mSkeleton.getBoneIndex(boneName);
        if (idx < 0) return mat4.init;
        return mGlobalTransforms[idx];
    }

    /// Check if current animation is past a specific frame number
    bool isPastFrame(int frameNumber)
    {
        if (mCurrentClip is null) return false;
        return cast(int)mCurrentTime >= frameNumber;
    }

    private void computeBoneMatrices()
    {
        // For each bone, compute local transform from keyframes
        // Then walk hierarchy: global = parent_global × local
        // Then final = global × inverseBindPose

        auto numBones = mSkeleton.boneNames.length;

        // Compute local transforms from animation
        mat4[] localTransforms;
        localTransforms.length = numBones;

        for (uint i = 0; i < numBones; i++)
        {
            string boneName = mSkeleton.boneNames[i];
            BoneChannel* ch = mCurrentClip.getChannel(boneName);

            if (ch !is null)
            {
                vec3 pos = interpolatePosition(ch, mCurrentTime);
                float[4] rot = interpolateRotation(ch, mCurrentTime);
                vec3 scl = interpolateScale(ch, mCurrentTime);

                mat4 T = MatrixMakeTranslation(pos);
                mat4 R = quatToMat4(rot[0], rot[1], rot[2], rot[3]);
                mat4 S = MatrixMakeScale(scl);

                localTransforms[i] = T * R * S;
            }
            else
            {
                localTransforms[i] = mat4.init;
            }
        }

        // Walk hierarchy: global = parent × local
        for (uint i = 0; i < numBones; i++)
        {
            int parentIdx = mSkeleton.parentIndices[i];
            if (parentIdx >= 0)
                mGlobalTransforms[i] = mGlobalTransforms[parentIdx] * localTransforms[i];
            else
                mGlobalTransforms[i] = localTransforms[i];
        }

        // Final skinning matrix = global × inverseBindPose
        for (uint i = 0; i < numBones; i++)
        {
            mBoneMatrices[i] = mGlobalTransforms[i] * mSkeleton.inverseBindMatrices[i];
        }
    }

    /// Interpolate position between two keyframes
    private static vec3 interpolatePosition(BoneChannel* ch, double time)
    {
        if (ch.positionKeys.length == 1)
            return ch.positionKeys[0].value;

        // Find the two keyframes surrounding 'time'
        uint idx0 = 0;
        for (uint i = 0; i < ch.positionKeys.length - 1; i++)
        {
            if (time < ch.positionKeys[i + 1].time)
            {
                idx0 = i;
                break;
            }
            idx0 = i;
        }
        uint idx1 = idx0 + 1;
        if (idx1 >= ch.positionKeys.length)
            return ch.positionKeys[idx0].value;

        double t0 = ch.positionKeys[idx0].time;
        double t1 = ch.positionKeys[idx1].time;
        float factor = cast(float)((time - t0) / (t1 - t0));
        if (factor < 0) factor = 0;
        if (factor > 1) factor = 1;

        vec3 a = ch.positionKeys[idx0].value;
        vec3 b = ch.positionKeys[idx1].value;

        return vec3(
            a.x + (b.x - a.x) * factor,
            a.y + (b.y - a.y) * factor,
            a.z + (b.z - a.z) * factor
        );
    }

    /// Interpolate rotation (quaternion slerp) between two keyframes
    private static float[4] interpolateRotation(BoneChannel* ch, double time)
    {
        if (ch.rotationKeys.length == 1)
            return [ch.rotationKeys[0].w, ch.rotationKeys[0].x,
                    ch.rotationKeys[0].y, ch.rotationKeys[0].z];

        uint idx0 = 0;
        for (uint i = 0; i < ch.rotationKeys.length - 1; i++)
        {
            if (time < ch.rotationKeys[i + 1].time)
            {
                idx0 = i;
                break;
            }
            idx0 = i;
        }
        uint idx1 = idx0 + 1;
        if (idx1 >= ch.rotationKeys.length)
            return [ch.rotationKeys[idx0].w, ch.rotationKeys[idx0].x,
                    ch.rotationKeys[idx0].y, ch.rotationKeys[idx0].z];

        double t0 = ch.rotationKeys[idx0].time;
        double t1 = ch.rotationKeys[idx1].time;
        float factor = cast(float)((time - t0) / (t1 - t0));
        if (factor < 0) factor = 0;
        if (factor > 1) factor = 1;

        // Slerp
        float aw = ch.rotationKeys[idx0].w;
        float ax = ch.rotationKeys[idx0].x;
        float ay = ch.rotationKeys[idx0].y;
        float az = ch.rotationKeys[idx0].z;

        float bw = ch.rotationKeys[idx1].w;
        float bx = ch.rotationKeys[idx1].x;
        float by = ch.rotationKeys[idx1].y;
        float bz = ch.rotationKeys[idx1].z;

        return slerp(aw, ax, ay, az, bw, bx, by, bz, factor);
    }

    /// Interpolate scale between two keyframes
    private static vec3 interpolateScale(BoneChannel* ch, double time)
    {
        if (ch.scaleKeys.length == 1)
            return ch.scaleKeys[0].value;

        uint idx0 = 0;
        for (uint i = 0; i < ch.scaleKeys.length - 1; i++)
        {
            if (time < ch.scaleKeys[i + 1].time)
            {
                idx0 = i;
                break;
            }
            idx0 = i;
        }
        uint idx1 = idx0 + 1;
        if (idx1 >= ch.scaleKeys.length)
            return ch.scaleKeys[idx0].value;

        double t0 = ch.scaleKeys[idx0].time;
        double t1 = ch.scaleKeys[idx1].time;
        float factor = cast(float)((time - t0) / (t1 - t0));
        if (factor < 0) factor = 0;
        if (factor > 1) factor = 1;

        vec3 a = ch.scaleKeys[idx0].value;
        vec3 b = ch.scaleKeys[idx1].value;

        return vec3(
            a.x + (b.x - a.x) * factor,
            a.y + (b.y - a.y) * factor,
            a.z + (b.z - a.z) * factor
        );
    }

    /// Quaternion spherical linear interpolation
    private static float[4] slerp(
        float aw, float ax, float ay, float az,
        float bw, float bx, float by, float bz,
        float t)
    {
        // Dot product
        float dot = aw * bw + ax * bx + ay * by + az * bz;

        // If negative dot, negate one quaternion to take shorter path
        if (dot < 0)
        {
            bw = -bw; bx = -bx; by = -by; bz = -bz;
            dot = -dot;
        }

        // If very close, use linear interpolation to avoid division by zero
        if (dot > 0.9995f)
        {
            float rw = aw + (bw - aw) * t;
            float rx = ax + (bx - ax) * t;
            float ry = ay + (by - ay) * t;
            float rz = az + (bz - az) * t;

            // Normalize
            float len = sqrt(rw * rw + rx * rx + ry * ry + rz * rz);
            return [rw / len, rx / len, ry / len, rz / len];
        }

        float theta0 = acos(dot);
        float theta = theta0 * t;
        float sinTheta = sin(theta);
        float sinTheta0 = sin(theta0);

        float s0 = sin(theta0 - theta) / sinTheta0;
        float s1 = sinTheta / sinTheta0;

        return [
            aw * s0 + bw * s1,
            ax * s0 + bx * s1,
            ay * s0 + by * s1,
            az * s0 + bz * s1
        ];
    }

    /// Convert quaternion (w, x, y, z) to a 4x4 rotation matrix
    private static mat4 quatToMat4(float w, float x, float y, float z)
    {
        mat4 m = mat4.init;

        float xx = x * x, yy = y * y, zz = z * z;
        float xy = x * y, xz = x * z, yz = y * z;
        float wx = w * x, wy = w * y, wz = w * z;

        m[0]  = 1.0f - 2.0f * (yy + zz);
        m[1]  = 2.0f * (xy + wz);
        m[2]  = 2.0f * (xz - wy);

        m[4]  = 2.0f * (xy - wz);
        m[5]  = 1.0f - 2.0f * (xx + zz);
        m[6]  = 2.0f * (yz + wx);

        m[8]  = 2.0f * (xz + wy);
        m[9]  = 2.0f * (yz - wx);
        m[10] = 1.0f - 2.0f * (xx + yy);

        return m;
    }
}
