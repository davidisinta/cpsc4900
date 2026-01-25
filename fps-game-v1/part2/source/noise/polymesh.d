module polymesh;

//standard library
import std.stdio;
import std.file;

//project libraries
import linear;

class PolyMesh {
    public:
        vec3[] vertices;
        vec2[] st;
        vec3[] normals;
        uint[] faceArray;
        uint[] verticesArray;
        uint numVertices;
        uint numFaces;

    this() {}

    /// Method to export to .obj file
    void exportToObj() {

        // Open file for writing
        File file = File("./polymesh.obj", "w");

        // Write vertices to the file
        foreach (vertex; vertices) {
            file.writeln("v ", vertex.x, " ", vertex.y, " ", vertex.z);
        }

        // Write texture coordinates to the file
        foreach (texture; st) {
            file.writeln("vt ", texture.x, " ", texture.y);
        }

        // Write normals to the file
        foreach (normal; normals) {
            file.writeln("vn ", normal.x, " ", normal.y, " ", normal.z);
        }

        uint k = 0;
        for(uint i = 0; i < numFaces; i++){
            file.write("f ");
            for(uint j = 0; j < faceArray[i]; ++j){
                uint objIndex = verticesArray[k + j] + 1;
                file.write(objIndex, "/", objIndex, "/", objIndex);
                if(j != (faceArray[i] - 1)){
                    file.write(" ");
                }
            }
            file.writeln();
            k += faceArray[i];
        }

        file.close(); // Close the file
    }
}

// Function to create a subdivided planar mesh
PolyMesh createPolyMesh(
    uint width = 1,
    uint height = 1,
    uint subdivisionWidth = 40,
    uint subdivisionHeight = 40)
{
    // Allocate memory for PolyMesh instance
    auto poly = new PolyMesh();

    // Calculate total number of vertices: (subdivs + 1) in each direction
    poly.numVertices = (subdivisionWidth + 1) * (subdivisionHeight + 1);
    writeln("Number of vertices: ", poly.numVertices);

    // Allocate arrays to hold vertex positions, normals, and texture coordinates
    poly.vertices = new vec3[](poly.numVertices);
    poly.normals = new vec3[](poly.numVertices);
    poly.st = new vec2[](poly.numVertices);

    // Inverses used for UVs and vertex spacing
    float invSubdivisionWidth = 1.0f / subdivisionWidth;
    float invSubdivisionHeight = 1.0f / subdivisionHeight;

    // Generate vertex positions and texture coordinates
    for (uint j = 0; j <= subdivisionHeight; ++j) {
        for (uint i = 0; i <= subdivisionWidth; ++i) {
            // Calculate index into the flat vertex array
            uint idx = j * (subdivisionWidth + 1) + i;

            // X and Z coordinates scaled between -0.5 and 0.5 of width/height
            float x = width * (i * invSubdivisionWidth - 0.5f);
            float z = height * (j * invSubdivisionHeight - 0.5f);
            poly.vertices[idx] = vec3(x, 0.0f, z);

            // UV coordinates (st)
            poly.st[idx] = vec2(i * invSubdivisionWidth, j * invSubdivisionHeight);
        }
    }

    // Each face is a quad (4 vertices), so total number of faces
    poly.numFaces = subdivisionWidth * subdivisionHeight;

    // Allocate face array and set all faces to 4 vertices each
    poly.faceArray = new uint[](poly.numFaces);
    foreach (i; 0 .. poly.numFaces) {
        poly.faceArray[i] = 4;
    }

    // Allocate vertex indices for each face (4 per face)
    poly.verticesArray = new uint[](4 * poly.numFaces);

    // Fill the face indices
    uint k = 0; // Running index for verticesArray
    for (uint j = 0; j < subdivisionHeight; ++j) {
        for (uint i = 0; i < subdivisionWidth; ++i) {
            // Calculate vertex indices of the quad
            poly.verticesArray[k]     = j * (subdivisionWidth + 1) + i;
            poly.verticesArray[k + 1] = j * (subdivisionWidth + 1) + i + 1;
            poly.verticesArray[k + 2] = (j + 1) * (subdivisionWidth + 1) + i + 1;
            poly.verticesArray[k + 3] = (j + 1) * (subdivisionWidth + 1) + i;
            k += 4;
        }
    }

    return poly;
}
