module gamegui;

import std.stdio;
import std.string : toStringz, fromStringz;
import std.conv : to;
import std.math : cos, sin, PI, fmax, fmin;
import std.algorithm : min, max;

import editor;
import collisioneditor;
import challenge_state;
import leaderboard;

/// A short message that floats up briefly on the HUD (e.g. "+300 ENEMY x2").
struct FloatingMessage
{
    string text;
    double ttl;          // seconds remaining
    double maxTtl;       // original ttl (for fade)
    float  r, g, b;      // color
    bool   isBig;        // enemy/jackpot messages render larger
}

class GameGUI
{
    string mGuiName;

    // Live game state. GameApplication updates these each frame.
    ChallengePhase phase = ChallengePhase.Intro;
    int score = 0;
    int shotsFired = 0;
    int shotsHit = 0;
    float accuracy = 0.0f;
    int currentAmmo = 30;
    int maxAmmo = 30;
    string weaponName = "PISTOL";
    string playerName = "Player";
    int roundTimeSeconds = cast(int)kChallengeDuration;
    double roundTimeRemaining = kChallengeDuration;
    double roundTimeTotal = kChallengeDuration;
    int comboCount = 0;
    float comboMultiplier = 1.0f;
    int enemiesKilled = 0;
    int cubesHit = 0;
    int enemiesAlive = 0;
    int fps = 0;
    double lastFiveSecFps = 60;
    string movementState = "STOPPED";
    float currentSpread = 0.0f;

    LeaderboardEntry[] leaderboard;
    int finalScore = 0;

    CollisionEditor mCollisionEditor;

    // Screen dimensions — set from engine each frame.
    int screenWidth = 960;
    int screenHeight = 720;

    // HUD animation state
    private double mComboPulseRemaining = 0.0;
    private int mLastDisplayedCombo = 0;
    private FloatingMessage[] mFloatingMessages;

    private char[32] mPlayerNameBuffer;
    private bool mStartPressed = false;
    private bool mRestartPressed = false;

    this(string name)
    {
        mGuiName = name;
        setDefaultName("Player");
    }

    //----------------------------------------------------------------
    // Messages / effects the game can push into the HUD
    //----------------------------------------------------------------

    /// Push a floating "+N" style message to the HUD. It floats up, fades, vanishes.
    void pushScorePopup(int points, int combo, bool isEnemy)
    {
        import std.format : format;

        string prefix = isEnemy ? "ENEMY " : "";
        string comboSuffix = combo > 1 ? format(" x%d", combo) : "";
        string text = format("%s+%d%s", prefix, points, comboSuffix);

        FloatingMessage m;
        m.text = text;
        m.ttl = 1.2;
        m.maxTtl = 1.2;
        m.isBig = isEnemy;
        if (isEnemy)
        {
            m.r = 1.00f;
            m.g = 0.55f;
            m.b = 0.15f;
        }
        else
        {
            m.r = 0.45f;
            m.g = 0.85f;
            m.b = 0.38f;
        }

        mFloatingMessages ~= m;
        // cap the list to keep it tidy
        if (mFloatingMessages.length > 6)
            mFloatingMessages = mFloatingMessages[$ - 6 .. $];
    }

    /// Call when a combo increases so we can animate it.
    void onComboAdvanced(int newCombo)
    {
        if (newCombo > mLastDisplayedCombo)
            mComboPulseRemaining = 0.5;
        mLastDisplayedCombo = newCombo;
    }

    /// Advance HUD animation timers. Call once per frame from Update().
    void tick(double dt)
    {
        if (mComboPulseRemaining > 0)
            mComboPulseRemaining -= dt;

        for (int i = cast(int)mFloatingMessages.length - 1; i >= 0; --i)
        {
            mFloatingMessages[i].ttl -= dt;
            if (mFloatingMessages[i].ttl <= 0)
            {
                if (cast(size_t)i != mFloatingMessages.length - 1)
                    mFloatingMessages[i] = mFloatingMessages[$ - 1];
                mFloatingMessages.length = mFloatingMessages.length - 1;
            }
        }
    }

    //----------------------------------------------------------------
    // Name input + button plumbing
    //----------------------------------------------------------------

