/// Renderer module
module renderer;

// third party libraries
import bindbc.sdl;
import bindbc.opengl;

//project libraries
import camera,scene;

/// Purpose of this class is to make it easy to render part of, or the entirety of a scene
/// from a specific camera viewpoint.
/// The start and end of a frame is handled by the engine, this just renders object on the scene.
class Renderer{

    SDL_Window* mWindow;
    int mScreenWidth;
    int mScreenHeight;

    /// Constructor
    this(SDL_Window* window, int width, int height){
        mWindow = window;
        mScreenWidth = width;
        mScreenHeight = height;
    }

    /// Encapsulation of the rendering process of a scene tree with a camera
    void Render(SceneTree s, Camera c){

        // Set the camera prior to our traversal
        s.SetCamera(c);
        // Start traversing the scene tree
        s.StartTraversal();
    }
}
