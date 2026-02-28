// module graphicsengine;

// // standard libraries
// import std.stdio;
// import std.math;
// import std.conv;
// import std.string : toStringz;
// import std.datetime.stopwatch : StopWatch, AutoStart;
// import core.thread : Thread;

// import std.datetime : dur;

// // Third-party libraries
// import bindbc.sdl;
// import bindbc.opengl;

// // Project libraries
// import enginecore;
// import mesh, linear, scene, materials, geometry;
// import platform;
// import light;
// import firstpersonshootergame;
// import editor;
// import audiosubsystem;
// import physics;


// /// The main graphics application.
// struct GraphicsEngine{
// 		bool mGameIsRunning=true;
// 		bool mRenderWireframe = false;
// 		SDL_GLContext mContext;
// 		SDL_Window* mWindow;
// 		int i = 0;
// 		int fps = 0;
// 		int MS_PER_FRAME = 16;
// 		GameApplication mGame;
// 		int mScreenWidth;
// 		int mScreenHeight;

// 		SceneTree mSceneTree;
// 		Camera mCamera;
// 		Renderer mRenderer;
// 		Light gLight;

// 		/// Setup OpenGL and any libraries
// 		this(int major_ogl_version, int minor_ogl_version){

// 				//Set screen Width and Height
// 				mScreenWidth = 640;
// 				mScreenHeight = 480;

// 				// Setup SDL OpenGL Version
// 				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
// 				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
// 				SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

// 				// We want to request a double buffer for smooth updating.
// 				SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
// 				SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

// 				// Create an application window using OpenGL that supports SDL
// 				mWindow = SDL_CreateWindow( "dlang - OpenGL 4+ Graphics Framework",
// 								SDL_WINDOWPOS_UNDEFINED,
// 								SDL_WINDOWPOS_UNDEFINED,
// 								mScreenWidth,
// 								mScreenHeight,
// 								SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN );

// 				// Create the OpenGL context and associate it with our window
// 				mContext = SDL_GL_CreateContext(mWindow);

// 				// Load OpenGL Function calls
// 				auto retVal = LoadOpenGLLib();

// 				// Check OpenGL version
// 				GetOpenGLVersionInfo();

// 				// Create a renderer
// 				mRenderer = new Renderer(mWindow,mScreenWidth,mScreenHeight);

// 				// Create a camera
// 				mCamera = new Camera();

// 				// Create (or load) a Scene Tree
// 				mSceneTree = new SceneTree("root");

// 				// Add the game to the engine
// 				// I heap allocate the game struct for performance reasons
// 				mGame = new GameApplication("topshotaa");
// 		}

// 		/// Destructor
// 		~this(){
// 				// Destroy our context
// 				SDL_GL_DeleteContext(mContext);
// 				// Destroy our window
// 				SDL_DestroyWindow(mWindow);
// 		}

// 		/// Handle input
// 		void Input(){
// 				// Store an SDL Event
// 				SDL_Event event;
// 				while(SDL_PollEvent(&event)){
// 						if(event.type == SDL_QUIT){
// 								writeln("Exit event triggered (probably clicked 'x' at top of the window)");
// 								mGameIsRunning= false;
// 						}
// 						if(event.type == SDL_KEYDOWN){
// 								if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
// 										writeln("Pressed escape key and now exiting...");
// 										mGameIsRunning= false;
// 								}else if(event.key.keysym.sym == SDLK_TAB){
// 										mRenderWireframe = !mRenderWireframe;
// 								}
// 								else if(event.key.keysym.sym == SDLK_DOWN){
// 										mCamera.MoveBackward();
// 								}
// 								else if(event.key.keysym.sym == SDLK_UP){
// 										mCamera.MoveForward();
// 								}
// 								else if(event.key.keysym.sym == SDLK_LEFT){
// 										mCamera.MoveLeft();
// 								}
// 								else if(event.key.keysym.sym == SDLK_RIGHT){
// 										mCamera.MoveRight();
// 								}
// 								else if(event.key.keysym.sym == SDLK_a){
// 										mCamera.MoveUp();
// 								}
// 								else if(event.key.keysym.sym == SDLK_z){
// 										mCamera.MoveDown();
// 								}
// 								writeln("Camera Position: ",mCamera.mEyePosition);
// 						}
// 				}

