module perlinnoise;

//standard libraries
import std.math;
import std.random;
import std.algorithm : swap;
import std.conv : to;
import std.stdio;

//project libraries
import linear;

/// Helper Functions
T lerp(T)(ref T lo, ref T hi, ref T t){
	return lo * (1 - t) + hi * t;
}

float smoothstep(ref float t){
    return t * t * (3 - 2 * t);
}

float quintic(ref float t){
    return t * t * t * (t * (t * 6 - 15) + 10);
}

float smoothstepDeriv(ref float t){
    return t * (6 - 6 * t);
}

float quinticDeriv(ref float t){
    return 30 * t * t * (t * (t - 2) + 1);
}

class PerlinNoise {
    static immutable uint tableSize = 256;
    static immutable uint tableSizeMask = tableSize - 1;

    vec3[tableSize] gradients;
    uint[tableSize * 2] permutationTable;

    this(uint seed = 2016) {

        // writeln("constructor called!!");
        auto rng = Mt19937(seed);

        foreach (i; 0 .. tableSize) {
            float theta = acos(2.0f * uniform01!float(rng) - 1.0f);
            float phi = 2.0f * uniform01!float(rng) * PI;

            float x = cos(phi) * sin(theta);
            float y = sin(phi) * sin(theta);
            float z = cos(theta);
            gradients[i] = vec3(x, y, z);

            permutationTable[i] = i;
        }

        foreach (i; 0 .. tableSize){
            permutationTable[i].swap(permutationTable[uniform(0, tableSize) & tableSizeMask]);
        }
            
        foreach (i; 0 .. tableSize){
            permutationTable[tableSize + i] = permutationTable[i];
        }   

        // writeln("constructor complete!!");
    }

    float eval(const vec3 p, out vec3 derivs) const {
        int xi0 = cast(int)floor(p.x) & tableSizeMask;
        int yi0 = cast(int)floor(p.y) & tableSizeMask;
        int zi0 = cast(int)floor(p.z) & tableSizeMask;

        int xi1 = (xi0 + 1) & tableSizeMask;
        int yi1 = (yi0 + 1) & tableSizeMask;
        int zi1 = (zi0 + 1) & tableSizeMask;

        float tx = p.x - floor(p.x);
        float ty = p.y - floor(p.y);
        float tz = p.z - floor(p.z);

        float u = quintic(tx);
        float v = quintic(ty);
        float w = quintic(tz);

        float x0 = tx, x1 = tx - 1;
        float y0 = ty, y1 = ty - 1;
        float z0 = tz, z1 = tz - 1;

        float a = gradientDotV(hash(xi0, yi0, zi0), x0, y0, z0);
        float b = gradientDotV(hash(xi1, yi0, zi0), x1, y0, z0);
        float c = gradientDotV(hash(xi0, yi1, zi0), x0, y1, z0);
        float d = gradientDotV(hash(xi1, yi1, zi0), x1, y1, z0);
        float e = gradientDotV(hash(xi0, yi0, zi1), x0, y0, z1);
        float f = gradientDotV(hash(xi1, yi0, zi1), x1, y0, z1);
        float g = gradientDotV(hash(xi0, yi1, zi1), x0, y1, z1);
        float h = gradientDotV(hash(xi1, yi1, zi1), x1, y1, z1);

        float du = quinticDeriv(tx);
        float dv = quinticDeriv(ty);
        float dw = quinticDeriv(tz);

        float k0 = a;
        float k1 = b - a;
        float k2 = c - a;
        float k3 = e - a;
        float k4 = a + d - b - c;
        float k5 = a + f - b - e;
        float k6 = a + g - c - e;
        float k7 = b + c + e + h - a - d - f - g;

        derivs.x = du * (k1 + k4 * v + k5 * w + k7 * v * w);
        derivs.y = dv * (k2 + k4 * u + k6 * w + k7 * u * w);
        derivs.z = dw * (k3 + k5 * u + k6 * v + k7 * u * v);

        // writeln("eval called");

        return k0 + k1 * u + k2 * v + k3 * w + k4 * u * v + k5 * u * w + k6 * v * w + k7 * u * v * w;
    }

private:
    ubyte hash(ref int x, ref int y, ref int z) const {
        return cast(ubyte) permutationTable[permutationTable[permutationTable[x] + y] + z];
    }

    float gradientDotV(ubyte perm, float x, float y, float z) const {
        switch (perm & 15) {
            case 0:  return x + y;
            case 1:  return -x + y;
            case 2:  return x - y;
            case 3:  return -x - y;
            case 4:  return x + z;
            case 5:  return -x + z;
            case 6:  return x - z;
            case 7:  return -x - z;
            case 8:  return y + z;
            case 9:  return -y + z;
            case 10: return y - z;
            case 11: return -y - z;
            case 12: return y + x;
            case 13: return -x + y;
            case 14: return -y + z;
            case 15: return -y - z;
            default: return 0;
        }
    }

    // float quintic(float t) const {
    //     return t * t * t * (t * (t * 6 - 15) + 10);
    // }

    // float quinticDeriv(float t) const {
    //     return 30 * t * t * (t * (t - 2) + 1);
    // }

    // float smoothstep(float t) const {
    //     return t * t * (3 - 2 * t);
    // }

    // float lerp(float a, float b, float t) const {
    //     return a + t * (b - a);
    // }
}