    void setDefaultName(string value)
    {
        mPlayerNameBuffer[] = 0;
        auto n = value.length < mPlayerNameBuffer.length - 1
            ? value.length
            : mPlayerNameBuffer.length - 1;

        foreach (i; 0 .. n)
            mPlayerNameBuffer[i] = value[i];
    }

    string enteredName()
    {
        return fromStringz(mPlayerNameBuffer.ptr).idup;
    }

    bool consumeStartPressed()
    {
        bool result = mStartPressed;
        mStartPressed = false;
        return result;
    }

    bool consumeRestartPressed()
    {
        bool result = mRestartPressed;
        mRestartPressed = false;
        return result;
    }

    //----------------------------------------------------------------
    // Render entry point
    //----------------------------------------------------------------

    void Render()
    {
        if (phase == ChallengePhase.Intro)
        {
            renderIntro();
            renderLeaderboardPanel(false);
        }
        else if (phase == ChallengePhase.Live)
        {
            renderHud();
            if (mCollisionEditor !is null)
                mCollisionEditor.renderGUI(screenWidth, screenHeight);
        }
        else
        {
            renderResults();
            renderLeaderboardPanel(true);
        }

        igRender();
        ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData());
    }

    //----------------------------------------------------------------
    // Intro / welcome screen
    //----------------------------------------------------------------

    private void renderIntro()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight / 2.0f, 4, 0.5f, 0.5f);
        igSetNextWindowBgAlpha(0.94f);

        igBegin("##challenge_intro", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize);

        ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
        ImVec4 green  = ImVec4(0.48f, 0.88f, 0.40f, 1.0f);
        ImVec4 cyan   = ImVec4(0.38f, 0.82f, 1.00f, 1.0f);
        ImVec4 muted  = ImVec4(0.62f, 0.68f, 0.74f, 1.0f);

        igTextColored(orange, "== TOPSHOOTA ==");
        igTextColored(muted,  "45-second precision challenge");
        igSeparator();

        igText("PLAYER NAME");
        igInputText("##player_name", mPlayerNameBuffer.ptr, mPlayerNameBuffer.length, 0, null, null);

        igSeparator();
        igTextColored(green, "CUBES");
        igText("  Fall from the sky. Shoot them for points.");
        igText("  Spawn rate and fall speed ramp up over the round.");

        igSeparator();
        igTextColored(orange, "JACKPOT ENEMIES (3x)");
        igText("  Up to %d appear at random across the map.", kMaxAliveEnemies);
        igText("  Each enemy is worth %d points versus %d for a cube.",
            kPointsPerEnemy, kPointsPerHit);

        igSeparator();
        igTextColored(cyan, "COMBO MULTIPLIER");
        igText("  Chain hits within %.1fs to build your combo.", kComboWindow);
        igText("  Each chained hit multiplies score, up to %.1fx.",
            kComboMaxMultiplier);
        igText("  Miss, or wait too long, and the combo resets.");

        igSeparator();
        renderControlsBlock();

        igSeparator();
        if (igButton("START CHALLENGE", 240, 40))
            mStartPressed = true;

        igEnd();
    }

    //----------------------------------------------------------------
    // Results screen
    //----------------------------------------------------------------

    private void renderResults()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight / 2.0f, 4, 0.5f, 0.5f);
        igSetNextWindowBgAlpha(0.94f);

        igBegin("##challenge_results", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize);

        ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
        ImVec4 green  = ImVec4(0.48f, 0.88f, 0.40f, 1.0f);

        igTextColored(orange, "== CHALLENGE COMPLETE ==");
        igSeparator();
        igText("Player:        %s", playerName.toStringz);
        igTextColored(green, "Final score:   %d", finalScore);
        igText("Shots fired:   %d", shotsFired);
        igText("Hits:          %d   (cubes %d, enemies %d)",
            shotsHit, cubesHit, enemiesKilled);
        igText("Accuracy:      %.1f%%", accuracy);

        igSeparator();
        if (igButton("PLAY AGAIN", 200, 36))
            mRestartPressed = true;

        igEnd();
    }

    //----------------------------------------------------------------
    // Leaderboard — nicely formatted with rank / score / acc columns
    //----------------------------------------------------------------