//                 // Retrieve the mouse position
//                 int mouseX,mouseY;
//                 SDL_GetMouseState(&mouseX,&mouseY);
//                 mCamera.MouseLook(mouseX,mouseY);
// 		}

// 		/// A helper function to setup a scene.
// 		/// NOTE: In the future this can use a configuration file to otherwise make our graphics applications
// 		///       data-driven.
// 		void SetupScene(){

// 				// Create a pipeline and associate it with a material
// 				// that can be attached to meshes.
// 				Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
// 				IMaterial basicMaterial    = new BasicMaterial("basic");

// 				// Create a pipeline for our light, this way the light
// 				// itself remains unaffected by itself but lights other objects
// 				Pipeline lightPipeline = new Pipeline("light","./pipelines/light/basic.vert","./pipelines/light/basic.frag");
// 				IMaterial lightMaterial    = new BasicMaterial("light");

// 				// Create an object and add it to our scene tree
// 				ISurface obj = new SurfaceOBJ("./assets/meshes/bunny_centered.obj"); 
// 				MeshNode  m        = new MeshNode("bunny",obj,basicMaterial);
// 				mSceneTree.GetRootNode().AddChildSceneNode(m);

// 				//we create another object for our light box and add it to scene tree
// 				//create vbo for this obj
// 				GLfloat[] lightboxVBO = [
// 					-0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
// 					0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
// 					0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
// 					0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
// 					-0.5f,  0.5f, -0.5f,  1.0f,  1.0f, 1.0f,
// 					-0.5f, -0.5f, -0.5f,  1.0f,  1.0f, 1.0f,

// 					-0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					-0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					-0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

// 					-0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
// 					-0.5f,  0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
// 					-0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
// 					-0.5f, -0.5f, -0.5f, 1.0f,  1.0f,  1.0f,
// 					-0.5f, -0.5f,  0.5f, 1.0f,  1.0f,  1.0f,
// 					-0.5f,  0.5f,  0.5f, 1.0f,  1.0f,  1.0f,

// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f, -0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f, -0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,

// 					-0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
// 					0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,
// 					0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
// 					0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
// 					-0.5f, -0.5f,  0.5f,  1.0f, 1.0f,  1.0f,
// 					-0.5f, -0.5f, -0.5f,  1.0f, 1.0f,  1.0f,

// 					-0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					-0.5f,  0.5f,  0.5f,  1.0f,  1.0f,  1.0f,
// 					-0.5f,  0.5f, -0.5f,  1.0f,  1.0f,  1.0f
// 				];
// 				ISurface lightBox = new SurfaceTriangle(lightboxVBO);

// 				//slight problem with light shader
// 				MeshNode light = new MeshNode("light", lightBox, lightMaterial);
// 				mSceneTree.GetRootNode().AddChildSceneNode(light);

// 				// Add three uniforms to the basic material.
// 				// The 4th parameter is set to the pointer where the value will be updated each frame.
// 				// Becauses the model matrix will be different among models, then we will just leave
// 				// this null for now.
// 				basicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
// 				basicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
// 				basicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

// 				//Add uniforms to our light shader as well
// 				lightMaterial.AddUniform(new Uniform("uModel", "mat4", null));
// 				lightMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
// 				lightMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
// 		}

// 		void setUpLights(){

// 			GLuint shaderProgramID = Pipeline.sPipeline["basic"];
// 			glUseProgram(shaderProgramID);

