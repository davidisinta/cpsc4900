module graphicsengine;

// standard libraries
import std.stdio;
import std.math;
import std.conv;
import std.string : toStringz;
import std.datetime.stopwatch : StopWatch, AutoStart;
import core.thread : Thread;
import std.datetime : dur;
import std.datetime.systime : Clock;

// Third-party libraries
import bindbc.sdl;
import bindbc.opengl;

// Project libraries
import enginecore;
import mesh, linear, scene, materials, geometry;
import platform;
// import light;
import firstpersonshootergame;
import editor;
import audiosubsystem;
import physics;


/// The main graphics application.
class GraphicsEngine{
        bool mGameIsRunning=true;
        bool mRenderWireframe = false;
        SDL_GLContext mContext;
        SDL_Window* mWindow;
        int i = 0;
        int fps = 0;
        int MS_PER_FRAME = 16;
        int mScreenWidth;
        int mScreenHeight;

        SceneTree mSceneTree;
        Camera mCamera;
        Renderer mRenderer;

        //--------------------------------------------------------------
        // Physics + entity management
        //--------------------------------------------------------------
        PhysicsWorld mPhysicsWorld;
        EntityManager mEntityManager;
        int mLastFrameTime;
        IMaterial mBasicMaterial;
		double mFrameDt;
        GLuint mCrosshairVAO;
        GLuint mCrosshairVBO;
        bool mCrosshairReady = false;

        //--------------------------------------------------------------
        // First Person Shooter Game
        //--------------------------------------------------------------
        GameApplication mGame;

        //--------------------------------------------------------------
        // Audio
        //--------------------------------------------------------------
        AudioEngine mAudio;

        /// Setup OpenGL and any libraries
        this(int major_ogl_version, int minor_ogl_version){

            //Set screen Width and Height
            SDL_DisplayMode dm;
            if (SDL_GetCurrentDisplayMode(0, &dm) != 0) {
                throw new Exception("SDL_GetCurrentDisplayMode failed");
            }

            mScreenWidth = dm.w;
            mScreenHeight = dm.h;

            // Setup SDL OpenGL Version
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
            SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

            // We want to request a double buffer for smooth updating.
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
            SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
                    
            mWindow = SDL_CreateWindow(
                "dlang - OpenGL 4+ Graphics Framework",
                SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED,
                mScreenWidth,
                mScreenHeight,
                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_FULLSCREEN_DESKTOP
            );

            // Create the OpenGL context and associate it with our window
            mContext = SDL_GL_CreateContext(mWindow);

            // Load OpenGL Function calls
            auto retVal = LoadOpenGLLib();

            // Check OpenGL version
            GetOpenGLVersionInfo();

            // Create a renderer
            mRenderer = new Renderer(mWindow,mScreenWidth,mScreenHeight);

            // Create a camera
            mCamera = new Camera();

            // Create (or load) a Scene Tree
            mSceneTree = new SceneTree("root");

            // Initialise physics world + entity manager
            mPhysicsWorld = new PhysicsWorld("main-world");
            mEntityManager = new EntityManager();
            mLastFrameTime = SDL_GetTicks();
        }

        /// Destructor
        ~this(){

            // Shut down ImGui
            ImGui_ImplOpenGL3_Shutdown();
            ImGui_ImplSDL2_Shutdown();
            igDestroyContext(null);

            //shut down fmod
            mAudio.shutdown();

            // Shut down physics
            mPhysicsWorld.shutdown();

            // Destroy our context
            SDL_GL_DeleteContext(mContext);
            // Destroy our window
            SDL_DestroyWindow(mWindow);
        }

        void Input(){

            SDL_Event event;
            while(SDL_PollEvent(&event)){
                // First process if theres any input over imgui stuff
                ImGui_ImplSDL2_ProcessEvent(cast(void*)&event);

                if(event.type == SDL_QUIT){
                    writeln("Exit event triggered");
                    mGameIsRunning= false;
                }
                if(event.type == SDL_KEYDOWN){
                    if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
                            writeln("Pressed escape key and now exiting...");
                            mGameIsRunning= false;
                    }
                    else if(event.key.keysym.sym == SDLK_TAB){
                            mRenderWireframe = !mRenderWireframe;
                    }
                }

                if(event.type == SDL_MOUSEBUTTONDOWN){
                    if(event.button.button == SDL_BUTTON_LEFT){
                        mGame.requestShoot();
                        writeln("requesting to shoot");
                    }
                }
            }

            // Continuous key state for smooth movement
            const(ubyte)* keys = SDL_GetKeyboardState(null);
            bool moving = false;
            if (keys[SDL_SCANCODE_W]) {
                mCamera.MoveForward();
                moving = true;
            }
            if (keys[SDL_SCANCODE_S]) {
                mCamera.MoveBackward();
                moving = true;
            }
            if (keys[SDL_SCANCODE_A]) {
                mCamera.MoveLeft();
                moving = true;
            }
            if (keys[SDL_SCANCODE_D]) {
                mCamera.MoveRight();
                moving = true;
            }
            if (keys[SDL_SCANCODE_UP]) {
                mCamera.MoveUp();
                moving = true;
            }
            if (keys[SDL_SCANCODE_DOWN]) {
                mCamera.MoveDown();
                moving = true;
            }
            
