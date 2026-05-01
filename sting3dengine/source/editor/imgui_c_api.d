module imgui_c_api;

extern(C)
{
    //----------------------------------------------------------------
    // Opaque types
    //----------------------------------------------------------------
    alias ImGuiContext = void;
    alias ImDrawData   = void;
    alias ImFontAtlas  = void;
    alias ImDrawList   = void;
    alias ImFont       = void;

    //----------------------------------------------------------------
    // Primitive types used by drawlist API
    //----------------------------------------------------------------
    alias ImU32        = uint;     // packed 0xAABBGGRR color
    alias ImTextureID  = void*;
    alias ImDrawIdx    = ushort;

    //----------------------------------------------------------------
    // Window flags
    //----------------------------------------------------------------
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

    //----------------------------------------------------------------
    // Vector types
    //----------------------------------------------------------------

    /// 2D vector. Added so we can talk to the drawlist API, set window sizes
    /// via ImVec2 overloads, and use igCalcTextSize's result.
    struct ImVec2
    {
        float x, y;
    }

    /// 4D vector — colors (r,g,b,a) or rects. Already in use for igTextColored.
    struct ImVec4
    {
        float x, y, z, w;
    }

    //----------------------------------------------------------------
    // Context / frame
    //----------------------------------------------------------------
    ImGuiContext* igCreateContext(ImFontAtlas* shared_font_atlas);
    void igDestroyContext(ImGuiContext* ctx);

    void igNewFrame();
    void igEndFrame();
    void igRender();
    ImDrawData* igGetDrawData();

    //----------------------------------------------------------------
    // Windows
    //----------------------------------------------------------------
    bool igBegin(const(char)* name, bool* p_open, int flags);
    void igEnd();

    /// Fill `out_pos` with the current window's top-left in screen coords.
    /// cimgui convention: functions returning ImVec2 take an out-pointer
    /// and have no suffix. Must be called inside Begin/End.
    void igGetWindowPos(ImVec2* out_pos);

    /// Fill `out_size` with the current window's size.
    void igGetWindowSize(ImVec2* out_size);

    /// Returns the drawlist attached to the current window. Use this for
    /// custom primitives (arcs, lines, filled shapes) layered on top of
    /// a window's background.
    ImDrawList* igGetWindowDrawList();

    //----------------------------------------------------------------
    // Positioning
    //----------------------------------------------------------------
    void igSetNextWindowPos(float x, float y, int cond, float pivot_x, float pivot_y);

    /// Existing 2-float version (kept as-is so old call sites still compile).
    void igSetNextWindowSize(float x, float y, int cond);

    /// cimgui's canonical ImVec2-taking overload. Same function, different
    /// symbol name at link time. We don't need this one yet but exposing it
    /// now saves you a round trip when future widgets want ImVec2 APIs.
    void igSetNextWindowSize_Vec2(ImVec2 size, int cond);

    void igSetNextWindowBgAlpha(float alpha);

    //----------------------------------------------------------------
    // Widgets (existing set — leave alone)
    //----------------------------------------------------------------
    void igText(const(char)* fmt, ...);
    void igTextWrapped(const(char)* fmt, ...);
    void igTextColored(ImVec4 col, const(char)* fmt, ...);

    bool igButton(const(char)* label, float size_x, float size_y);
    void igSeparator();
    bool igSliderFloat(const(char)* label, float* v, float v_min, float v_max,
                       const(char)* format, int flags);

    void igSameLine(float offset_from_start_x, float spacing);
    void igPushItemWidth(float item_width);
    void igPopItemWidth();
    void igProgressBar(float fraction, float size_x, float size_y,
                       const(char)* overlay);

    //----------------------------------------------------------------
    // Text input
    //----------------------------------------------------------------
    alias ImGuiInputTextCallback = int function(void* data);
    bool igInputText(const(char)* label, char* buf, size_t buf_size,
                     int flags, ImGuiInputTextCallback callback, void* user_data);

    //----------------------------------------------------------------
    // Text measurement
    //----------------------------------------------------------------

    /// Compute the size a string would occupy if rendered with igText.
    /// cimgui out-pointer convention: first arg is where the result goes.
    /// `text_end` may be null to use strlen. `wrap_width` < 0 disables wrap.
    void igCalcTextSize(ImVec2* out_size,
                        const(char)* text,
                        const(char)* text_end,
                        bool hide_text_after_double_hash,
                        float wrap_width);

    //----------------------------------------------------------------
    // Color packing
    //----------------------------------------------------------------

    /// Pack an ImVec4 (0..1 floats) into an ImU32 for drawlist calls.
    /// cimgui has multiple overloads — Vec4 is the one that takes an ImVec4.
    ImU32 igGetColorU32_Vec4(ImVec4 col);

    //----------------------------------------------------------------
    // ImDrawList primitives
    //
    // cimgui prefixes all ImDrawList methods with `ImDrawList_` and
    // passes `this` as the first arg. The text overload that takes a
    // position is suffixed `_Vec2`.
    //----------------------------------------------------------------
    void ImDrawList_AddLine(ImDrawList* self, ImVec2 p1, ImVec2 p2,
                            ImU32 col, float thickness);

    void ImDrawList_AddRect(ImDrawList* self, ImVec2 p_min, ImVec2 p_max,
                            ImU32 col, float rounding,
                            int draw_flags, float thickness);

    void ImDrawList_AddRectFilled(ImDrawList* self, ImVec2 p_min, ImVec2 p_max,
                                  ImU32 col, float rounding, int draw_flags);

    void ImDrawList_AddCircle(ImDrawList* self, ImVec2 center, float radius,
                              ImU32 col, int num_segments, float thickness);

    void ImDrawList_AddCircleFilled(ImDrawList* self, ImVec2 center,
                                    float radius, ImU32 col, int num_segments);

    /// Text at a screen position. `font` and `font_size` args are covered
    /// by the `_Vec2` overload (simple pos+col+text).
    void ImDrawList_AddText_Vec2(ImDrawList* self, ImVec2 pos, ImU32 col,
                                 const(char)* text_begin,
                                 const(char)* text_end);

    //----------------------------------------------------------------
    // ImDrawList path API — used for drawing arcs (the timer ring).
    //
    // Workflow: PathClear, PathArcTo (accumulate points), PathStroke.
    //----------------------------------------------------------------
    void ImDrawList_PathClear(ImDrawList* self);
    void ImDrawList_PathArcTo(ImDrawList* self, ImVec2 center, float radius,
                              float a_min, float a_max, int num_segments);
    void ImDrawList_PathStroke(ImDrawList* self, ImU32 col,
                               int draw_flags, float thickness);

    //----------------------------------------------------------------
    // SDL2 + OpenGL3 backends (unchanged)
    //----------------------------------------------------------------
    bool ImGui_ImplSDL2_InitForOpenGL(void* window, void* sdl_gl_context);
    void ImGui_ImplSDL2_Shutdown();
    void ImGui_ImplSDL2_NewFrame();
    bool ImGui_ImplSDL2_ProcessEvent(void* event);

    bool ImGui_ImplOpenGL3_Init(const(char)* glsl_version);
    void ImGui_ImplOpenGL3_Shutdown();
    void ImGui_ImplOpenGL3_NewFrame();
    void ImGui_ImplOpenGL3_RenderDrawData(ImDrawData* draw_data);
}