using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudMeshGenerator : MonoBehaviour
{
    [Min(0)]
    [SerializeField] private int layerCount;
    [SerializeField] private Mesh duplicatedMesh;
    [SerializeField] private Material cloudMat;
    [SerializeField] private Vector3 startPos;
    [Min(0.01f)]
    [SerializeField] private Vector3 CloudScale;

    private Matrix4x4[] matrice;
    private MaterialPropertyBlock mpb;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {

    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    private void LateUpdate()
    {
        GenerateCloudMesh();
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    public void GenerateCloudMesh()
    {
        layerCount = Mathf.Max(2, layerCount);
        cloudMat.SetFloat("_CloudStartH", startPos.y);
        cloudMat.SetFloat("_CloudHeight", CloudScale.y);
        matrice = new Matrix4x4[layerCount];
        mpb = new MaterialPropertyBlock();

        for (int i = 0; i < layerCount; i++)
        {
            matrice[i] = Matrix4x4.TRS(
                startPos + Vector3.up * CloudScale.y * ((float)i / (float)(layerCount - 1) - 0.5f),
                transform.localRotation,
                new Vector3(CloudScale.x, 1, CloudScale.z)
                );
        }
        Graphics.DrawMeshInstanced(duplicatedMesh, 0, cloudMat, matrice, layerCount, mpb, UnityEngine.Rendering.ShadowCastingMode.TwoSided, true);
    }
}