            if (moving) {
                if (!mGame.mWalkingSoundPlaying) {
                    mGame.playSound(mGame.mWalkingSound, &mGame.mWalkingSoundChannel);
                    mGame.mWalkingSoundPlaying = true;
                }
            } else {
                if (mGame.mWalkingSoundPlaying) {
                    mGame.stopSound(&mGame.mWalkingSoundChannel);
                    mGame.mWalkingSoundPlaying = false;
                }
            }
            
            int mouseX, mouseY;
            SDL_GetMouseState(&mouseX, &mouseY);
            int centerX = mScreenWidth / 2;
            int centerY = mScreenHeight / 2;
            int deltaX = mouseX - centerX;
            int deltaY = mouseY - centerY;

            if (deltaX != 0 || deltaY != 0){
                mCamera.MouseLook(deltaX, deltaY);
                SDL_WarpMouseInWindow(mWindow, centerX, centerY);
            }

            mGame.Input();
        }

        void Update(){

            // Update game audio
            mAudio.update();

			// Step physics
            mPhysicsWorld.updatePhysics(mFrameDt);

            // Sync physics transforms → MeshNode model matrices
            // Optionally Set debugLog=true to print positions each frame for verification
            syncPhysicsToRender(mPhysicsWorld, mEntityManager, /*debugLog=*/ false);

			// A rotation value that 'updates' every frame to give some animation in our scene
			static float yRotation = 0.0f;   yRotation += 0.01f;

            //Update the FPS which the games gui is reading
            mGame.mGui.fps = this.fps;
            mGame.mGui.screenWidth = mScreenWidth;
            mGame.mGui.screenHeight = mScreenHeight;

            mGame.Update(mFrameDt);
        }

        void Render(){

            // Render 3D scene
            if(mRenderWireframe){
                    glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
            }else{
                    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
            }

            mGame.setUpLights();

            glViewport(0,0,mScreenWidth, mScreenHeight);
            glClearColor(0.0f,0.6f,0.8f,1.0f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_DEPTH_TEST);	


            // Draw skybox FIRST with depth writing off

            // glEnable(GL_DEPTH_TEST);
            // glDepthMask(GL_FALSE);
            // mGame.drawSkyBox();
            // glDepthMask(GL_TRUE);

            // to do: check if perhaps renderer can do all rendering
            // even from game side
            mRenderer.Render(mSceneTree,mCamera);

            //Do game rendering last
            mGame.Render();

            SDL_GL_SwapWindow(mWindow);	
        }

        void AdvanceFrame(){

            // Compute real delta time
            int now = SDL_GetTicks();
            int elapsed = now - mLastFrameTime;
            mLastFrameTime = now;
            mFrameDt = elapsed / 1000.0;

            // Start ImGui frame BEFORE input
            // beacuse we need to check if there are any events to imgui
            ImGui_ImplOpenGL3_NewFrame();
            ImGui_ImplSDL2_NewFrame();
            igNewFrame();

            Input();
            Update();
            Render();

            // Frame cap
            int frame_elapsed = SDL_GetTicks() - now;
            if(frame_elapsed < 16){
                SDL_Delay(16 - frame_elapsed);
                int curr_fps = 1000/(SDL_GetTicks() - now);
                if(this.fps!=curr_fps)
                {
                    this.fps = curr_fps;
                    string fps_title = "FPS: " ~ curr_fps.to!string;
                    SDL_SetWindowTitle(mWindow, fps_title.toStringz);
                }
            }
            else {
                int curr_fps = 1000/frame_elapsed;
                if(this.fps!=curr_fps)
                {
                    this.fps = curr_fps;
                    string fps_title = "FPS: " ~ curr_fps.to!string;
                    SDL_SetWindowTitle(mWindow, fps_title.toStringz);
                }
            }
        }


        /// helper to hide triangle cursor from screen
        void hideCursor(){
            // Hide cursor by setting a blank 1x1 transparent cursor
            auto blankData = new ubyte[4];
            blankData[0] = 0; blankData[1] = 0; blankData[2] = 0; blankData[3] = 0;
            auto blankSurface = SDL_CreateRGBSurfaceFrom(
                blankData.ptr, 1, 1, 32, 4,
                0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
            if (blankSurface !is null)
            {
                auto blankCursor = SDL_CreateColorCursor(blankSurface, 0, 0);
                if (blankCursor !is null)
                    SDL_SetCursor(blankCursor);
                SDL_FreeSurface(blankSurface);
            }

        }

        /// Main application loop
        void Loop(){

            // Setup the graphics scene
            // SetupScene();

            //imgui set up
            igCreateContext(null);
            ImGui_ImplSDL2_InitForOpenGL(cast(void*)mWindow, cast(void*)mContext);
            ImGui_ImplOpenGL3_Init("#version 410");
            writeln("[imgui] initialized");

            // Dummy frame to satisfy ImGui's internal state
            ImGui_ImplOpenGL3_NewFrame();
            ImGui_ImplSDL2_NewFrame();
            igNewFrame();
            igEndFrame();

            mGame = new GameApplication(
                "topshotaa",
                mPhysicsWorld,
                mEntityManager,
                mCamera,
                mSceneTree,
                mBasicMaterial
            );

            mGame.Setup();

            // initialize audio after game because game is setting up some 
            // multitexture pipelines
            mAudio.init();

            //attach audio engine to game
            mGame.attachAudio(&mAudio);

            // Lock mouse to center of screen
            SDL_WarpMouseInWindow(mWindow,640/2,320/2);

            hideCursor();

            // Run the graphics application loop
            while(mGameIsRunning){
                    AdvanceFrame();
            }
        }
}
