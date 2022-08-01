using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class WorleyNoiseGenerator : MonoBehaviour
{
    [SerializeField] private ComputeShader worleyNoiseCompute;
    [SerializeField] private int numOfCellPerAxis_A;
    [SerializeField] private int numOfCellPerAxis_B;

    [Range(10f, 1024f)]
    [SerializeField] private int resolution;
    [SerializeField] private RenderTexture targetRT_A;
    [SerializeField] private RenderTexture targetRT_B;

    [SerializeField] private Material cloudImgEffectMat;
    [SerializeField] private Material rtDisplayMat;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        GenerateWorley();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    public void GenerateWorley()
    {
        // Initialize Texture A
        targetRT_A = InitializeRT();
        worleyNoiseCompute.SetTexture(0, "ResultTexA", targetRT_A);
        // Create Texture
        SetUpWorleyCompute(numOfCellPerAxis_A);

        // Initialize Texture B
        targetRT_B = InitializeRT();
        worleyNoiseCompute.SetTexture(0, "ResultTexA", targetRT_B);
        // Create Texture
        SetUpWorleyCompute(numOfCellPerAxis_B);

        //// Blend Both Textures
        //worleyNoiseCompute.SetTexture(1, "ResultTexA", targetRT_A);
        //worleyNoiseCompute.SetTexture(1, "ResultTexB", targetRT_B);
        //worleyNoiseCompute.Dispatch(1, resolution / 10, resolution / 10, resolution / 10);

        // Assign Textures
        cloudImgEffectMat.SetTexture("_CloudTex", targetRT_A);
        if (rtDisplayMat != null)
        {
            rtDisplayMat.SetTexture("_MainTex", targetRT_A);
        }
    }

    private RenderTexture InitializeRT()
    {
        RenderTexture targetRT = new RenderTexture(resolution, resolution, 0);
        targetRT.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        targetRT.volumeDepth = resolution;
        targetRT.enableRandomWrite = true;
        targetRT.wrapMode = TextureWrapMode.Repeat;
        targetRT.Create();
        return targetRT;
    }

    private void SetUpWorleyCompute(int numOfCellPerAxis)
    {
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
}