//     private void renderLeaderboardPanel(bool wide)
// {
//     igSetNextWindowPos(cast(float)screenWidth - 20, 20, 4, 1.0f, 0.0f);
//     igSetNextWindowBgAlpha(0.90f);

//     igBegin("##leaderboard", null,
//         ImGuiWindowFlags_NoTitleBar |
//         ImGuiWindowFlags_NoResize |
//         ImGuiWindowFlags_NoMove |
//         ImGuiWindowFlags_NoScrollbar |
//         ImGuiWindowFlags_AlwaysAutoResize);

//     ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
//     ImVec4 muted  = ImVec4(0.65f, 0.70f, 0.76f, 1.0f);
//     ImVec4 gold   = ImVec4(1.00f, 0.84f, 0.20f, 1.0f);
//     ImVec4 silver = ImVec4(0.80f, 0.85f, 0.90f, 1.0f);
//     ImVec4 bronze = ImVec4(0.85f, 0.55f, 0.25f, 1.0f);

//     igTextColored(orange, "TOP 10 LEADERBOARD");
//     igSeparator();

//     if (leaderboard.length == 0)
//     {
//         igTextColored(muted, "no scores yet - be the first!");
//     }
//     else
//     {
//         foreach (i, e; leaderboard)
//         {
//             int rank = cast(int)i + 1;
//             string name = e.name.length <= 14 ? e.name : e.name[0 .. 14];

//             auto color = rank == 1 ? gold
//                        : rank == 2 ? silver
//                        : rank == 3 ? bronze
//                        : ImVec4(0.90f, 0.90f, 0.90f, 1.0f);

//             igTextColored(color, "%2d.  %s", rank, name.toStringz);
//             igTextColored(muted, "     %d pts  -  %.1f%% acc",
//                 e.score, e.accuracy);
//         }
//     }

//     igEnd();
// }

private void renderLeaderboardPanel(bool wide)
{
    igSetNextWindowPos(cast(float)screenWidth - 20, 20, 4, 1.0f, 0.0f);
    igSetNextWindowBgAlpha(0.90f);

    igBegin("##leaderboard", null,
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoScrollbar |
        ImGuiWindowFlags_AlwaysAutoResize);

    ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
    ImVec4 muted  = ImVec4(0.65f, 0.70f, 0.76f, 1.0f);
    ImVec4 gold   = ImVec4(1.00f, 0.84f, 0.20f, 1.0f);
    ImVec4 silver = ImVec4(0.80f, 0.85f, 0.90f, 1.0f);
    ImVec4 bronze = ImVec4(0.85f, 0.55f, 0.25f, 1.0f);

    igTextColored(orange, "TOP 10 LEADERBOARD");
    igSeparator();

    if (leaderboard.length == 0)
    {
        igTextColored(muted, "no scores yet - be the first!");
        igEnd();
        return;
    }

    import std.format : format;

    // Header row, pre-formatted in D so we don't hit binding vararg quirks.
    string header = format("%-4s %-16s %7s   %6s", "#", "NAME", "SCORE", "ACC");
    igTextColored(muted, "%s", header.toStringz);
    igSeparator();

    foreach (i, e; leaderboard)
    {
        int rank = cast(int)i + 1;
        string name = e.name.length <= 16 ? e.name : e.name[0 .. 16];

        auto color = rank == 1 ? gold
                   : rank == 2 ? silver
                   : rank == 3 ? bronze
                   : ImVec4(0.90f, 0.90f, 0.90f, 1.0f);

        string row = format("%-4d %-16s %7d   %5.1f%%",
            rank, name, e.score, e.accuracy);

        igTextColored(color, "%s", row.toStringz);
    }

    igEnd();
}



// private void renderLeaderboardPanel(bool wide)
// {
//     // Stack the leaderboard directly under the intro/results panel,
//     // centered on screen. Gives it unlimited width headroom and avoids
//     // any collision with the right edge or the dialog above it.
//     float centerX = cast(float)screenWidth / 2.0f;
//     float topY    = cast(float)screenHeight / 2.0f + 180.0f;

