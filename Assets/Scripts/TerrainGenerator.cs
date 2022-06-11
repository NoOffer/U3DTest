using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
struct RandomParaSet
{
    public float maxHeightDiff;
    public float maxDepth;
    public float noiseRngScale;
    public Vector2 noiseOffset;
}

[System.Serializable]
struct ColorScheme
{
    public string regionName;
    public float maxHeight;
    public Color regionColor;
}

//[ExecuteAlways]
public class TerrainGenerator : MonoBehaviour
{
    [Header("Basic Settings")]
    [SerializeField] private float chunkSideLen;
    [SerializeField] private int meshPointPerSide;
    [SerializeField] private Vector2[] unitHorizontalChunkOffsets;
    [SerializeField] private Material meshMaterial;
    [Header("Custom Height Settings")]
    [SerializeField] private RandomParaSet[] randomParaSets;
    [SerializeField] private bool flatHorizon;
    [SerializeField] private bool radialFlatten;
    //[SerializeField] private float flattenRadPercentage;
    [SerializeField] private float flattenStart;
    [SerializeField] private float flattenRng;
    [SerializeField] private bool applyHScalerCurve;
    [SerializeField] private AnimationCurve hScalerCurve;
    [Header("Custom Color Settings")]
    [SerializeField] private ColorScheme[] colorSchemes;
    [Header("LOD Simplification")]
    [Range(1, 6)]
    [SerializeField] private int levelOfDetail;
    [Header("Update Mesh")]
    [SerializeField] private bool toUpdateMesh;
    [Header("Update PerlinNoise Seed")]
    [SerializeField] private bool toUpdateSeed;
    [SerializeField] private bool toResetSeed;
    //[Header("Test")]
    //[SerializeField] private float testVar;

    private Vector3[] vertices;
    private int[] triangles;
    //private Vector2[] meshUV;
    private Vector3[] normals;
    //private Color[] meshColors;
    private Mesh terrainMesh;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;
    // Helper variables
    private float maxPossibleH;
    private int inverseLOD;
    private Dictionary<Vector2, GameObject> meshMasters;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        //if (meshPointPerSide < 2)
        //{
        //    meshPointPerSide = 2;
        //}
        meshPointPerSide = 241;  // A number less than 255 that has enough factors;
        if (flattenRng <= 0)
        {
            flattenRng = 0.01f;
        }

        meshMasters = new Dictionary<Vector2, GameObject>();
        UpdateMesh();

        toUpdateMesh = false;
        toUpdateSeed = false;
        toResetSeed = false;
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void Update()
    {
        if (toUpdateMesh)
        {
            UpdateMesh();
            toUpdateMesh = false;
            Debug.Log("Mesh Updated");
        }
        if (toUpdateSeed)
        {
            UpdateSeed();
            UpdateMesh();
            toUpdateSeed = false;
            Debug.Log("Noise Seed Updated");
        }
        if (toResetSeed)
        {
            ResetSeed();
            UpdateMesh();
            toResetSeed = false;
            Debug.Log("Noise Seed Reset");
        }
    }

    // ----------------------------------------------------------------------------------------------------------------------------------------- Debug
    //private void OnDrawGizmos()
    //{

    //}

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    //private void RecolorColorMap()
    //{
    //    for (int i = 0; i < (meshPointPerSide - 1) / inverseLOD + 1; i++)
    //    {
    //        for (int j = 0; j < (meshPointPerSide - 1) / inverseLOD + 1; j++)
    //        {
    //            foreach (ColorScheme colorScheme in colorSchemes)
    //            {
    //                if ((vertices[i * ((meshPointPerSide - 1) / inverseLOD + 1) + j].y - transform.position.y) / maxPossibleH
    //                    <= colorScheme.maxHeight)
    //                {
    //                    meshColors[i * ((meshPointPerSide - 1) / inverseLOD + 1) + j] = colorScheme.regionColor;
    //                    break;
    //                }
    //            }
    //        }
    //    }
    //}

