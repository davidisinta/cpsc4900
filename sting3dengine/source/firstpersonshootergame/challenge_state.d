module challenge_state;

enum ChallengePhase
{
    Intro,
    Live,
    Results
}

struct ChallengeTarget
{
    uint entityId;
    double ttl;
}

/// A spawned jackpot enemy. Tracks its own collision-editor label so we can
/// remove the right box when the enemy dies.
struct ChallengeEnemy
{
    uint entityId;
    size_t positionIndex;   // index into LevelBuilder.mSoldierPositions / mSoldierEntityIds
    double aliveTime;       // seconds since spawn
}

//--------------------------------------------------------------------
// Round tuning.
//--------------------------------------------------------------------

/// Total round length in seconds.
enum double kChallengeDuration = 45.0;

/// Base cube lifetime — how long a cube lives on the ground before despawning.
enum double kTargetLifetime = 9.0;

/// Score per cube hit (base). Combo multiplier is applied on top.
enum int kPointsPerHit = 100;

/// Score per enemy hit (base). Jackpot = 3x a cube.
enum int kPointsPerEnemy = 300;

//--------------------------------------------------------------------
// Ramp: cubes appear faster AND appear to fall faster as the round
// progresses. We implement "fall faster" by progressively lowering the
// spawn altitude — same gravity, shorter flight, feels more urgent.
//--------------------------------------------------------------------

/// Spawn interval at the start of the round (seconds between cubes).
enum double kCubeSpawnIntervalStart = 1.20;

/// Spawn interval at the end of the round. Must be < start.
enum double kCubeSpawnIntervalEnd = 0.35;

/// Cube spawn Y range at the start of the round (high = slow fall).
enum float kCubeSpawnYMinStart = 18.0f;
enum float kCubeSpawnYMaxStart = 25.0f;

/// Cube spawn Y range at the end of the round (lower = faster impact).
enum float kCubeSpawnYMinEnd = 8.0f;
enum float kCubeSpawnYMaxEnd = 12.0f;

//--------------------------------------------------------------------
// Jackpot enemies.
//--------------------------------------------------------------------

/// Max enemies alive at once.
enum int kMaxAliveEnemies = 5;

/// Range of seconds between enemy spawn attempts.
enum double kEnemySpawnMinInterval = 2.0;
enum double kEnemySpawnMaxInterval = 6.0;

//--------------------------------------------------------------------
// Combo multiplier. Consecutive hits chain within the window; a miss or
// the window expiring resets the combo.
//--------------------------------------------------------------------

/// Seconds since last hit after which the combo breaks.
enum double kComboWindow = 2.0;

/// Max combo factor applied to score. Multiplier = 1 + 0.5 * (combo - 1), capped.
enum float kComboMaxMultiplier = 4.0f;