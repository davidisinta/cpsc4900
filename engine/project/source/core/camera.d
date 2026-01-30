/// This represents a camera abstraction.
module camera;

import linear;
import bindbc.opengl;
import std.math;
import std.stdio;

/// Camera abstraction.
class Camera{
    mat4 mViewMatrix;
    mat4 mProjectionMatrix;
    bool firstMouse = true;
    int lastX;
    int lastY;
    float yaw;
    float pitch;
    vec3 cameraFront;
    int count;
    double movementSpeed;

    vec3 mEyePosition;          /// This is our 'translation' value
    // Axis of the camera
    vec3 mUpVector;             /// This is 'up' in the world
    vec3 mForwardVector;        /// This is on the camera axis
    vec3 mRightVector;          /// This is where 'right' is

    /// Constructor for a camera
    this(){
        // Setup our camera (view matrix) 
        mViewMatrix = MatrixMakeIdentity();

        // Setup our perspective projection matrix
        // NOTE: Assumption made here is our window is always 640/480 or the similar aspect ratio.
        mProjectionMatrix = MatrixMakePerspective(90.0f.ToRadians,480.0f/640.0f, 0.1f, 100.0f);

        /// Initial Camera setup
        mEyePosition    = vec3(0.0f, 0.0f, 0.0f);
        // Eye position
        // Forward vector matching the positive z-axis
        mForwardVector  = vec3(0.0f, 0.0f, 1.0f);
        // Where up is in the world initially
        mUpVector       = vec3(0.0f,1.0f,0.0f);
        // Where right is initially
        mRightVector    = vec3(1.0f, 0.0f, 0.0f);
        //init yaw and pitch and other variables
        yaw = -90.0f;
        lastX = 400;
        lastY = 300;
        count = 0;
        movementSpeed = 0.1f;
    }

    /// Position the eye of the camera in the world
    void SetCameraPosition(vec3 v){
        UpdateViewMatrix();
        mEyePosition = v;
    }
    /// Position the eye of the camera in the world
    void SetCameraPosition(float x, float y, float z){
        UpdateViewMatrix();
        mEyePosition = vec3(x,y,z);
    }

    /// Builds a matrix for where the matrix is looking
    /// given the following parameters
    mat4 LookAt(vec3 eye, vec3 direction, vec3 up){
        mat4 result;

        mRightVector =  Normalize(Cross(mUpVector, direction));
        mUpVector = Normalize(Cross(direction, mRightVector));

        mat4 rotationMatrix = MatrixMakeIdentity();
        //set the 9 values in the identity matrix
        rotationMatrix[0] = mRightVector.x;
        rotationMatrix[1] = mRightVector.y;
        rotationMatrix[2] = mRightVector.z;
        rotationMatrix[4] = mUpVector.x;
        rotationMatrix[5] = mUpVector.y;
        rotationMatrix[6] = mUpVector.z;
        rotationMatrix[8] = direction.x;
        rotationMatrix[9] = direction.y;
        rotationMatrix[10] = direction.z;

        mat4 translationMatrix = MatrixMakeIdentity();
        translationMatrix[3] = -eye.x;
        translationMatrix[7] = -eye.y;
        translationMatrix[11] = -eye.z;

        result = rotationMatrix * translationMatrix;
        return result; 
    }

    /// Sets the view matrix and also retrieves it
    /// Retrieves the camera view matrix
    mat4 UpdateViewMatrix(){
        mViewMatrix = LookAt(mEyePosition,
                             mEyePosition + mForwardVector,
                             mUpVector);
        return mViewMatrix;
    }

    /// Mouse look function
    void MouseLook(int mouseX, int mouseY){
 
        if (firstMouse){
            lastX = mouseX;
            lastY = mouseY;
            firstMouse = false;
        }

        double xoffset = mouseX - lastX;
        double yoffset = lastY - mouseY; 
        lastX = mouseX;
        lastY = mouseY;

        float sensitivity = 1.1f;
        xoffset *= sensitivity;
        yoffset *= sensitivity;

        yaw   = xoffset;
        pitch = yoffset;

        vec4 dir = vec4(mForwardVector, 1.0f);
        mat4 yawRotation = MatrixMakeYRotation(ToRadians(yaw));
        vec4 rotatedVector = yawRotation * dir;
        vec3 finalVec = vec3(rotatedVector.x, rotatedVector.y, rotatedVector.z);
        mForwardVector = Normalize(finalVec);
        count++;
        UpdateViewMatrix();
    }

    void MoveForward(){
        vec3 dir = Normalize(mForwardVector) * movementSpeed;
        vec3 newPos = vec3(mEyePosition.x - dir.x, 
                        mEyePosition.y - dir.y, 
                        mEyePosition.z - dir.z);       
        SetCameraPosition(newPos); 
    }

    void MoveBackward(){
        vec3 dir = Normalize(mForwardVector) * movementSpeed;
        vec3 newPos = vec3(mEyePosition.x + dir.x, 
                        mEyePosition.y + dir.y, 
                        mEyePosition.z + dir.z);       
        SetCameraPosition(newPos);
    }

    void MoveLeft(){
        vec3 dir = Normalize(mRightVector) * movementSpeed;
        vec3 newPos = vec3(mEyePosition.x - dir.x, 
                        mEyePosition.y - dir.y, 
                        mEyePosition.z - dir.z);       
        SetCameraPosition(newPos);
    }

    void MoveRight(){
        vec3 dir = Normalize(mRightVector) * movementSpeed;
        vec3 newPos = vec3(mEyePosition.x + dir.x, 
                        mEyePosition.y + dir.y, 
                        mEyePosition.z + dir.z);       
        SetCameraPosition(newPos);
    }
}
