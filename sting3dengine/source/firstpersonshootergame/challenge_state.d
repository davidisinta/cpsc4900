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

enum double kChallengeDuration = 90.0;
enum double kTargetSpawnInterval = 0.75;
enum double kTargetLifetime = 9.0;
enum int kPointsPerHit = 100;
