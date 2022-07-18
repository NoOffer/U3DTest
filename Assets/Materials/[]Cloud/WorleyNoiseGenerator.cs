using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorleyNoiseGenerator : MonoBehaviour
{
    [SerializeField] private ComputeShader worleyNoiseCompute;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void Update()
    {
        
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    void CreatWorleyPointsData(int numOfCellPerAxis, string bufferName)
    {
        Vector3[] points = new Vector3[numOfCellPerAxis * numOfCellPerAxis * numOfCellPerAxis];

        for (int i = 0; i < numOfCellPerAxis; i++)
        {
            for (int j = 0; j < numOfCellPerAxis; j++)
            {
                for (int k = 0; k < numOfCellPerAxis; k++)
                {
                    Vector3 pos = (new Vector3(i, j, k) + new Vector3(Random.value, Random.value, Random.value)) / numOfCellPerAxis;
                    points[k + numOfCellPerAxis * (j + numOfCellPerAxis * i)] = pos;
                }
            }
        }
        CreateBuffer(points, sizeof(float) * 3, bufferName);
    }

    void CreateBuffer(Vector3[] data, int stride, string bufferName, int kernel = 0)
    {
        ComputeBuffer buffer = new ComputeBuffer(data.Length, stride, ComputeBufferType.Raw);
        buffer.SetData(data);
        worleyNoiseCompute.SetBuffer(kernel, bufferName, buffer);
    }
}
