module igame;

/// Interface that any game must implement.
/// The engine calls these hooks at the right time in the frame loop.
interface IGame
{
    /// Called once after engine systems are ready.
    /// Use this to spawn your scene, set gravity, position camera, etc.
    void Setup();

    /// Called once per frame to handle game-specific input.
    /// Return: engine should pass SDL events here in the future,
    /// but for now the game can query state directly.
    void Input();

    /// Called once per frame after physics sync.
    /// Game logic: shooting, scoring, collisions, spawning, etc.
    void Update(double frameDt);

    /// Called once per frame after 3D render, before swap.
    /// Use for HUD, crosshair, debug overlays.
    void Render();
}