    private void UpdateSeed()
    {
        for (int i = 0; i < randomParaSets.Length; i++)
        {
            randomParaSets[i].noiseOffset = new Vector2(UnityEngine.Random.Range(0f, 100f), UnityEngine.Random.Range(0f, 100f));
        }
    }

    private void ResetSeed()
    {
        for (int i = 0; i < randomParaSets.Length; i++)
        {
            randomParaSets[i].noiseOffset = new Vector2(0f, 0f);
        }
    }

    private void RandomizeHeight(Vector2 unitChunkOffset)
    {
        maxPossibleH = 0f;
        for (int i = 0; i < (meshPointPerSide - 1) / inverseLOD + 1; i++)
        {
            for (int j = 0; j < (meshPointPerSide - 1) / inverseLOD + 1; j++)
            {
                // Calculate height
                float h = 0;
                float sumMaxHeightDiff = 0;
                for (int k = 0; k < randomParaSets.Length; k++)
                {
                    h += Mathf.PerlinNoise(
                        ((meshPointPerSide - 1) / inverseLOD * unitChunkOffset.x + j) * randomParaSets[k].noiseRngScale * inverseLOD
                        + randomParaSets[k].noiseOffset.x + 0.01f,
                        ((meshPointPerSide - 1) / inverseLOD * unitChunkOffset.y + i) * randomParaSets[k].noiseRngScale * inverseLOD
                        + randomParaSets[k].noiseOffset.y + 0.01f)
                        * randomParaSets[k].maxHeightDiff
                        - randomParaSets[k].maxDepth;
                    sumMaxHeightDiff += randomParaSets[k].maxHeightDiff;
                }
                
                // Height Scaling
                // Radial
                if (radialFlatten)
                {
                    float r = new Vector2(
                        j * 2f / ((meshPointPerSide - 1) / inverseLOD) - 1,
                        i * 2f / ((meshPointPerSide - 1) / inverseLOD) - 1).magnitude;
                    h *= Mathf.Cos(Mathf.Clamp01((Mathf.Clamp01(r) - Mathf.Clamp01(flattenStart)) / flattenRng) * Mathf.PI) / 2f + 0.5f;
                }
                // Scaler Curve
                if (applyHScalerCurve)
                {
                    h = hScalerCurve.Evaluate(h / sumMaxHeightDiff) * sumMaxHeightDiff;
                }

                // Record max H over the map
                if (h > maxPossibleH)
                {
                    maxPossibleH = h;
                }
                
                // Flatten the horizon
                if (flatHorizon)
                {
                    h = Mathf.Clamp(h, 0, Mathf.Infinity);
                }

                vertices[i * ((meshPointPerSide - 1) / inverseLOD + 1) + j].y = meshMasters[unitChunkOffset].transform.position.y + h;
            }
        }

        //RecolorColorMap();
    }

