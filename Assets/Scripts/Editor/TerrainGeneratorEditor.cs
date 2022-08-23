using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TerrainGenerator))]
public class TerrainGeneratorEditor : Editor
{
    private TerrainGenerator targetGenerator;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void OnEnable()
    {
        targetGenerator = (TerrainGenerator)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Randomize Seed"))
        {
            targetGenerator.UpdateSeed();
        }

        if (GUILayout.Button("Reset Seed"))
        {
            targetGenerator.ResetSeed();
        }

        if (GUILayout.Button("Update Mesh"))
        {
            targetGenerator.UpdateMesh();
        }
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
}
