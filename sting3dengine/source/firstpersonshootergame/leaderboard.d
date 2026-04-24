module leaderboard;

import std.file : exists, readText, write, mkdirRecurse;
import std.path : dirName;
import std.string : splitLines, split, strip;
import std.conv : to;
import std.algorithm : sort;
import std.datetime.systime : Clock;

struct LeaderboardEntry
{
    string name;
    int score;
    int shotsFired;
    int shotsHit;
    float accuracy;
    string timestamp;
}

class LeaderboardStore
{
    private string mPath;
    private LeaderboardEntry[] mEntries;

    this(string path)
    {
        mPath = path;
        load();
    }

    LeaderboardEntry[] top10()
    {
        return mEntries.dup;
    }

    void addScore(string name, int score, int shotsFired, int shotsHit)
    {
        if (name.length == 0)
            name = "Player";

        float acc = shotsFired > 0
            ? cast(float)shotsHit / cast(float)shotsFired * 100.0f
            : 0.0f;

        mEntries ~= LeaderboardEntry(
            name,
            score,
            shotsFired,
            shotsHit,
            acc,
            Clock.currTime().toSimpleString()
        );

        sortEntries();
        if (mEntries.length > 10)
            mEntries = mEntries[0 .. 10];

        save();
    }

    private void load()
    {
        mEntries.length = 0;
        if (!exists(mPath))
            return;

        foreach (line; readText(mPath).splitLines())
        {
            auto clean = line.strip();
            if (clean.length == 0)
                continue;

            auto parts = clean.split("|");
            if (parts.length < 6)
                continue;

            try
            {
                mEntries ~= LeaderboardEntry(
                    parts[0],
                    parts[1].to!int,
                    parts[2].to!int,
                    parts[3].to!int,
                    parts[4].to!float,
                    parts[5]
                );
            }
            catch (Exception)
            {
                // Skip bad lines instead of crashing the game.
            }
        }

        sortEntries();
        if (mEntries.length > 10)
            mEntries = mEntries[0 .. 10];
    }

    private void save()
    {
        auto parent = dirName(mPath);
        if (parent.length > 0)
            mkdirRecurse(parent);

        string output;
        foreach (e; mEntries)
        {
            output ~= e.name ~ "|" ~
                      e.score.to!string ~ "|" ~
                      e.shotsFired.to!string ~ "|" ~
                      e.shotsHit.to!string ~ "|" ~
                      e.accuracy.to!string ~ "|" ~
                      e.timestamp ~ "\n";
        }

        write(mPath, output);
    }

    private void sortEntries()
    {
        sort!((a, b) =>
            (a.score > b.score) ||
            (a.score == b.score && a.accuracy > b.accuracy)
        )(mEntries);
    }
}
