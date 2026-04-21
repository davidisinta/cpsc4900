module imgui_c_api;

extern(C)
{
    // Opaque types
    alias ImGuiContext = void;
    alias ImDrawData = void;
    alias ImFontAtlas = void;

    // Window flags
    enum : int
    {
        ImGuiWindowFlags_None                  = 0,
        ImGuiWindowFlags_NoTitleBar            = 1 << 0,
        ImGuiWindowFlags_NoResize              = 1 << 1,
        ImGuiWindowFlags_NoMove                = 1 << 2,
        ImGuiWindowFlags_NoScrollbar           = 1 << 3,
        ImGuiWindowFlags_NoBackground          = 1 << 7,
        ImGuiWindowFlags_NoDecoration          = (1<<0) | (1<<1) | (1<<3) | (1<<5),
        ImGuiWindowFlags_AlwaysAutoResize      = 1 << 6,
        ImGuiWindowFlags_NoInputs              = (1<<9) | (1<<10),
    }

    // Context
    ImGuiContext* igCreateContext(ImFontAtlas* shared_font_atlas);
    void igDestroyContext(ImGuiContext* ctx);

    // Frame
    void igNewFrame();
    void igRender();
    ImDrawData* igGetDrawData();

    // Windows
    bool igBegin(const(char)* name, bool* p_open, int flags);
    void igEnd();

    // Widgets
    void igText(const(char)* fmt, ...);
    bool igButton(const(char)* label, float size_x, float size_y);
    void igSeparator();
    bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max, const(char)* format, int flags);

    // Positioning
    void igSetNextWindowPos(float x, float y, int cond, float pivot_x, float pivot_y);
    void igSetNextWindowSize(float x, float y, int cond);
    void igSetNextWindowBgAlpha(float alpha);

    // SDL2 backend
    bool ImGui_ImplSDL2_InitForOpenGL(void* window, void* sdl_gl_context);
    void ImGui_ImplSDL2_Shutdown();
    void ImGui_ImplSDL2_NewFrame();
    bool ImGui_ImplSDL2_ProcessEvent(void* event);

    // OpenGL3 backend
    bool ImGui_ImplOpenGL3_Init(const(char)* glsl_version);
    void ImGui_ImplOpenGL3_Shutdown();
    void ImGui_ImplOpenGL3_NewFrame();
    void ImGui_ImplOpenGL3_RenderDrawData(ImDrawData* draw_data);


    void igEndFrame();


    void igProgressBar(float fraction, float size_x, float size_y, const(char)* overlay);
}