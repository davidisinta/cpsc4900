/// Centralized material creation and lookup
/// Avoids duplicate material setup scattered across files

module materialregistry;

import std.stdio;
import enginecore;
import materials;
import linear;

class MaterialRegistry
{
    Camera mCamera;

    IMaterial[string] mMaterials;

    vec3 mFogColor;
    float mFogStart;
    float mFogEnd;

    this(Camera cam)
    {
        mCamera = cam;
        mFogColor = vec3(0.55f, 0.68f, 0.78f);
        mFogStart = 80.0f;
        mFogEnd = 180.0f;
    }

    void setup()
    {
        setupBasic();
        setupLitTextured();
        setupSoldierMaterial();
        setupLindenMaterial();
        setupMapMaterial();
        setupTerrainMaterial();
        setupMeshesMaterial();
        writeln("[materials] all materials registered");
    }

    IMaterial get(string name)
    {
        if (auto mat = name in mMaterials)
            return *mat;
        writeln("[materials] WARNING: material '", name, "' not found, using basic");
        return mMaterials["basic"];
    }

    private void setupBasic()
    {
        Pipeline basicPipeline = new Pipeline("basic",
            "./pipelines/basic/basic.vert",
            "./pipelines/basic/basic.frag");

        IMaterial mat = new BasicMaterial("basic");
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mMaterials["basic"] = mat;
    }

    private void setupLitTextured()
    {
        Pipeline litTexPipeline = new Pipeline("lit_textured",
            "./pipelines/lit_textured/lit_textured.vert",
            "./pipelines/lit_textured/lit_textured.frag");
    }

    private void setupSoldierMaterial()
    {
        IMaterial mat = new LitTexturedMaterial("lit_textured",
            "./assets/modern_soldier/textures/material_0_baseColor.jpeg");
        mat.AddUniform(new Uniform("uTexture", 0));
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uFogColor", "vec3", &mFogColor));
        mat.AddUniform(new Uniform("uFogStart", mFogStart));
        mat.AddUniform(new Uniform("uFogEnd", mFogEnd));
        mMaterials["soldier"] = mat;
    }

    private void setupLindenMaterial()
    {
        IMaterial mat = new LitTexturedMaterial("lit_textured",
            "./assets/4-linden-trees-pack-medium-poly/import_1/nature_bark_linden_04_m_0001.jpg");
        mat.AddUniform(new Uniform("uTexture", 0));
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mMaterials["linden"] = mat;
    }

    private void setupMapMaterial()
    {
        IMaterial mat = new LitTexturedMaterial("lit_textured",
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png");
        mat.AddUniform(new Uniform("uTexture", 0));
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mMaterials["map"] = mat;
    }

    // private void setupMeshesMaterial()
    // {
    //     IMaterial mat = new LitTexturedMaterial("lit_textured",
    //         "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png");

    //     // uploads_files_3151797_FPS_Modular_Map_Kit_Map/FPS_Modular_Map_BaseColor.png
    //     mat.AddUniform(new Uniform("uTexture", 0));
    //     mat.AddUniform(new Uniform("uModel", "mat4", null));
    //     mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
    //     mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
    //     mMaterials["meshes"] = mat;
    // }

    private void setupMeshesMaterial()
    {
        IMaterial mat = new LitTexturedMaterial("lit_textured",
            "./assets/fps_map_kit/uploads_files_3151797_FPS_Modular_Map_Kit_FBX/Meshes.png");
        mat.AddUniform(new Uniform("uTexture", 0));
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mMaterials["meshes"] = mat;
    }


    private void setupTerrainMaterial()
    {
        Pipeline simpleTexPipeline = new Pipeline("textured_simple",
            "./pipelines/textured_simple/textured_simple.vert",
            "./pipelines/textured_simple/textured_simple.frag");

        IMaterial mat = new LitTexturedMaterial("textured_simple",
            "./assets/textures/green-grass-background.jpg");
        mat.AddUniform(new Uniform("uTexture", 0));
        mat.AddUniform(new Uniform("uModel", "mat4", null));
        mat.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
        mat.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));
        mMaterials["terrain"] = mat;
    }
}