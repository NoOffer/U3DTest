using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorleyNoiseGenerator : MonoBehaviour
{
    [SerializeField] private ComputeShader worleyNoiseCompute;
    [SerializeField] private int numOfCellPerAxis_A;
    [SerializeField] private int numOfCellPerAxis_B;

    [Range(10f, 300f)]
    [SerializeField] private int resolution;
    [SerializeField] private RenderTexture targetRT_A;
    [SerializeField] private RenderTexture targetRT_B;
    [Range(0, 1)]
    [SerializeField] private float blendFactor;

    [SerializeField] private Material cloudImgEffectMat;
    [SerializeField] private Material rtDisplayMat;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        //GenerateWorley();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    private void InitializeRT(ref RenderTexture targetRT)
    {
        targetRT = new RenderTexture(resolution, resolution, 0);
        targetRT.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        targetRT.volumeDepth = resolution;
        targetRT.enableRandomWrite = true;
        targetRT.wrapMode = TextureWrapMode.Repeat;
        targetRT.Create();
    }

    private void SetUpWorleyCompute(int numOfCellPerAxis, RenderTexture targetRT)
    {
        worleyNoiseCompute.SetTexture(0, "ResultTex", targetRT);

        Vector3[] points = new Vector3[numOfCellPerAxis * numOfCellPerAxis * numOfCellPerAxis];

        for (int i = 0; i < numOfCellPerAxis; i++)
        {
            for (int j = 0; j < numOfCellPerAxis; j++)
            {
                for (int k = 0; k < numOfCellPerAxis; k++)
                {
                    //Vector3 pos = (new Vector3(i, j, k) + new Vector3(Random.value, Random.value, Random.value)) / numOfCellPerAxis;
                    Vector3 pos = new Vector3(Random.value, Random.value, Random.value);
                    points[k + numOfCellPerAxis * (j + numOfCellPerAxis * i)] = pos;
                }
            }
        }

        worleyNoiseCompute.SetInt("pointsPerSide", numOfCellPerAxis);

        ComputeBuffer pointsBuffer = new ComputeBuffer(points.Length, sizeof(float) * 3, ComputeBufferType.Raw);
        pointsBuffer.SetData(points);
        worleyNoiseCompute.SetBuffer(0, "Points", pointsBuffer);

        worleyNoiseCompute.Dispatch(0, resolution / 10, resolution / 10, resolution / 10);
        pointsBuffer.Dispose();
    }

    public void GenerateWorley()
    {
        // Initialize Texture
        InitializeRT(ref targetRT_A);
        InitializeRT(ref targetRT_B);
        // Create Texture
        SetUpWorleyCompute(numOfCellPerAxis_A, targetRT_A);
        SetUpWorleyCompute(numOfCellPerAxis_B, targetRT_B);

        // Blend
        worleyNoiseCompute.SetTexture(1, "ResultTex", targetRT_A);
        worleyNoiseCompute.SetTexture(1, "InputTex", targetRT_B);
        worleyNoiseCompute.SetFloat("blendFactor", blendFactor);
        worleyNoiseCompute.Dispatch(1, resolution / 10, resolution / 10, resolution / 10);

        // Assign Textures
        cloudImgEffectMat.SetTexture("_CloudTex", targetRT_A);
        if (rtDisplayMat != null)
        {
            rtDisplayMat.SetTexture("_MainTex", targetRT_A);
        }
    }
}
