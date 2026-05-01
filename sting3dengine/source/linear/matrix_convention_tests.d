module matrix_convention_tests;

import std.stdio;
import std.math : fabs, cos, sin;
import std.conv : to;
import mat;
import vec;

enum float EPS = 1e-4f;

bool approx(float a, float b, float eps = EPS)
{
    return fabs(a - b) <= eps;
}

bool approxVec4(vec4 a, vec4 b, float eps = EPS)
{
    return approx(a[0], b[0], eps) && approx(a[1], b[1], eps) &&
           approx(a[2], b[2], eps) && approx(a[3], b[3], eps);
}

bool approxMat4(mat4 a, mat4 b, float eps = EPS)
{
    for (int i = 0; i < 16; i++)
        if (!approx(a[i], b[i], eps)) return false;
    return true;
}

unittest // T001: Translation lives at [3],[7],[11]
{
    mat4 T = MatrixMakeTranslation(vec3(1f, 2f, 3f));
    bool pass = approx(T[3], 1f) && approx(T[7], 2f) && approx(T[11], 3f);
    writeln("T001 translation at [3],[7],[11]: ", pass ? "PASS" : "FAIL",
            "  [3]=", T[3], " [7]=", T[7], " [11]=", T[11]);
    assert(pass);
}

unittest // T002: Translation NOT at [12],[13],[14]
{
    mat4 T = MatrixMakeTranslation(vec3(10f, 20f, 30f));
    bool pass = approx(T[12], 0f) && approx(T[13], 0f) && approx(T[14], 0f);
    writeln("T002 translation NOT at [12],[13],[14]: ", pass ? "PASS" : "FAIL",
            "  [12]=", T[12], " [13]=", T[13], " [14]=", T[14]);
    assert(pass);
}

