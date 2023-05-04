using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(NormalProcessor))]
public class NormalProcessorEditor : Editor
{
    private NormalProcessor targetProcessor;

    private void OnEnable()
    {
        targetProcessor = (NormalProcessor)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Update Normal"))
        {
            targetProcessor.UpdateNormal();
        }

        if (GUILayout.Button("Average Normal"))
        {
            targetProcessor.averageNormal();
            targetProcessor.UpdateNormal();
        }
    }
}
