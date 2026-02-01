/// OBJ File Creation
module objgeometry;

import bindbc.opengl;
import geometry;
import error;

//standard library files
import std.stdio;
import std.file;
import std.algorithm;
import std.conv;
import std.array;

/// Geometry stores all of the vertices and/or indices for a 3D object.
/// Geometry also has the responsibility of setting up the 'attributes'
class SurfaceOBJ : ISurface{
    GLuint mVBO;
    GLuint mIBO;
    GLfloat[] mVertexData; // all data for a vertex, coordinates + normal
	GLfloat[] mNormalData;
    GLfloat[] mVertexCoordinatesData;
	GLfloat[] mTextureData;
    GLuint[] mIndexData;
    
    size_t mTriangles;

    /// Geometry data
    this(string filename){
        MakeOBJ(filename);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawElements(GL_TRIANGLES,cast(GLuint)mIndexData.length,GL_UNSIGNED_INT,null);
    }

    void MakeOBJ(string filepath){

        //beginning of my update
        if(exists(filepath)){
            File file = File(filepath);
        
            int i = 1;
            auto range = file.byLine();
            foreach (ln; range){
                string line = ln.to!string;

                //place vertices in vertices array
                if(line.startsWith("vn")){
                    //get the 3 numbers that represent color
                    string[] positions = line.split();
                    float r = positions[1].to!float;
                    float g = positions[2].to!float;
                    float b = positions[3].to!float;

                    //add 3 positions to vertices normal data
                    mNormalData ~= r;
                    mNormalData ~= g;
                    mNormalData ~= b;
                } else if(line.startsWith("v")){
                    //  writeln("processing vs");
                    //get the 3 numbers that represent 3d coordinates
                    string[] positions = line.split();
                    float x = positions[1].to!float;
                    float y = positions[2].to!float;
                    float z = positions[3].to!float;

                    //add 3 positions to vertices data
                    mVertexCoordinatesData ~= x;
                    mVertexCoordinatesData ~= y;
                    mVertexCoordinatesData ~= z;

                //place normals in normals array
                } else if(line.startsWith("f")){
                    //we process a face of our object such that

                    //for each face we have 3 vertices
                    // fist get the indices of the 3 coordinates
                    //then we have 3 locations for the colors
        
                    //get the 6 numbers that represent a face
                    string[] faceData = line.split();
                    GLuint[3] tempCoordinates;
                    GLuint[3] tempColors;

                    //loop through the 3 elements in face data and decompose
                    int k = 0;
                    for(int g = 1; g < faceData.length; g++){
                        string currData = faceData[g];
                        
                        //split each element based on the // delimeter
                        // vertices come in form 1//3
                        //where 1 is coordinate
                        //3 is color
                        string[] values = currData.split("//");
                        int vPos = values[0].to!int;
                        int vnPos = values[1].to!int;

                        //shift all values back by 1 because obj files are 1 indexed
                        vPos--;
                        vnPos--;

                        //get coordinates using v pos
                        GLfloat[] currCoordinates = getGroup(mVertexCoordinatesData, vPos, 3);
        
                        //get color using vn pos
                        GLfloat[] currColor = getGroup(mNormalData, vnPos, 3);

                        // writeln("coords len: ", currCoordinates.length, " color len: ", currColor.length, "vn pos: ", vnPos, "col size", mVertexNormalData.length);

                        //pack them into one array size 6
                        GLfloat[] resultantVertex = currCoordinates ~ currColor;
                        // writeln("-----------------------------------------------");

                        //check, mVertexData[] if there is a
                        //row with exact 6 vals
                        // if yes get indx, update mIndexData
                        //if not add it to interimVeritces
                        //update indx data

                        int currVertexIndex = cast(int) findOrAddGroup(mVertexData, resultantVertex);
                        mIndexData ~= currVertexIndex;
                    }
                }
                i++;
            }
        }

        //debugging
        // foreach(int x; mIndexData){
        //     write(x, ", ");
        // }

        //store number of triangles making up the object
        mTriangles = mIndexData.length/3;
		
        // Vertex Arrays Object (VAO) Setup
        //Every class that implements Isurface has a mVAO
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) 
        // that we want to work withn.
        glBindVertexArray(mVAO);

        // Index Buffer Object (IBO)
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndexData.length* GLuint.sizeof, mIndexData.ptr, GL_STATIC_DRAW);

        // Vertex Buffer Object (VBO) creation
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, mVertexData.length* VertexFormat3F3F.sizeof, mVertexData.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);
        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F3F();
    }
}

GLfloat[] getGroup(GLfloat[] data, int index, int groupSize) {
    int start = index * groupSize;
    if (start + groupSize < data.length) {
        return data[start..start + groupSize];
    }
    return []; 
}

// Function to find or add group g in the larger array and return the index
ulong findOrAddGroup(ref GLfloat[] largerArray, GLfloat[] g) {
    // Ensure the size of g is 6
    if (g.length != 6) {
        writeln("The group must have exactly 6 elements.");
        return -1;
    }

    //loop through larger array in batches of 6
    for (int i = 0; i + 6 <= largerArray.length; i += 6) {
        // Extract a group of 6 elements from largerArray
        auto group = largerArray[i..i + 6];

        // Check if the current group matches the group g
        if (group == g) {
            return i / 6;
        }
    }
	
    // If no match is found, add g to the end of the larger array
    largerArray ~= g;
    return (largerArray.length / 6 - 1);
}