unittest // T003: Translation moves origin
{
    mat4 T = MatrixMakeTranslation(vec3(1f, 2f, 3f));
    vec4 p = vec4(0, 0, 0, 1);
    auto r = T * p;
    bool pass = approxVec4(r, vec4(1f, 2f, 3f, 1));
    writeln("T003 T*origin = translated: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T004: Scale scales point
{
    mat4 S = MatrixMakeScale(vec3(2f, 3f, 4f));
    vec4 p = vec4(1, 1, 1, 1);
    auto r = S * p;
    bool pass = approxVec4(r, vec4(2f, 3f, 4f, 1));
    writeln("T004 S*(1,1,1) = scaled: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T005: Default is identity
{
    mat4 m = mat4.init;
    bool pass = MatrixIsIdentity(m);
    writeln("T005 default is identity: ", pass ? "PASS" : "FAIL");
    assert(pass);
}

unittest // T006: Row extraction
{
    mat4 m = mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    auto r0 = Row(m, 0);
    auto r1 = Row(m, 1);
    bool pass = approxVec4(r0, vec4(1, 2, 3, 4)) && approxVec4(r1, vec4(5, 6, 7, 8));
    writeln("T006 row extraction: ", pass ? "PASS" : "FAIL",
            "  row0=", r0.toString, " row1=", r1.toString);
    assert(pass);
}

unittest // T007: Column extraction
{
    mat4 m = mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    auto c0 = Col(m, 0);
    auto c1 = Col(m, 1);
    bool pass = approxVec4(c0, vec4(1, 5, 9, 13)) && approxVec4(c1, vec4(2, 6, 10, 14));
    writeln("T007 column extraction: ", pass ? "PASS" : "FAIL",
            "  col0=", c0.toString, " col1=", c1.toString);
    assert(pass);
}

unittest // T008: Identity * M = M
{
    mat4 I = MatrixMakeIdentity();
    mat4 T = MatrixMakeTranslation(vec3(5f, 6f, 7f));
    bool pass = approxMat4(I * T, T) && approxMat4(T * I, T);
    writeln("T008 identity multiply: ", pass ? "PASS" : "FAIL");
    assert(pass);
}

unittest // T009: Double transpose = original
{
    mat4 m = mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    mat4 tt = MatrixTranspose(MatrixTranspose(m));
    bool pass = approxMat4(tt, m);
    writeln("T009 double transpose: ", pass ? "PASS" : "FAIL");
    assert(pass);
}

unittest // T010: Associativity
{
    mat4 T = MatrixMakeTranslation(vec3(1f, 2f, 3f));
    mat4 S = MatrixMakeScale(vec3(2, 3, 4));
    vec4 p = vec4(1, 1, 1, 1);
    auto out1 = (T * S) * p;
    auto out2 = T * (S * p);
    bool pass = approxVec4(out1, out2);
    writeln("T010 associativity: ", pass ? "PASS" : "FAIL",
            "  (T*S)*p=", out1.toString, " T*(S*p)=", out2.toString);
    assert(pass);
}

unittest // T011: X rotation keeps x-axis
{
    mat4 Rx = MatrixMakeXRotation(1.5707963f);
    vec4 v = vec4(1, 0, 0, 1);
    auto r = Rx * v;
    bool pass = approxVec4(r, vec4(1, 0, 0, 1));
    writeln("T011 x-rot keeps x: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T012: Y rotation keeps y-axis
{
    mat4 Ry = MatrixMakeYRotation(1.5707963f);
    vec4 v = vec4(0, 1, 0, 1);
    auto r = Ry * v;
    bool pass = approxVec4(r, vec4(0, 1, 0, 1));
    writeln("T012 y-rot keeps y: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T013: Z rotation keeps z-axis
{
    mat4 Rz = MatrixMakeZRotation(1.5707963f);
    vec4 v = vec4(0, 0, 1, 1);
    auto r = Rz * v;
    bool pass = approxVec4(r, vec4(0, 0, 1, 1));
    writeln("T013 z-rot keeps z: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T014: Perspective -1 at [14]
{
    mat4 P = MatrixMakePerspective(1.0471975f, 1.0f, 0.1f, 100.0f);
    bool pass = approx(P[14], -1.0f, 1e-3f);
    writeln("T014 perspective [14]=-1: ", pass ? "PASS" : "FAIL",
            "  [14]=", P[14]);
    assert(pass);
}

unittest // T015: Scale diagonal
{
    mat4 S = MatrixMakeScale(vec3(2f, 3f, 4f));
    bool pass = approx(S[0], 2f) && approx(S[5], 3f) && approx(S[10], 4f) && approx(S[15], 1f);
    writeln("T015 scale diagonal: ", pass ? "PASS" : "FAIL",
            "  [0]=", S[0], " [5]=", S[5], " [10]=", S[10], " [15]=", S[15]);
    assert(pass);
}

unittest // T016: Translation diagonal is 1s
{
    mat4 T = MatrixMakeTranslation(vec3(99f, 88f, 77f));
    bool pass = approx(T[0], 1f) && approx(T[5], 1f) && approx(T[10], 1f) && approx(T[15], 1f);
    writeln("T016 translation diagonal 1s: ", pass ? "PASS" : "FAIL",
            "  [0]=", T[0], " [5]=", T[5], " [10]=", T[10], " [15]=", T[15]);
    assert(pass);
}

unittest // T017: T * S * point
{
    mat4 T = MatrixMakeTranslation(vec3(10f, 20f, 30f));
    mat4 S = MatrixMakeScale(vec3(2f, 2f, 2f));
    vec4 p = vec4(1, 1, 1, 1);
    auto r = (T * S) * p;
    bool pass = approxVec4(r, vec4(12f, 22f, 32f, 1));
    writeln("T017 T*S*p: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString, " expected=(12,22,32,1)");
    assert(pass);
}

unittest // T018: Composed translations
{
    mat4 T1 = MatrixMakeTranslation(vec3(1f, 0f, 0f));
    mat4 T2 = MatrixMakeTranslation(vec3(0f, 2f, 0f));
    mat4 T3 = MatrixMakeTranslation(vec3(0f, 0f, 3f));
    vec4 p = vec4(0, 0, 0, 1);
    auto r = (T1 * T2 * T3) * p;
    bool pass = approxVec4(r, vec4(1f, 2f, 3f, 1));
    writeln("T018 composed translations: ", pass ? "PASS" : "FAIL",
            "  result=", r.toString);
    assert(pass);
}

unittest // T019: Flat constructor order
{
    mat4 m = mat4(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    bool pass = true;
    for (int i = 0; i < 16; i++)
        if (!approx(m[i], cast(float)(1 + i))) pass = false;
    writeln("T019 flat constructor: ", pass ? "PASS" : "FAIL",
            "  m[0]=", m[0], " m[3]=", m[3], " m[15]=", m[15]);
    assert(pass);
}

unittest // T020: GL_TRUE transpose puts translation at [12],[13],[14]
{
    mat4 T = MatrixMakeTranslation(vec3(7f, 8f, 9f));
    mat4 Tt = MatrixTranspose(T);
    bool pass = approx(Tt[12], 7f) && approx(Tt[13], 8f) && approx(Tt[14], 9f);
    writeln("T020 GL_TRUE transpose: ", pass ? "PASS" : "FAIL",
            "  transposed [12]=", Tt[12], " [13]=", Tt[13], " [14]=", Tt[14]);
    assert(pass);
}