// 			GLint field1 = glGetUniformLocation(shaderProgramID, "uLight1.mColor");
// 			GLint field2 = glGetUniformLocation(shaderProgramID, "uLight1.mPosition");
// 			GLint field3 = glGetUniformLocation(shaderProgramID, "uLight1.mAmbientIntensity");
// 			GLint field4 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularIntensity");
// 			GLint field5 = glGetUniformLocation(shaderProgramID, "uLight1.mSpecularExponent");
// 			GLint field6 = glGetUniformLocation(shaderProgramID, "viewpos");

// 			foreach(value ; [field1,field2,field3,field4,field5]){
// 				if(value < 0){
// 					writeln("Failed to find: ",value);
// 				}else{
// 					// writeln("Light Uniform Location(s): ",value);
// 				}
// 			}
		
// 			// Postion light to move in a circle
// 			static float inc = 0.0f;
// 			float radius = 3.0f;
// 			inc+=0.01;
// 			gLight.mPosition = [radius*cos(inc),0.0f,radius*sin(inc)];

// 			glUniform1fv(field1,3,gLight.mColor.ptr);
// 			glUniform1fv(field2,3,gLight.mPosition.ptr);
// 			glUniform1f (field3,gLight.mAmbientIntensity);
// 			glUniform1f (field4,gLight.mSpecularIntensity);
// 			glUniform1f (field5,gLight.mSpecularExponent);
// 			glUniform3f(field6, mCamera.mEyePosition.x, mCamera.mEyePosition.y, mCamera.mEyePosition.z);

// 		}

// 		/// Update gamestate
// 		void Update(){
// 				// A rotation value that 'updates' every frame to give some animation in our scene
// 				static float yRotation = 0.0f;   yRotation += 0.01f;

// 				// Update our bunny
// 				MeshNode m = cast(MeshNode)mSceneTree.FindNode("bunny");
// 				m.mModelMatrix = MatrixMakeTranslation(vec3(0.0f,0.0f,-1.0f));
// 				m.mModelMatrix = m.mModelMatrix * MatrixMakeYRotation(yRotation);

// 				//update our light object
// 				MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");

// 				//ensure the light box follows point light
// 				GLfloat x = gLight.mPosition[0];
// 				GLfloat y = gLight.mPosition[1];
// 				GLfloat z = gLight.mPosition[2];
// 				lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z));
// 		}

// 		/// Render our scene by traversing the scene tree from a specific viewpoint
// 		void Render(){


// 			//to do: implement render function, to call imgui
// 			// so that we render both the editor and the 3d stuff
// 			// because of separation of concerns, renderer, should be 
// 			// part of the engine, and imgui should be part of editor,
// 			// so we can easily swap out our editor and engine does not depend
// 			// on the editor tightly.


// 			if(mRenderWireframe){
// 					glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
// 			}else{
// 					glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
// 			}

// 			//set up lights for the scene
// 			setUpLights();

// 			/// Sets state at the start of a frame
// 			glViewport(0,0,mScreenWidth, mScreenHeight);
// 			glClearColor(0.0f,0.6f,0.8f,1.0f);
// 			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
// 			glEnable(GL_DEPTH_TEST);	

// 			mRenderer.Render(mSceneTree,mCamera);

// 			// perform any cleanup and ultimately the double or triple buffering to display the final framebuffer.
// 			SDL_GL_SwapWindow(mWindow);	
// 		}


// 		//Run Boilerplate physics connecting with bullet
// 		void runPhysicsDevSmokeTests(){

// 			runPhysicsSimSmokeTestURDF(5.0, 60.0,"plane.urdf", "cube.urdf");
// 		}

// 		/// Process 1 frame
// 		void AdvanceFrame(){

// 			// get original state in time
// 			int startTime = SDL_GetTicks();	

// 			Input();
// 			Update();
// 			Render();

// 			int elapsed_time = SDL_GetTicks() - startTime;

// 			//to do: check if this is the best way to implement frame capping
// 			//apply frame capping to 60 fps, if the game is running too fast:
// 			if(elapsed_time < 16){
// 				//if our program was too fast, delay it
// 				SDL_Delay(16 - elapsed_time);
// 				int curr_fps = 1000/(SDL_GetTicks() - startTime);

