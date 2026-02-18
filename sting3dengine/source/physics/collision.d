module collision;

import std.stdio;

// compile this program on its own
// ldc2 -c collision.d


extern(C):

alias b3PhysicsClientHandle = void*;
alias b3SharedMemoryCommandHandle = void*;

// Mirrors b3ContactPointData in SharedMemoryPublic.h
struct b3ContactPointData
{
    int m_contactFlags;
    int m_bodyUniqueIdA;
    int m_bodyUniqueIdB;
    int m_linkIndexA;
    int m_linkIndexB;

    double[3] m_positionOnAInWS;
    double[3] m_positionOnBInWS;
    double[3] m_contactNormalOnBInWS;

    double m_contactDistance; // negative = penetration
    double m_normalForce;
    double m_linearFrictionForce1;
    double m_linearFrictionForce2;
    double[3] m_linearFrictionDirection1;
    double[3] m_linearFrictionDirection2;
}

struct b3ContactInformation
{
    int m_numContactPoints;
    b3ContactPointData* m_contactPointData;
}



// Submit command + wait for status (blocking)
void* b3SubmitClientCommandAndWaitStatus(
    b3PhysicsClientHandle physClient,
    b3SharedMemoryCommandHandle commandHandle
);

// Contact query API
b3SharedMemoryCommandHandle b3InitRequestContactPointInformation(b3PhysicsClientHandle physClient);
void b3SetContactFilterBodyA(b3SharedMemoryCommandHandle commandHandle, int bodyUniqueIdA);
void b3SetContactFilterBodyB(b3SharedMemoryCommandHandle commandHandle, int bodyUniqueIdB);

// After requesting contact points, read them into this struct
void b3GetContactPointInformation(b3PhysicsClientHandle physClient, b3ContactInformation* contactPointData);




// Helpers:
b3ContactInformation getContactsBetween(b3PhysicsClientHandle client, int bodyA, int bodyB)
{
    // Ask Bullet to compute/report contact info for the last simulation step.
    auto cmd = b3InitRequestContactPointInformation(client);
    b3SetContactFilterBodyA(cmd, bodyA);
    b3SetContactFilterBodyB(cmd, bodyB);

    // Blocking submit (simplest path)
    auto status = b3SubmitClientCommandAndWaitStatus(client, cmd);

    b3ContactInformation info;
    b3GetContactPointInformation(client, &info);
    return info;
}






bool didBodiesTouch(b3PhysicsClientHandle client, int bodyA, int bodyB)
{
    auto info = getContactsBetween(client, bodyA, bodyB);
    return info.m_numContactPoints > 0;
}

void printFirstContact(b3PhysicsClientHandle client, int bodyA, int bodyB)
{
    auto info = getContactsBetween(client, bodyA, bodyB);
    if (info.m_numContactPoints <= 0) return;

    auto c = info.m_contactPointData[0];

    writeln("CONTACT between ", bodyA, " and ", bodyB,
        " | count=", info.m_numContactPoints,
        " | distance=", c.m_contactDistance,
        " | normalForce=", c.m_normalForce);

    writeln("  posOnBWS=(", c.m_positionOnBInWS[0], ", ", c.m_positionOnBInWS[1], ", ", c.m_positionOnBInWS[2], ")");
    writeln("  normalOnBWS=(", c.m_contactNormalOnBInWS[0], ", ", c.m_contactNormalOnBInWS[1], ", ", c.m_contactNormalOnBInWS[2], ")");
}