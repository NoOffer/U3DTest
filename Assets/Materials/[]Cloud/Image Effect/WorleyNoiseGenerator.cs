using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorleyNoiseGenerator : MonoBehaviour
{
    [SerializeField] private ComputeShader worleyNoiseCompute;
    [SerializeField] private int numOfCellPerAxis;

    [Range(10f, 1024f)]
    [SerializeField] private int resolution;
    [SerializeField] private RenderTexture targetRT;

    [SerializeField] private Material cloudImgEffectMat;
    [SerializeField] private Material rtDisplayMat;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        //GenerateWorley();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    private void InitializeRT()
    {
        targetRT = new RenderTexture(resolution, resolution, 0);
        targetRT.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        targetRT.volumeDepth = resolution;
        targetRT.enableRandomWrite = true;
        targetRT.wrapMode = TextureWrapMode.Repeat;
        targetRT.Create();
    }

    public void GenerateWorley()
    {
        // Initialize Texture A
        InitializeRT();
        worleyNoiseCompute.SetTexture(0, "ResultTex", targetRT);
        // Create Texture
        SetUpWorleyCompute(numOfCellPerAxis);

        // Assign Textures
        cloudImgEffectMat.SetTexture("_CloudTex", targetRT);
        if (rtDisplayMat != null)
        {
            rtDisplayMat.SetTexture("_NoiseTex", targetRT);
        }
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
