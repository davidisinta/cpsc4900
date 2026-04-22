module frustum;

import std.math : sqrt;
import linear;

struct FrustumPlane {
    float a, b, c, d;
}

/// Extract 6 frustum planes from a View*Projection matrix.
/// Call once per frame after camera updates.
FrustumPlane[6] extractFrustumPlanes(mat4 vp)
{
    FrustumPlane[6] planes;

    // Left: row3 + row0
    planes[0].a = vp[12] + vp[0];
    planes[0].b = vp[13] + vp[1];
    planes[0].c = vp[14] + vp[2];
    planes[0].d = vp[15] + vp[3];

    // Right: row3 - row0
    planes[1].a = vp[12] - vp[0];
    planes[1].b = vp[13] - vp[1];
    planes[1].c = vp[14] - vp[2];
    planes[1].d = vp[15] - vp[3];

    // Bottom: row3 + row1
    planes[2].a = vp[12] + vp[4];
    planes[2].b = vp[13] + vp[5];
    planes[2].c = vp[14] + vp[6];
    planes[2].d = vp[15] + vp[7];

    // Top: row3 - row1
    planes[3].a = vp[12] - vp[4];
    planes[3].b = vp[13] - vp[5];
    planes[3].c = vp[14] - vp[6];
    planes[3].d = vp[15] - vp[7];

    // Near: row3 + row2
    planes[4].a = vp[12] + vp[8];
    planes[4].b = vp[13] + vp[9];
    planes[4].c = vp[14] + vp[10];
    planes[4].d = vp[15] + vp[11];

    // Far: row3 - row2
    planes[5].a = vp[12] - vp[8];
    planes[5].b = vp[13] - vp[9];
    planes[5].c = vp[14] - vp[10];
    planes[5].d = vp[15] - vp[11];

    // Normalize each plane
    foreach (ref p; planes)
    {
        float len = sqrt(p.a * p.a + p.b * p.b + p.c * p.c);
        if (len > 0)
        {
            p.a /= len;
            p.b /= len;
            p.c /= len;
            p.d /= len;
        }
    }

    return planes;
}

/// Test if a bounding sphere is inside or intersecting the frustum.
/// Returns true if visible (should draw), false if entirely outside (cull it).
bool isSphereInFrustum(FrustumPlane[6] planes, vec3 center, float radius)
{
    foreach (ref p; planes)
    {
        float dist = p.a * center.x + p.b * center.y + p.c * center.z + p.d;
        if (dist < -radius)
            return false; // entirely outside this plane
    }
    return true;
}
