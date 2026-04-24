// module gamegui;

// import std.stdio;
// import std.string : toStringz;
// import std.conv : to;
// import editor;
// import collisioneditor;

// class GameGUI
// {
//     string mGuiName;

//     // Game state refs — set these from GameApplication each frame
//     int kills = 0;
//     float accuracy = 0.0f;
//     int currentAmmo = 30;
//     int maxAmmo = 30;
//     string weaponName = "PISTOL";
//     string playerName = "Bazenga";
//     float health = 100.0f;
//     float maxHealth = 100.0f;
//     int roundTimeSeconds = 38;
//     int comboCount = 0;
//     int fps = 0;

//     double lastFiveSecFps = 60;

//     CollisionEditor mCollisionEditor;

//     // Screen dimensions — set from engine
//     int screenWidth = 960;
//     int screenHeight = 720;

//     this(string name)
//     {
//         mGuiName = name;
//     }

//     void Render()
//     {
//         // ============================================
//         // TOP LEFT — Kills / Accuracy
//         // ============================================
//         igSetNextWindowPos(10, 10, 2, 0, 0);  // cond=2 is ImGuiCond_Once... use Always=4? 
//         igSetNextWindowBgAlpha(0.6f);
//         igBegin("##topleft", null,
//             ImGuiWindowFlags_NoTitleBar |
//             ImGuiWindowFlags_NoResize |
//             ImGuiWindowFlags_NoMove |
//             ImGuiWindowFlags_AlwaysAutoResize |
//             ImGuiWindowFlags_NoScrollbar);

//         igText("KILLS: %d", kills);
//         igText("ACCURACY: %.1f%%", accuracy);
//         if (comboCount > 1)
//             igText("COMBO: x%d", comboCount);

//         igEnd();

//         // ============================================
//         // TOP CENTER — Weapon + Ammo
//         // ============================================
//         igSetNextWindowPos(cast(float)screenWidth / 2.0f, 10, 4, 0.5f, 0);
//         igSetNextWindowBgAlpha(0.6f);
//         igBegin("##topcenter", null,
//             ImGuiWindowFlags_NoTitleBar |
//             ImGuiWindowFlags_NoResize |
//             ImGuiWindowFlags_NoMove |
//             ImGuiWindowFlags_AlwaysAutoResize |
//             ImGuiWindowFlags_NoScrollbar);

//         igText("%s", weaponName.toStringz);
//         igText("%d / %d", currentAmmo, maxAmmo);

//         igEnd();

//         // ============================================
//         // TOP RIGHT — FPS
//         // ============================================
//         igSetNextWindowPos(cast(float)screenWidth - 30, 10, 4, 1.0f, 0);
//         igSetNextWindowBgAlpha(0.4f);
//         igBegin("##topright", null,
//             ImGuiWindowFlags_NoTitleBar |
//             ImGuiWindowFlags_NoResize |
//             ImGuiWindowFlags_NoMove |
//             ImGuiWindowFlags_AlwaysAutoResize |
//             ImGuiWindowFlags_NoScrollbar);

//         igText("FPS: %d", cast(int)lastFiveSecFps);

//         igEnd();

//         // ============================================
//         // BOTTOM LEFT — Round Timer
//         // ============================================
//         int minutes = roundTimeSeconds / 60;
//         int seconds = roundTimeSeconds % 60;

//         igSetNextWindowPos(10, cast(float)screenHeight - 50, 4, 0, 1.0f);
//         igSetNextWindowBgAlpha(0.6f);
//         igBegin("##bottomleft", null,
//             ImGuiWindowFlags_NoTitleBar |
//             ImGuiWindowFlags_NoResize |
//             ImGuiWindowFlags_NoMove |
//             ImGuiWindowFlags_AlwaysAutoResize |
//             ImGuiWindowFlags_NoScrollbar);

//         igText("%02d:%02d", minutes, seconds);

//         igEnd();

//         // ============================================
//         // BOTTOM CENTER — Player Name + Health Bar
//         // ============================================
//         igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight - 10, 4, 0.5f, 1.0f);
//         igSetNextWindowBgAlpha(0.6f);
//         igBegin("##bottomcenter", null,
//             ImGuiWindowFlags_NoTitleBar |
//             ImGuiWindowFlags_NoResize |
//             ImGuiWindowFlags_NoMove |
//             ImGuiWindowFlags_AlwaysAutoResize |
//             ImGuiWindowFlags_NoScrollbar);

//         igText("%s", playerName.toStringz);

//         float healthFrac = health / maxHealth;
//         igProgressBar(healthFrac, 200, 18, null);

//         igEnd();



//         // ============================================
//         // Collision Editor Panel (if active)
//         // ============================================
//         if (mCollisionEditor !is null)
//             mCollisionEditor.renderGUI(screenWidth, screenHeight);

//         // ============================================
//         // Finalize ImGui
//         // ============================================
//         igRender();



//         ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData());
//     }
// }

module gamegui;

import std.stdio;
import std.string : toStringz, fromStringz;
import std.conv : to;