// 				//update window with fps
// 				if(this.fps!=curr_fps)
// 				{
// 					this.fps = curr_fps;
// 					// writeln("fps: ", curr_fps);
// 					string fps_title = "FPS: " ~ curr_fps.to!string;
// 					SDL_SetWindowTitle(mWindow, fps_title.toStringz);
// 				}
// 			} //end if
			
// 			else { //calculate the fps, and update the window title with current fps
// 				int curr_fps = 1000/elapsed_time;

// 				//update window with fps
// 				if(this.fps!=curr_fps)
// 				{
// 					this.fps = curr_fps;
// 					// writeln("fps: ", curr_fps);
// 					string fps_title = "FPS: " ~ curr_fps.to!string;
// 					SDL_SetWindowTitle(mWindow, fps_title.toStringz);
// 				}
// 			}
// 		}

// 		/// Main application loop
// 		void Loop(){
// 				// Setup the graphics scene
// 				SetupScene();


// 				//run physics tests here
// 				runPhysicsDevSmokeTests();

// 				// Lock mouse to center of screen
// 				// This will help us get a continuous rotation.
// 				// NOTE: On occasion folks on virtual machine or WSL may not have this work,
// 				//       so you'll have to compute the 'diff' and reposition the mouse yourself.
// 				SDL_WarpMouseInWindow(mWindow,640/2,320/2);

// 				// Run the graphics application loop
// 				while(mGameIsRunning){
// 						AdvanceFrame();
// 				}
// 		}
// }



module graphicsengine;

// standard libraries
import std.stdio;
import std.math;
import std.conv;
import std.string : toStringz;
import std.datetime.stopwatch : StopWatch, AutoStart;
import core.thread : Thread;
import std.datetime : dur;

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

// NEW imports for transform sync
import entitymanager;
import transform;
import transformsync;


/// The main graphics application.
struct GraphicsEngine{
        bool mGameIsRunning=true;
        bool mRenderWireframe = false;
        SDL_GLContext mContext;
        SDL_Window* mWindow;
        int i = 0;
        int fps = 0;
        int MS_PER_FRAME = 16;
        GameApplication mGame;
        int mScreenWidth;
        int mScreenHeight;

        SceneTree mSceneTree;
        Camera mCamera;
        Renderer mRenderer;
        Light gLight;

        //--------------------------------------------------------------
        // NEW: Physics + entity management (replaces old mPhysicsClient)
        //--------------------------------------------------------------
        PhysicsWorld mPhysicsWorld;
        EntityManager mEntityManager;
        int mLastFrameTime;            // for computing frameDt
        IMaterial mBasicMaterial;       // cached ref for spawning objects

        /// Setup OpenGL and any libraries
        this(int major_ogl_version, int minor_ogl_version){

                //Set screen Width and Height
                mScreenWidth = 640;
                mScreenHeight = 480;

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

                // Add the game to the engine
                mGame = new GameApplication("topshotaa");

                //------------------------------------------------------
                // NEW: Initialise physics world + entity manager
                //------------------------------------------------------
                mPhysicsWorld = PhysicsWorld("main-world");
                mEntityManager = new EntityManager();
                mLastFrameTime = SDL_GetTicks();
        }

        /// Destructor
        ~this(){
                // Shut down physics
                mPhysicsWorld.shutdown();

                // Destroy our context
                SDL_GL_DeleteContext(mContext);
                // Destroy our window
                SDL_DestroyWindow(mWindow);
        }

