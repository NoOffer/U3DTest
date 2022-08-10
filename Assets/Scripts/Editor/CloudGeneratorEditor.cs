using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

//[CustomEditor(typeof(WorleyNoiseGenerator))]
[CustomEditor(typeof(CloudMeshGenerator))]
public class CloudGeneratorEditor : Editor
{
    //private WorleyNoiseGenerator targetGenerator;
    private CloudMeshGenerator targetGenerator;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void OnEnable()
    {
        //targetGenerator = (WorleyNoiseGenerator)target;
        targetGenerator = (CloudMeshGenerator)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        //if (GUILayout.Button("Generate Worley Noise"))
        //{
        //    targetGenerator.GenerateWorley();
        //}

        if (GUILayout.Button("Generate Cloud Mesh"))
        {
            targetGenerator.GenerateCloudMesh();
        }
    }
}
