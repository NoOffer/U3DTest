using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderTest : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private RenderTexture renderTex;
    [SerializeField] private Material targetMat;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        if (renderTex == null)
        {
            renderTex = new RenderTexture(256, 256, 24);
            renderTex.enableRandomWrite = true;
            renderTex.Create();
        }

        computeShader.SetTexture(0, "Result", renderTex);
        computeShader.Dispatch(0, renderTex.width / 8, renderTex.height / 8, 1);

        targetMat.mainTexture = renderTex;
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    //void Update()
    //{

    //}

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
}
