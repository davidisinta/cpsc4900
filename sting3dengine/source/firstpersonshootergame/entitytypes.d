/// Data-driven entity type definitions
/// Each type describes what model, physics, material, and scale an entity uses

module entitytypes;

import linear;

struct EntityType
{
    string name;
    string modelPath;
    string urdfPath;       // null if no physics
    string texturePath;    // null if using basic material
    float scale;
    float yOffset;         // raise above ground
    bool hasPhysics;
    int maxSubmeshes = 0;  // 0 = use all meshes


    static EntityType soldier()
    {
        EntityType t;
        t.name = "soldier";
        t.modelPath = "./assets/modern_soldier/scene.gltf";
        t.urdfPath = "soldier.urdf";
        t.texturePath = "soldier";  // key into material registry
        t.scale = 1.0f;
        t.yOffset = 1.0f;
        t.hasPhysics = true;
        return t;
    }

    static EntityType lindenTree()
    {
        EntityType t;
        t.name = "linden";
        t.modelPath = "./assets/4-linden-trees-pack-medium-poly/import_1/linden.obj";
        t.urdfPath = null;
        t.texturePath = "linden";
        t.scale = 1.0f;
        t.yOffset = 0.0f;
        t.hasPhysics = false;
        t.maxSubmeshes = 1;  // only use first mesh
        return t;
    }

    static EntityType bunny()
    {
        EntityType t;
        t.name = "bunny";
        t.modelPath = "./assets/meshes/bunny_centered.obj";
        t.urdfPath = "cube.urdf";
        t.texturePath = null;  // uses basic material
        t.scale = 1.0f;
        t.yOffset = 0.0f;
        t.hasPhysics = true;
        return t;
    }
}