        /// Handle input
        void Input(){
                // Store an SDL Event
                SDL_Event event;
                while(SDL_PollEvent(&event)){
                        if(event.type == SDL_QUIT){
                                writeln("Exit event triggered (probably clicked 'x' at top of the window)");
                                mGameIsRunning= false;
                        }
                        if(event.type == SDL_KEYDOWN){
                                if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
                                        writeln("Pressed escape key and now exiting...");
                                        mGameIsRunning= false;
                                }else if(event.key.keysym.sym == SDLK_TAB){
                                        mRenderWireframe = !mRenderWireframe;
                                }
                                else if(event.key.keysym.sym == SDLK_DOWN){
                                        mCamera.MoveBackward();
                                }
                                else if(event.key.keysym.sym == SDLK_UP){
                                        mCamera.MoveForward();
                                }
                                else if(event.key.keysym.sym == SDLK_LEFT){
                                        mCamera.MoveLeft();
                                }
                                else if(event.key.keysym.sym == SDLK_RIGHT){
                                        mCamera.MoveRight();
                                }
                                else if(event.key.keysym.sym == SDLK_a){
                                        mCamera.MoveUp();
                                }
                                else if(event.key.keysym.sym == SDLK_z){
                                        mCamera.MoveDown();
                                }
                                writeln("Camera Position: ",mCamera.mEyePosition);
                        }
                }

