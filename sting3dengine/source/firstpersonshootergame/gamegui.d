module gamegui;

import std.stdio;
import std.string : toStringz;
import std.conv : to;
import editor;

class GameGUI
{
    string mGuiName;

    // Game state refs — set these from GameApplication each frame
    int kills = 0;
    float accuracy = 0.0f;
    int currentAmmo = 30;
    int maxAmmo = 30;
    string weaponName = "PISTOL";
    string playerName = "Bazenga";
    float health = 100.0f;
    float maxHealth = 100.0f;
    int roundTimeSeconds = 38;
    int comboCount = 0;
    int fps = 0;

    double lastFiveSecFps = 60;

    // Screen dimensions — set from engine
    int screenWidth = 960;
    int screenHeight = 720;

    this(string name)
    {
        mGuiName = name;
    }

    void Render()
    {
        // ============================================
        // TOP LEFT — Kills / Accuracy
        // ============================================
        igSetNextWindowPos(10, 10, 2, 0, 0);  // cond=2 is ImGuiCond_Once... use Always=4? 
        igSetNextWindowBgAlpha(0.6f);
        igBegin("##topleft", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("KILLS: %d", kills);
        igText("ACCURACY: %.1f%%", accuracy);
        if (comboCount > 1)
            igText("COMBO: x%d", comboCount);

        igEnd();

        // ============================================
        // TOP CENTER — Weapon + Ammo
        // ============================================
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, 10, 4, 0.5f, 0);
        igSetNextWindowBgAlpha(0.6f);
        igBegin("##topcenter", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("%s", weaponName.toStringz);
        igText("%d / %d", currentAmmo, maxAmmo);

        igEnd();

        // ============================================
        // TOP RIGHT — FPS
        // ============================================
        igSetNextWindowPos(cast(float)screenWidth - 30, 10, 4, 1.0f, 0);
        igSetNextWindowBgAlpha(0.4f);
        igBegin("##topright", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("FPS: %d", cast(int)lastFiveSecFps);

        igEnd();

        // ============================================
        // BOTTOM LEFT — Round Timer
        // ============================================
        int minutes = roundTimeSeconds / 60;
        int seconds = roundTimeSeconds % 60;

        igSetNextWindowPos(10, cast(float)screenHeight - 50, 4, 0, 1.0f);
        igSetNextWindowBgAlpha(0.6f);
        igBegin("##bottomleft", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("%02d:%02d", minutes, seconds);

        igEnd();

        // ============================================
        // BOTTOM CENTER — Player Name + Health Bar
        // ============================================
        igSetNextWindowPos(cast(float)screenWidth / 2.0f, cast(float)screenHeight - 10, 4, 0.5f, 1.0f);
        igSetNextWindowBgAlpha(0.6f);
        igBegin("##bottomcenter", null,
            ImGuiWindowFlags_NoTitleBar |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoScrollbar);

        igText("%s", playerName.toStringz);

        float healthFrac = health / maxHealth;
        igProgressBar(healthFrac, 200, 18, null);

        igEnd();

        // ============================================
        // Finalize ImGui
        // ============================================
        igRender();
        ImGui_ImplOpenGL3_RenderDrawData(igGetDrawData());
    }
}