/// TransformComponent — the single source of truth for an entity's
/// position, orientation, and scale.
///
/// Design rationale:
///   - Bullet gives us position (double[3]) + quaternion (double[4]).
///   - The renderer needs a mat4 (row-major, float[16]).
///   - This struct bridges the two: physics writes position+rotation,
///     then toModelMatrix() produces the mat4 for the MeshNode.
///
/// Coordinate system note:
///   Your PhysicsWorld sets gravity to (0, 0, -9.81), meaning Bullet
///   uses Z-up.  Make sure your OpenGL camera/scene also treats Z as up,
///   or swap axes in fromBullet().
///
module transform;

// standard lib files
import std.math : sqrt;

//project files
import linear;

/// Quaternion stored as [x, y, z, w] to match Bullet's convention.
struct Quat
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float w = 1.0f; // identity rotation

    /// Construct from Bullet's double[4] output (which is [x,y,z,w]).
    static Quat fromBulletDoubles(const double[4] q)
    {
        return Quat(
            cast(float) q[0],
            cast(float) q[1],
            cast(float) q[2],
            cast(float) q[3]
        );
    }

    /// Convert this quaternion to a 4×4 rotation matrix.
    ///
    /// Your mat4 is ROW-MAJOR:  e[row*4 + col]
    ///   row 0 = right,   row 1 = up,   row 2 = forward,   row 3 = [0,0,0,1]
    ///
    /// The standard quat→matrix formula (for column vectors, M*v) is:
    ///   | 1-2(yy+zz)   2(xy-wz)    2(xz+wy)  0 |
    ///   | 2(xy+wz)     1-2(xx+zz)  2(yz-wx)   0 |
    ///   | 2(xz-wy)     2(yz+wx)    1-2(xx+yy) 0 |
    ///   | 0             0           0          1 |
    ///
    /// In your row-major layout, element [i,j] is at e[i*4 + j],
    /// so the mapping is straightforward.
    mat4 toMat4() const
    {
        float xx = x * x;
        float yy = y * y;
        float zz = z * z;
        float xy = x * y;
        float xz = x * z;
        float yz = y * z;
        float wx = w * x;
        float wy = w * y;
        float wz = w * z;

        mat4 r = MatrixMakeIdentity();

        // Row 0
        r.e[0]  = 1.0f - 2.0f * (yy + zz);
        r.e[1]  =        2.0f * (xy - wz);
        r.e[2]  =        2.0f * (xz + wy);
        r.e[3]  = 0.0f;

        // Row 1
        r.e[4]  =        2.0f * (xy + wz);
        r.e[5]  = 1.0f - 2.0f * (xx + zz);
        r.e[6]  =        2.0f * (yz - wx);
        r.e[7]  = 0.0f;

        // Row 2
        r.e[8]  =        2.0f * (xz - wy);
        r.e[9]  =        2.0f * (yz + wx);
        r.e[10] = 1.0f - 2.0f * (xx + yy);
        r.e[11] = 0.0f;

        // Row 3 is already [0,0,0,1] from identity
        return r;
    }
}

/// The canonical transform for any entity.
struct TransformComponent
{
    vec3 position  = vec3(0.0f, 0.0f, 0.0f);
    Quat rotation;                               // defaults to identity
    vec3 scale     = vec3(1.0f, 1.0f, 1.0f);

    /// Populate from Bullet's raw state output.
    /// actualStateQ[0..3] = position (x,y,z)
    /// actualStateQ[3..7] = quaternion (x,y,z,w)
    static TransformComponent fromBulletState(const(double)* stateQ)
    {
        TransformComponent t;
        t.position = vec3(
            cast(float) stateQ[0],
            cast(float) stateQ[1],
            cast(float) stateQ[2]
        );
        double[4] q = [stateQ[3], stateQ[4], stateQ[5], stateQ[6]];
        t.rotation = Quat.fromBulletDoubles(q);
        // scale stays at (1,1,1) — Bullet doesn't do scale
        return t;
    }

    /// Build the model matrix:  T * R * S  (translation × rotation × scale)
    ///
    /// This is the standard TRS order so that:
    ///   1. vertices are scaled in local space
    ///   2. then rotated
    ///   3. then translated to world position
    mat4 toModelMatrix() const
    {
        mat4 S = MatrixMakeScale(scale);
        mat4 R = rotation.toMat4();
        mat4 T = MatrixMakeTranslation(position);

        return T * R * S;
    }
}
