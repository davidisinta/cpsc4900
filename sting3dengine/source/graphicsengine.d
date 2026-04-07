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
import light;
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
        Light gLight;

        //--------------------------------------------------------------
        // Physics + entity management
        //--------------------------------------------------------------
        PhysicsWorld mPhysicsWorld;
        EntityManager mEntityManager;
        int mLastFrameTime;
        IMaterial mBasicMaterial;
		double mFrameDt;
		// uint mGroundEntity;
        // uint mCubeEntity;
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
                mScreenWidth = 768;  //640 multiples
                mScreenHeight = 576; //480 multiples

                // Setup SDL OpenGL Version
                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
                SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
                SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

                // We want to request a double buffer for smooth updating.
                SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
                SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

                // Create an application window using OpenGL that supports SDL
                mWindow = SDL_CreateWindow( "dlang - OpenGL 4+ Graphics Framework",
                                SDL_WINDOWPOS_UNDEFINED,
                                SDL_WINDOWPOS_UNDEFINED,
                                mScreenWidth,
                                mScreenHeight,
                                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN );

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
                            }
                        }
                }

                // Continuous key state for smooth movement
                const(ubyte)* keys = SDL_GetKeyboardState(null);
                if (keys[SDL_SCANCODE_W])     mCamera.MoveForward();
                if (keys[SDL_SCANCODE_S])     mCamera.MoveBackward();
                if (keys[SDL_SCANCODE_A])     mCamera.MoveLeft();
                if (keys[SDL_SCANCODE_D])     mCamera.MoveRight();

                // Mouse look
                int mouseX, mouseY;
                SDL_GetMouseState(&mouseX, &mouseY);
                mCamera.MouseLook(mouseX, mouseY);

                mGame.HandleInput();
        }

        /// A helper function to setup a scene.
        void SetupScene(){

                // Create a pipeline and associate it with a material
                Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
                mBasicMaterial = new BasicMaterial("basic");  // cache for spawning

                // Create a pipeline for our light
                Pipeline lightPipeline = new Pipeline("light","./pipelines/light/basic.vert","./pipelines/light/basic.frag");
                IMaterial lightMaterial    = new BasicMaterial("light");

                //we create another object for our light box and add it to scene tree
                GLfloat[] lightboxVBO = [
                    -0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                     0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                     0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                     0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                    -0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
                    -0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,

                    -0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                    -0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                    -0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

                    -0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
                    -0.5f,  0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
                    -0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
                    -0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
                    -0.5f, -0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
                    -0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,

                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

                    -0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
                     0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
                     0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
                     0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
                    -0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
                    -0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,

                    -0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                     0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                    -0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
                    -0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f
                ];
                ISurface lightBox = new SurfaceTriangle(lightboxVBO);
                MeshNode light = new MeshNode("light", lightBox, lightMaterial);
                mSceneTree.GetRootNode().AddChildSceneNode(light);

                // Add uniforms to the basic material
                mBasicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
                mBasicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
                mBasicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

                //Add uniforms to our light shader as well
                lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
                lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
                lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        }

        void setUpLights(){

            GLuint shaderProgramID = Pipeline.sPipeline["basic"];
            glUseProgram(shaderProgramID);

            GLint field1 = glGetUniformLocation(shaderProgramID, "uLight1.mColor");
            GLint field2 = glGetUniformLocation(shaderProgramID, "uLight1.mPosition");
            GLint field3 = glGetUniformLocation(shaderProgramID, "uLight1.mAmbientIntensity");
            GLint field4 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularIntensity");
            GLint field5 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularExponent");
            GLint field6 = glGetUniformLocation(shaderProgramID, "viewpos");

            foreach(value ; [field1,field2,field3,field4,field5]){
                if(value < 0){
                    writeln("Failed to find: ",value);
                }
            }
        
            // Postion light to move in a circle
            static float inc = 0.0f;
            float radius = 3.0f;
            inc+=0.01;
            gLight.mPosition = [radius*cos(inc),0.0f,radius*sin(inc)];

            glUniform1fv(field1,3,gLight.mColor.ptr);
            glUniform1fv(field2,3,gLight.mPosition.ptr);
            glUniform1f (field3,gLight.mAmbientIntensity);
            glUniform1f (field4,gLight.mSpecularIntensity);
            glUniform1f (field5,gLight.mSpecularExponent);
            glUniform3f(field6, mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);
        }

        void Update(){

			// Step physics
            mPhysicsWorld.updatePhysics(mFrameDt);

            // Sync physics transforms → MeshNode model matrices
            // Optionally Set debugLog=true to print positions each frame for verification
            syncPhysicsToRender(mPhysicsWorld, mEntityManager, /*debugLog=*/ false);

			// A rotation value that 'updates' every frame to give some animation in our scene
			static float yRotation = 0.0f;   yRotation += 0.01f;

			//update our light object
			MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");
			if (lightNode !is null)
			{
				GLfloat x = gLight.mPosition[0];
				GLfloat y = gLight.mPosition[1];
				GLfloat z = gLight.mPosition[2];
				lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z));
			}

            mGame.Update(mFrameDt);
        }

        void Render(){
            if(mRenderWireframe){
                    glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
            }else{
                    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
            }

            setUpLights();

            glViewport(0,0,mScreenWidth, mScreenHeight);
            glClearColor(0.0f,0.6f,0.8f,1.0f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_DEPTH_TEST);	

            mRenderer.Render(mSceneTree,mCamera);

            mGame.drawCrosshair();

            SDL_GL_SwapWindow(mWindow);	
        }

        void AdvanceFrame(){

            // Compute real delta time
            int now = SDL_GetTicks();
            int elapsed = now - mLastFrameTime;
            mLastFrameTime = now;
            mFrameDt = elapsed / 1000.0;

            Input();

            mAudio.update();

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

        /// Main application loop
        void Loop(){

                // Setup the graphics scene
                SetupScene();

               

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

                mAudio.play("./assets/sounds/drumloop.wav");

                //attach audio engine to game
                mGame.attachAudio(&mAudio);

                // Lock mouse to center of screen
                SDL_WarpMouseInWindow(mWindow,640/2,320/2);

                // Run the graphics application loop
                while(mGameIsRunning){
                        AdvanceFrame();
                }
        }
}