//     igSetNextWindowPos(centerX, topY, 4, 0.5f, 0.0f);
//     igSetNextWindowBgAlpha(0.90f);

//     igBegin("##leaderboard", null,
//         ImGuiWindowFlags_NoTitleBar |
//         ImGuiWindowFlags_NoResize |
//         ImGuiWindowFlags_NoMove |
//         ImGuiWindowFlags_NoScrollbar |
//         ImGuiWindowFlags_AlwaysAutoResize);

//     ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
//     ImVec4 muted  = ImVec4(0.65f, 0.70f, 0.76f, 1.0f);
//     ImVec4 gold   = ImVec4(1.00f, 0.84f, 0.20f, 1.0f);
//     ImVec4 silver = ImVec4(0.80f, 0.85f, 0.90f, 1.0f);
//     ImVec4 bronze = ImVec4(0.85f, 0.55f, 0.25f, 1.0f);

//     igTextColored(orange, "TOP 10 LEADERBOARD");
//     igSeparator();

//     if (leaderboard.length == 0)
//     {
//         igTextColored(muted, "no scores yet - be the first!");
//         igEnd();
//         return;
//     }

//     import std.format : format;

//     foreach (i, e; leaderboard)
//     {
//         int rank = cast(int)i + 1;
//         string name = e.name.length <= 16 ? e.name : e.name[0 .. 16];

//         auto color = rank == 1 ? gold
//                    : rank == 2 ? silver
//                    : rank == 3 ? bronze
//                    : ImVec4(0.90f, 0.90f, 0.90f, 1.0f);

//         string row = format("%2d. %-16s  %5d pts   %5.1f%% acc",
//             rank, name, e.score, e.accuracy);

//         igTextColored(color, "%s", row.toStringz);
//     }