                // Retrieve the mouse position
                int mouseX,mouseY;
                SDL_GetMouseState(&mouseX,&mouseY);
                mCamera.MouseLook(mouseX,mouseY);
        }

        /// A helper function to setup a scene.
        void SetupScene(){

                // Create a pipeline and associate it with a material
                Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
                mBasicMaterial = new BasicMaterial("basic");  // cache for spawning

                // Create a pipeline for our light
                Pipeline lightPipeline = new Pipeline("light","./pipelines/light/basic.vert","./pipelines/light/basic.frag");
                IMaterial lightMaterial    = new BasicMaterial("light");

                // Create an object and add it to our scene tree
                ISurface obj = new SurfaceOBJ("./assets/meshes/bunny_centered.obj"); 
                MeshNode  m        = new MeshNode("bunny",obj,mBasicMaterial);
                mSceneTree.GetRootNode().AddChildSceneNode(m);

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

        //--------------------------------------------------------------
        // NEW: Spawn a physics-driven object with both visual + physics
        //--------------------------------------------------------------
        /// Creates an entity with:
        ///   - a Bullet physics body (from URDF)
        ///   - a rendered mesh (from .obj)
        ///   - a TransformComponent synced each frame
        ///
        /// Returns the entity ID.
        uint spawnPhysicsObject(
            string urdfPath,
            string objPath,
            vec3 pos,
            Quat orient = Quat.init)  // default = identity rotation
        {
            // Allocate entity
            uint eid = mEntityManager.create();

            // Physics side: load URDF into Bullet
            mPhysicsWorld.addURDF(eid, urdfPath,
                pos.x, pos.y, pos.z,
                orient.x, orient.y, orient.z, orient.w);
            mEntityManager.markPhysics(eid);

            // Render side: load .obj mesh, attach to scene tree
            ISurface surf = new SurfaceOBJ(objPath);
            MeshNode node = new MeshNode("entity_" ~ eid.to!string, surf, mBasicMaterial);
            mSceneTree.GetRootNode().AddChildSceneNode(node);

            // Register in EntityManager
            TransformComponent tc;
            tc.position = pos;
            tc.rotation = orient;
            mEntityManager.addTransform(eid, tc);
            mEntityManager.addRenderable(eid, node);

            // Set initial model matrix
            node.mModelMatrix = tc.toModelMatrix();

            writeln("[spawn] entity=", eid, " urdf=", urdfPath, " obj=", objPath,
                    " pos=", pos);
            return eid;
        }

        //--------------------------------------------------------------
        // NEW: Setup physics scene (replaces runPhysicsDevSmokeTests)
        //--------------------------------------------------------------
        // void SetupPhysicsScene()
        // {

		// 	//slow down gravity for now
		// 	mPhysicsWorld.setGravity(0.0, -1.0, 0.0);





        //     // Spawn a ground plane (static — won't move, but good practice)
        //     // The plane has no .obj visual for now; you can add one later.
        //     // For now we just load it into Bullet for collision.
        //     uint planeId = mEntityManager.create();
        //     mPhysicsWorld.addURDF(planeId, "plane.urdf", 0, 0, 0);
        //     mEntityManager.markPhysics(planeId);
        //     TransformComponent planeTc;
        //     mEntityManager.addTransform(planeId, planeTc);






        //     // Spawn a cube that falls under gravity
        //     // This is your end-to-end test: .obj visual + .urdf physics
        //     spawnPhysicsObject(
        //         "cube.urdf",
        //         "./assets/meshes/bunny_centered.obj",  // swap for cube.obj when ready
        //         vec3(0.0f, 40.0f, 3.0f)                 // start 3 units up
        //     );
        // }


		void SetupPhysicsScene()
{
    mPhysicsWorld.setGravity(0.0, -5.0, 0.0);

    // Ground plane (top surface at Y=0)
    uint planeId = mEntityManager.create();
    mPhysicsWorld.addURDF(planeId, "plane.urdf",
        0, 0, 0,
        0, 0, 0, 1);
    mEntityManager.markPhysics(planeId);
    TransformComponent planeTc;
    mEntityManager.addTransform(planeId, planeTc);

    // Cube falls on Y
    spawnPhysicsObject(
        "cube.urdf",
        "./assets/meshes/bunny_centered.obj",
        vec3(0.0f, 10.0f, 0.0f)
    );
}

        /// Update gamestate (non-physics game logic)
        void Update(){
                // A rotation value that 'updates' every frame to give some animation in our scene
                static float yRotation = 0.0f;   yRotation += 0.01f;

                // Update our bunny (only if it exists and isn't physics-driven)
                MeshNode m = cast(MeshNode)mSceneTree.FindNode("bunny");
                if (m !is null)
                {
                    m.mModelMatrix = MatrixMakeTranslation(vec3(0.0f,0.0f,-1.0f));
                    m.mModelMatrix = m.mModelMatrix * MatrixMakeYRotation(yRotation);
                }

                //update our light object
                MeshNode lightNode = cast(MeshNode)mSceneTree.FindNode("light");
                if (lightNode !is null)
                {
                    GLfloat x = gLight.mPosition[0];
                    GLfloat y = gLight.mPosition[1];
                    GLfloat z = gLight.mPosition[2];
                    lightNode.mModelMatrix = MatrixMakeTranslation(vec3(x, y, z));
                }
        }

        /// Render our scene
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

            SDL_GL_SwapWindow(mWindow);	
        }


        /// Process 1 frame  (REFACTORED)
        ///
        /// New frame order:
        ///   1. Compute real frameDt
        ///   2. Input
        ///   3. Physics step (fixed timestep accumulator)
        ///   4. Sync physics → transforms → MeshNode model matrices
        ///   5. Update (non-physics game logic, camera, lights)
        ///   6. Render
        void AdvanceFrame(){

            // 1. Compute real delta time
            int now = SDL_GetTicks();
            int elapsed = now - mLastFrameTime;
            mLastFrameTime = now;
            double frameDt = elapsed / 1000.0;  // ms → seconds

            // 2. Input
            Input();

            // 3. Step physics
            mPhysicsWorld.updatePhysics(frameDt);

            // 4. Sync physics transforms → MeshNode model matrices
            //    Set debugLog=true to print positions each frame for verification
            syncPhysicsToRender(mPhysicsWorld, mEntityManager, /*debugLog=*/ true);

            // 5. Non-physics game logic
            Update();

            // 6. Render
            Render();

            // Frame cap (same as before)
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

                // Setup physics scene (spawn ground + test objects)
                SetupPhysicsScene();

                // Lock mouse to center of screen
                SDL_WarpMouseInWindow(mWindow,640/2,320/2);

                // Run the graphics application loop
                while(mGameIsRunning){
                        AdvanceFrame();
                }
        }
}