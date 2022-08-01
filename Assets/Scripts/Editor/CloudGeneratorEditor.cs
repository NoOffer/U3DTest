using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(WorleyNoiseGenerator))]
public class CloudGeneratorEditor : Editor
{
    private WorleyNoiseGenerator targetGenerator;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void OnEnable()
    {
        targetGenerator = (WorleyNoiseGenerator)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Generate Worley Noise"))
        {
            targetGenerator.GenerateWorley();
        }
    }
}
