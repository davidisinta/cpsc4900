module gameapplication;

// standard libraries
import std.stdio;
import std.string;


//the game application struct brings together all the components necessary to put together the game.
class GameApplication{
    string gameName;

    this(string name) {
        this.gameName = name;
    }

}