//     igEnd();
// }

    //----------------------------------------------------------------
    // HUD: timer ring, combo pulse, kill feed, score/ammo panels
    //----------------------------------------------------------------

    private void renderHud()
    {
        renderTopLeftStats();
        renderTopCenterWeapon();
        renderTopRightTimerRing();
        renderBottomLeftCombo();
        renderBottomCenterPlayer();
        renderFloatingMessages();
    }

    private void renderTopLeftStats()
    {
        igSetNextWindowPos(10, 10, 4, 0, 0);
        igSetNextWindowBgAlpha(0.72f);
        igBegin("##topleft", null,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoScrollbar);

        ImVec4 orange = ImVec4(0.98f, 0.62f, 0.18f, 1.0f);
        ImVec4 green  = ImVec4(0.48f, 0.88f, 0.40f, 1.0f);
        ImVec4 muted  = ImVec4(0.62f, 0.68f, 0.74f, 1.0f);

        igTextColored(orange, "SCORE  %d", score);
        igTextColored(muted,  "cubes  %d", cubesHit);
        igTextColored(green,  "kills  %d", enemiesKilled);
        igText("acc    %.1f%%", accuracy);
        igEnd();
    }

    private void renderTopCenterWeapon()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, 10, 4, 0.5f, 0);
        igSetNextWindowBgAlpha(0.72f);
        igBegin("##topcenter", null,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoScrollbar);

        igText("%s", weaponName.toStringz);
        igText("AMMO   %d / %d", currentAmmo, maxAmmo);
        igText("STATE  %s", movementState.toStringz);
        igText("SPREAD %.3f", currentSpread);
        igEnd();
    }

    /// Timer ring in the top-right. Uses ImGui's draw list to draw an arc
    /// that counts down from full to empty, color-shifting toward red as
    /// time runs out.
    private void renderTopRightTimerRing()
{
    const float ringSize = 100.0f;
    const float ringPadding = 20.0f;

    igSetNextWindowPos(cast(float)screenWidth - ringPadding, ringPadding, 4, 1.0f, 0.0f);
    // igSetNextWindowSize(ringSize + 20, ringSize + 102, 2);
    igSetNextWindowSize(ringSize + 20, ringSize + 78, 2);
    igSetNextWindowBgAlpha(0.60f);
    igBegin("##timer_ring", null,
        ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoScrollbar);

    ImVec2 winPos;
    igGetWindowPos(&winPos);
    ImVec2 winSize;
    igGetWindowSize(&winSize);

    auto drawList = igGetWindowDrawList();
    float centerX = winPos.x + winSize.x * 0.5f;
    float centerY = winPos.y + 14.0f + ringSize * 0.5f;
    float radius  = ringSize * 0.40f;

    ImU32 bgCol = igGetColorU32_Vec4(ImVec4(0.22f, 0.24f, 0.28f, 1.0f));
    ImDrawList_AddCircle(drawList, ImVec2(centerX, centerY), radius,
        bgCol, 48, 5.0f);

    float frac = cast(float)(roundTimeTotal > 0 ? roundTimeRemaining / roundTimeTotal : 0);
    if (frac < 0) frac = 0;
    if (frac > 1) frac = 1;

    float r, g, b;
    if (frac > 0.5f)
    {
        float t = (frac - 0.5f) * 2.0f;
        r = 0.98f * (1.0f - t) + 0.48f * t;
        g = 0.62f * (1.0f - t) + 0.88f * t;
        b = 0.18f * (1.0f - t) + 0.40f * t;
    }
    else
    {
        float t = frac * 2.0f;
        r = 0.95f * (1.0f - t) + 0.98f * t;
        g = 0.25f * (1.0f - t) + 0.62f * t;
        b = 0.20f * (1.0f - t) + 0.18f * t;
    }
    ImU32 fgCol = igGetColorU32_Vec4(ImVec4(r, g, b, 1.0f));

    float start = cast(float)(-PI * 0.5);
    float end   = cast(float)(start + 2.0 * PI * frac);

    const int segments = 64;
    ImDrawList_PathClear(drawList);
    ImDrawList_PathArcTo(drawList, ImVec2(centerX, centerY), radius, start, end, segments);
    ImDrawList_PathStroke(drawList, fgCol, false, 5.0f);

    int sec = cast(int)(roundTimeRemaining + 0.5);
    if (sec < 0) sec = 0;
    import std.format : format;
    string txt = format("%d", sec);
    ImVec2 txtSize;
    igCalcTextSize(&txtSize, txt.toStringz, null, false, -1.0f);
    ImU32 textCol = igGetColorU32_Vec4(ImVec4(1, 1, 1, 1));
    ImDrawList_AddText_Vec2(drawList,
        ImVec2(centerX - txtSize.x * 0.5f, centerY - txtSize.y * 0.5f),
        textCol, txt.toStringz, null);

    ImVec2 labelSize;
    string labelStr = "TIME";
    igCalcTextSize(&labelSize, labelStr.toStringz, null, false, -1.0f);
    ImU32 labelCol = igGetColorU32_Vec4(ImVec4(0.72f, 0.76f, 0.82f, 1.0f));
    ImDrawList_AddText_Vec2(drawList,
        ImVec2(centerX - labelSize.x * 0.5f, centerY + radius + 6.0f),
        labelCol, labelStr.toStringz, null);

    // // FPS readout below the ring.
    // string fpsStr = format("FPS %d", cast(int)lastFiveSecFps);
    // ImVec2 fpsSize;
    // igCalcTextSize(&fpsSize, fpsStr.toStringz, null, false, -1.0f);
    // ImU32 fpsCol = igGetColorU32_Vec4(ImVec4(0.55f, 0.60f, 0.66f, 1.0f));
    // ImDrawList_AddText_Vec2(drawList,
    //     ImVec2(centerX - fpsSize.x * 0.5f, centerY + radius + 24.0f),
    //     fpsCol, fpsStr.toStringz, null);
    // FPS readout below the ring.
string fpsStr = format("FPS %d", cast(int)lastFiveSecFps);
ImVec2 fpsSize;
igCalcTextSize(&fpsSize, fpsStr.toStringz, null, false, -1.0f);
ImU32 fpsCol = igGetColorU32_Vec4(ImVec4(0.55f, 0.60f, 0.66f, 1.0f));
ImDrawList_AddText_Vec2(drawList,
    ImVec2(centerX - fpsSize.x * 0.5f, centerY + radius + 24.0f),
    fpsCol, fpsStr.toStringz, null);

    igEnd();
}

    /// Combo multiplier panel. Pulses in scale when the combo advances.
    private void renderBottomLeftCombo()
    {
        igSetNextWindowPos(10, cast(float)screenHeight - 20, 4, 0, 1.0f);
        igSetNextWindowBgAlpha(0.72f);
        igBegin("##combo", null,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoScrollbar);

        ImVec4 muted = ImVec4(0.62f, 0.68f, 0.74f, 1.0f);

        if (comboCount <= 1)
        {
            igTextColored(muted, "COMBO  -");
            igTextColored(muted, "chain hits for bonus score");
        }
        else
        {
            // Pulse color when advancing
            float pulse = mComboPulseRemaining > 0
                ? cast(float)(mComboPulseRemaining / 0.5)
                : 0.0f;
            if (pulse < 0) pulse = 0;
            if (pulse > 1) pulse = 1;

            float r = 0.98f * (1.0f - pulse) + 1.00f * pulse;
            float g = 0.62f * (1.0f - pulse) + 0.92f * pulse;
            float b = 0.18f * (1.0f - pulse) + 0.30f * pulse;

            igTextColored(ImVec4(r, g, b, 1.0f), "COMBO  x%d", comboCount);
            igText("multi  %.2fx", comboMultiplier);
        }

        igText("enemies alive  %d / %d", enemiesAlive, kMaxAliveEnemies);
        igEnd();
    }

    private void renderBottomCenterPlayer()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight - 12, 4, 0.5f, 1.0f);
        igSetNextWindowBgAlpha(0.65f);
        igBegin("##bottomcenter", null,
            ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoScrollbar);

        igText("%s", playerName.toStringz);
        igEnd();
    }

    /// Floating "+N" style messages near screen center. They drift up and fade.
    private void renderFloatingMessages()
    {
        if (mFloatingMessages.length == 0)
            return;

        // Host window for popups: full-screen-ish, no background, no inputs,
        // no decoration. Uses the window drawlist (which always links).
        igSetNextWindowPos(0, 0, 4, 0.0f, 0.0f);
        igSetNextWindowSize(cast(float)screenWidth, cast(float)screenHeight, 2);
        igSetNextWindowBgAlpha(0.0f);
        igBegin("##score_popups", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoScrollbar |
            ImGuiWindowFlags_NoBackground |
            ImGuiWindowFlags_NoInputs);

        auto drawList = igGetWindowDrawList();
        float centerX = cast(float)screenWidth * 0.5f;
        float baseY = cast(float)screenHeight * 0.55f;

        foreach (i, ref m; mFloatingMessages)
        {
            float lifeFrac = cast(float)(m.ttl / m.maxTtl);
            if (lifeFrac < 0) lifeFrac = 0;
            if (lifeFrac > 1) lifeFrac = 1;

            float alpha = lifeFrac;                       // fade as ttl drops
            float rise  = (1.0f - lifeFrac) * 50.0f;      // px upward drift
            float y = baseY - rise - cast(float)i * 26.0f;

            ImVec2 sz;
            igCalcTextSize(&sz, m.text.toStringz, null, false, -1.0f);

            ImU32 col = igGetColorU32_Vec4(ImVec4(m.r, m.g, m.b, alpha));
            ImU32 shadow = igGetColorU32_Vec4(ImVec4(0, 0, 0, alpha * 0.6f));
            ImDrawList_AddText_Vec2(drawList,
                ImVec2(centerX - sz.x * 0.5f + 1, y + 1),
                shadow, m.text.toStringz, null);
            ImDrawList_AddText_Vec2(drawList,
                ImVec2(centerX - sz.x * 0.5f, y),
                col, m.text.toStringz, null);
        }

        igEnd();
    }

    private void renderControlsBlock()
    {
        igText("  W/A/S/D       Move");
        igText("  Mouse         Aim");
        igText("  Left Click    Shoot");
        igText("  R             Reload");
        igText("  Left Shift    Sprint (wider spread)");
        igText("  Tab           Toggle wireframe");
        igText("  ESC           Quit");
        igText("  Ctrl + E      Collision editor");
    }
}