import editor;
import collisioneditor;
import challenge_state;
import leaderboard;

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
    float health = 100.0f;
    float maxHealth = 100.0f;
    int roundTimeSeconds = 90;
    int comboCount = 0;
    int fps = 0;
    double lastFiveSecFps = 60;
    string movementState = "STOPPED";
    float currentSpread = 0.0f;

    LeaderboardEntry[] leaderboard;
    int finalScore = 0;

    CollisionEditor mCollisionEditor;

    // Screen dimensions — set from engine if you already do that elsewhere.
    int screenWidth = 960;
    int screenHeight = 720;

    private char[32] mPlayerNameBuffer;
    private bool mStartPressed = false;
    private bool mRestartPressed = false;

    this(string name)
    {
        mGuiName = name;
        setDefaultName("Player");
    }

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

    void Render()
    {
        if (phase == ChallengePhase.Intro)
        {
            renderIntro();
            renderLeaderboardPanel();
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
            renderLeaderboardPanel();
        }

        igRender();
        ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData());
    }

    private void renderIntro()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight / 2.0f, 4, 0.5f, 0.5f);
        igSetNextWindowBgAlpha(0.94f);

        igBegin("##challenge_intro", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize);

        ImVec4 orange = ImVec4(0.94f, 0.58f, 0.17f, 1.0f);
        ImVec4 green  = ImVec4(0.45f, 0.85f, 0.38f, 1.0f);
        ImVec4 muted  = ImVec4(0.60f, 0.66f, 0.72f, 1.0f);

        igTextColored(orange, "TOPSHOOTA TARGET PRACTICE");
        igTextColored(muted, "Precision challenge | 90 seconds | Score + accuracy");
        igSeparator();

        igText("PLAYER NAME");
        igInputText("##player_name", mPlayerNameBuffer.ptr, mPlayerNameBuffer.length, 0, null, null);

        igSeparator();
        igTextColored(green, "CHALLENGE");
        igText("Shapes fall from the sky.");
        igText("Shoot as many as possible before time runs out.");
        igText("Leaderboard ranks by score first, then accuracy.");

        igSeparator();
        renderControlsBlock();

        igSeparator();
        if (igButton("START CHALLENGE", 220, 38))
            mStartPressed = true;

        igEnd();
    }

    private void renderResults()
    {
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight / 2.0f, 4, 0.5f, 0.5f);
        igSetNextWindowBgAlpha(0.94f);

        igBegin("##challenge_results", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize);

        ImVec4 orange = ImVec4(0.94f, 0.58f, 0.17f, 1.0f);
        ImVec4 green  = ImVec4(0.45f, 0.85f, 0.38f, 1.0f);

        igTextColored(orange, "CHALLENGE COMPLETE");
        igSeparator();
        igText("Player: %s", playerName.toStringz);
        igText("Final Score: %d", finalScore);
        igText("Shots: %d", shotsFired);
        igText("Hits: %d", shotsHit);
        igText("Accuracy: %.1f%%", accuracy);

        igSeparator();
        igTextColored(green, "CONTROLS REMINDER");
        renderControlsBlock();

        igSeparator();
        if (igButton("PLAY AGAIN", 180, 34))
            mRestartPressed = true;

        igEnd();
    }

    private void renderLeaderboardPanel()
    {
        igSetNextWindowPos(cast(float)screenWidth - 20, 20, 4, 1.0f, 0.0f);
        igSetNextWindowBgAlpha(0.88f);

        igBegin("##leaderboard", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize);

        ImVec4 orange = ImVec4(0.94f, 0.58f, 0.17f, 1.0f);
        igTextColored(orange, "TOP 10 LEADERBOARD");
        igSeparator();

        if (leaderboard.length == 0)
        {
            igText("No scores yet.");
        }
        else
        {
            foreach (i, e; leaderboard)
            {
                igText("%d. %s | %d pts | %.1f%%",
                    cast(int)i + 1,
                    e.name.toStringz,
                    e.score,
                    e.accuracy);
            }
        }

        igEnd();
    }

    private void renderHud()
    {
        // TOP LEFT — score / accuracy
        igSetNextWindowPos(10, 10, 4, 0, 0);
        igSetNextWindowBgAlpha(0.65f);
        igBegin("##topleft", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("SCORE: %d", score);
        igText("HITS: %d", shotsHit);
        igText("ACCURACY: %.1f%%", accuracy);
        if (comboCount > 1)
            igText("COMBO: x%d", comboCount);
        igEnd();

        // TOP CENTER — weapon / ammo / spread
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, 10, 4, 0.5f, 0);
        igSetNextWindowBgAlpha(0.65f);
        igBegin("##topcenter", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("%s", weaponName.toStringz);
        igText("AMMO: %d / %d", currentAmmo, maxAmmo);
        igText("STATE: %s", movementState.toStringz);
        igText("SPREAD: %.3f", currentSpread);
        igEnd();

        // TOP RIGHT — FPS
        igSetNextWindowPos(cast(float)screenWidth - 20, 10, 4, 1.0f, 0);
        igSetNextWindowBgAlpha(0.5f);
        igBegin("##topright", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("FPS: %d", cast(int)lastFiveSecFps);
        igEnd();

        // BOTTOM LEFT — timer
        int minutes = roundTimeSeconds / 60;
        int seconds = roundTimeSeconds % 60;

        igSetNextWindowPos(10, cast(float)screenHeight - 50, 4, 0, 1.0f);
        igSetNextWindowBgAlpha(0.70f);
        igBegin("##bottomleft", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("TIME: %02d:%02d", minutes, seconds);
        igEnd();

        // BOTTOM CENTER — player / health
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight - 12, 4, 0.5f, 1.0f);
        igSetNextWindowBgAlpha(0.65f);
        igBegin("##bottomcenter", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("%s", playerName.toStringz);
        float healthFrac = health / maxHealth;
        igProgressBar(healthFrac, 220, 18, null);
        igEnd();
    }

    private void renderControlsBlock()
    {
        igText("W/A/S/D       Move");
        igText("Mouse         Aim");
        igText("Left Click    Shoot");
        igText("R             Reload");
        igText("Left Shift    Sprint / harder aim");
        igText("Tab           Toggle wireframe");
        igText("ESC           Quit game");
        igText("Ctrl + E      Collision editor");
        igText("Editor: P print boxes, F4 show/hide boxes");
    }
}

