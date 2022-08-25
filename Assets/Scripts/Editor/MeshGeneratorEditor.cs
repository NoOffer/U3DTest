using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(CustomMeshGenerator))]
public class MeshGeneratorEditor : Editor
{
    private CustomMeshGenerator targetGenerator;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void OnEnable()
    {
        targetGenerator = (CustomMeshGenerator)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Generate Mesh"))
        {
            targetGenerator.GenerateMesh();
        }
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
}
