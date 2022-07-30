using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(CityGenerator))]
public class CityEditor : Editor
{
    private CityGenerator targetGenerator;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void OnEnable()
    {
        targetGenerator = (CityGenerator)target;
    }

    public override void OnInspectorGUI()
    {
        //base.OnInspectorGUI();

        targetGenerator.cityDimensions.x = EditorGUILayout.Slider(targetGenerator.cityDimensions.x, 10f, 100f);
        targetGenerator.cityDimensions.y = EditorGUILayout.Slider(targetGenerator.cityDimensions.y, 10f, 100f);
        targetGenerator.cityDimensions.z = EditorGUILayout.Slider(targetGenerator.cityDimensions.z, 10f, 100f);
    }
}
