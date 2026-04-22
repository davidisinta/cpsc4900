module camera;

import linear;
import bindbc.opengl;
import std.math : PI, asin, cos, sin;

class Camera{
    mat4 mViewMatrix;
    mat4 mProjectionMatrix;

    vec3 mEyePosition;
    vec3 mUpVector;
    vec3 mForwardVector;
    vec3 mRightVector;

    float mYaw   = 0.0f;
    float mPitch = 0.0f;

    float mMoveSpeed = 0.1f;
    float mMouseSensitivity = 0.005f;

    this(){
        mViewMatrix = MatrixMakeIdentity();

        // to do: 
        // see if viable to change aspect ratio to this cast(float)mScreenWidth / cast(float)mScreenHeight
        mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians, 480.0f/640.0f, 0.1f, 1000.0f);

        mEyePosition = vec3(1.0f, 1.7f, 1.0f);
        mUpVector    = vec3(0.0f, 1.0f, 0.0f);

        updateVectors();
        UpdateViewMatrix();
    }

    void updateVectors()
    {
        vec3 fwd;
        fwd.x = cos(mYaw) * cos(mPitch);
        fwd.y = sin(mPitch);
        fwd.z = sin(mYaw) * cos(mPitch);
        mForwardVector = Normalize(fwd);

        mRightVector = Normalize(Cross(mForwardVector, vec3(0.0f, 1.0f, 0.0f)));
        mUpVector = Normalize(Cross(mRightVector, mForwardVector));
    }

    void SetCameraPosition(vec3 v){
        mEyePosition = v;
    }

    void SetCameraPosition(float x, float y, float z){
        mEyePosition = vec3(x, y, z);
    }

    mat4 UpdateViewMatrix(){
        // Build view matrix manually: dot-product form
        // This avoids the transpose/negation confusion entirely
        vec3 f = mForwardVector;
        vec3 r = mRightVector;
        vec3 u = mUpVector;
        vec3 e = mEyePosition;

        mViewMatrix = mat4(
             r.x,  r.y,  r.z, -(Dot(r, e)),
             u.x,  u.y,  u.z, -(Dot(u, e)),
            -f.x, -f.y, -f.z,   Dot(f, e),
             0.0f, 0.0f, 0.0f,  1.0f
        );

        return mViewMatrix;
    }

    void MouseLook(int deltaX, int deltaY){
        float dx = cast(float)deltaX * mMouseSensitivity;
        float dy = cast(float)deltaY * mMouseSensitivity;

        mYaw   += dx;
        mPitch -= dy;

        if (mPitch >  1.4f) mPitch =  1.4f;
        if (mPitch < -1.4f) mPitch = -1.4f;

        updateVectors();
        UpdateViewMatrix();
    }

    void MoveForward(){
        vec3 groundForward = Normalize(vec3(mForwardVector.x, 0.0f, mForwardVector.z));
        mEyePosition = mEyePosition + groundForward * mMoveSpeed;
        UpdateViewMatrix();
    }

    void MoveBackward(){
        vec3 groundForward = Normalize(vec3(mForwardVector.x, 0.0f, mForwardVector.z));
        mEyePosition = mEyePosition - groundForward * mMoveSpeed;
        UpdateViewMatrix();
    }

    void MoveLeft(){
        vec3 groundRight = Normalize(vec3(mRightVector.x, 0.0f, mRightVector.z));
        mEyePosition = mEyePosition - groundRight * mMoveSpeed;
        UpdateViewMatrix();
    }

    void MoveRight(){
        vec3 groundRight = Normalize(vec3(mRightVector.x, 0.0f, mRightVector.z));
        mEyePosition = mEyePosition + groundRight * mMoveSpeed;
        UpdateViewMatrix();
    }

    void MoveUp(){
        mEyePosition.y = mEyePosition.y + 0.5f;
        UpdateViewMatrix();
    }

    void MoveDown(){
        mEyePosition.y = mEyePosition.y - 0.5f;
        UpdateViewMatrix();
    }
}
