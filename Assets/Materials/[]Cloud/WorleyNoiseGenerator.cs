using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorleyNoiseGenerator : MonoBehaviour
{
    [SerializeField] private ComputeShader worleyNoiseCompute;
    [SerializeField] private int numOfCellPerAxis;

    [SerializeField] private RenderTexture targetRT;
    [SerializeField] private Material cloudImgEffectMat;

    [SerializeField] private bool manualUpdate;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        if (targetRT == null)
        {
            targetRT = new RenderTexture(100, 100, 0);
            targetRT.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            targetRT.volumeDepth = 100;
            targetRT.enableRandomWrite = true;
            targetRT.wrapMode = TextureWrapMode.Repeat;
            targetRT.Create();
        }
        worleyNoiseCompute.SetTexture(0, "Result", targetRT);
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void LateUpdate()
    {
        if (manualUpdate)
        {
            CreatWorleyPointsData("Points");

            worleyNoiseCompute.Dispatch(0, targetRT.width / 10, targetRT.height / 10, targetRT.volumeDepth / 10);
            cloudImgEffectMat.SetTexture("_CloudNoise", targetRT);

            manualUpdate = false;
        }        
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    private void CreatWorleyPointsData(string bufferName)
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

        worleyNoiseCompute.SetInt("numPerSide", numOfCellPerAxis);
        SetUpBuffer(points, sizeof(float) * 3, bufferName);
    }

    private void SetUpBuffer(Vector3[] data, int stride, string bufferName, int kernel = 0)
    {
        ComputeBuffer buffer = new ComputeBuffer(data.Length, stride, ComputeBufferType.Raw);
        buffer.SetData(data);
        worleyNoiseCompute.SetBuffer(kernel, bufferName, buffer);
    }
}
