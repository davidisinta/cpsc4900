module types;

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


// Mirrors b3ContactInformation in SharedMemoryPublic.h
struct b3ContactInformation
{
    int m_numContactPoints;
    b3ContactPointData* m_contactPointData;
}