    private void UpdateMesh()
    {
        // Delete unwanted chunk
        foreach (Vector2 chunkOffset in meshMasters.Keys)
        {
            if (Array.IndexOf(unitHorizontalChunkOffsets, chunkOffset) < 0)
            {
                Destroy(meshMasters[chunkOffset]);
            }
        }
        // Add new chunk(s)
        foreach (Vector2 chunkOffset in unitHorizontalChunkOffsets)
        {
            if (!meshMasters.ContainsKey(chunkOffset))
            {
                meshMasters[chunkOffset] = new GameObject();
                meshMasters[chunkOffset].transform.position = transform.position + new Vector3(
                    chunkOffset.x,
                    0f,
                    chunkOffset.y) * chunkSideLen;
                meshMasters[chunkOffset].transform.parent = transform;
                meshMasters[chunkOffset].AddComponent<MeshFilter>();
                meshMasters[chunkOffset].AddComponent<MeshRenderer>();
            }

            meshFilter = meshMasters[chunkOffset].GetComponent<MeshFilter>();
            meshRenderer = meshMasters[chunkOffset].GetComponent<MeshRenderer>();
            meshRenderer.material = meshMaterial;
            
            inverseLOD = (7 - levelOfDetail) * 2;

            terrainMesh = new Mesh();
            terrainMesh.name = "Generated Mesh at " + chunkOffset;
            vertices = new Vector3[(int)Mathf.Pow((meshPointPerSide - 1) / inverseLOD + 1, 2)];
            triangles = new int[(int)Mathf.Pow((meshPointPerSide - 1) / inverseLOD, 2) * 6];
            //meshUV = new Vector2[(int)Mathf.Pow((meshPointPerSide - 1) / inverseLOD + 1, 2)];
            normals = new Vector3[(int)Mathf.Pow((meshPointPerSide - 1) / inverseLOD + 1, 2)];
            //meshColors = new Color[(int)Mathf.Pow((meshPointPerSide - 1) / inverseLOD + 1, 2)];

            // Set vertices
            for (int i = 0; i < (meshPointPerSide - 1) / inverseLOD + 1; i++)  // Row
            {
                for (int j = 0; j < (meshPointPerSide - 1) / inverseLOD + 1; j++)  // Column
                {
                    vertices[i * ((meshPointPerSide - 1) / inverseLOD + 1) + j] = new Vector3(
                        chunkSideLen * j / ((meshPointPerSide - 1) / inverseLOD) - chunkSideLen / 2,
                        0,
                        chunkSideLen * i / ((meshPointPerSide - 1) / inverseLOD) - chunkSideLen / 2);
                    //meshUV[i * ((meshPointPerSide - 1) / inverseLOD + 1) + j] = new Vector2(
                    //    (float)j / ((meshPointPerSide - 1) / inverseLOD),
                    //    (float)i / ((meshPointPerSide - 1) / inverseLOD));
                }
            }
            RandomizeHeight(chunkOffset);

            // Set triangles
            for (int i = 0; i < (meshPointPerSide - 1) / inverseLOD; i++)  // Row
            {
                for (int j = 0; j < (meshPointPerSide - 1) / inverseLOD; j++)  // Column
                {
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 0] = i * ((meshPointPerSide - 1) / inverseLOD + 1) + j;
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 1] = (i + 1) * ((meshPointPerSide - 1) / inverseLOD + 1) + j;
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 2] = i * ((meshPointPerSide - 1) / inverseLOD + 1) + j + 1;
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 3] = i * ((meshPointPerSide - 1) / inverseLOD + 1) + j + 1;
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 4] = (i + 1) * ((meshPointPerSide - 1) / inverseLOD + 1) + j;
                    triangles[(i * (meshPointPerSide - 1) / inverseLOD + j) * 6 + 5] = (i + 1) * ((meshPointPerSide - 1) / inverseLOD + 1) + j + 1;
                }
            }

            // Calculate normals
            for (int i = 0; i < normals.Length; i++)
            {
                normals[i] = Vector3.zero;
            }
            for (int i = 0; i < triangles.Length / 3; i++)
            {
                Vector3 vertexA = vertices[triangles[i * 3]];
                Vector3 vertexB = vertices[triangles[i * 3 + 1]];
                Vector3 vertexC = vertices[triangles[i * 3 + 2]];
                Vector3 triangleNormal = Vector3.Cross(vertexB - vertexA, vertexC - vertexA).normalized;
                normals[triangles[i * 3]] += triangleNormal;
                normals[triangles[i * 3 + 1]] += triangleNormal;
                normals[triangles[i * 3 + 2]] += triangleNormal;
            }
            for (int i = 0; i < normals.Length; i++)
            {
                normals[i] = normals[i].normalized;
            }

            // Update mesh
            terrainMesh.vertices = vertices;
            terrainMesh.triangles = triangles;
            //terrainMesh.uv = meshUV;
            terrainMesh.normals = normals;

            //// Update Color
            //Texture2D tex2D = new Texture2D((meshPointPerSide - 1) / inverseLOD + 1, (meshPointPerSide - 1) / inverseLOD + 1);
            //tex2D.filterMode = FilterMode.Point;
            //tex2D.SetPixels(meshColors);
            //tex2D.Apply();

            ////texRenderer.transform.localScale = new Vector3(meshPointPerSide, 1, meshPointPerSide);
            //texRenderer.material.mainTexture = tex2D;

            // Apply mesh
            meshFilter.mesh = terrainMesh;
        }
    }
}
