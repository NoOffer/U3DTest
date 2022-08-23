using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
struct NoiseParaSet
{
    public float maxHeightDiff;
    public float maxDepth;
    public float noiseTiling;
    public Vector2 noiseOffset;
}
[System.Serializable]
struct HeightMapParaSet
{
    public Texture2D heightMap;
    public float noiseScaler;
    public float maxHeightDiff;
    public float maxDepth;
}

//[ExecuteAlways]
public class TerrainGenerator : MonoBehaviour
{
    [Header("Basic Settings")]
    [SerializeField] private float chunkSideLen;
    [SerializeField] private int meshPointPerSide;
    [SerializeField] private Material meshMaterial;
    [Header("Custom Height Settings")]
    [SerializeField] private bool useNoise;
    [SerializeField] private NoiseParaSet[] randomParaSets;
    [SerializeField] private HeightMapParaSet heightMapParaSet;
    [SerializeField] private ComputeShader hMapSamplerCompute;
    //[Header("LOD Simplification")]
    //[Range(1, 6)]
    //[SerializeField] private int levelOfDetail;
    [Header("Erosion Simulation Settings")]
    [SerializeField] private bool toErode;
    [Min(1000)]
    [SerializeField] private int iterationCount;
    [Min(10)]
    [SerializeField] private int dropLifeTime;
    [SerializeField] private ComputeShader erosionCompute;

    // Terrain data
    private Vector3[] vertices;
    private int[] triangles;
    private Vector3[] normals;

    // Mesh components
    private Mesh terrainMesh;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        UpdateMesh();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates

    // ----------------------------------------------------------------------------------------------------------------------------------------- Debug

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions

    public void UpdateSeed()
    {
        for (int i = 0; i < randomParaSets.Length; i++)
        {
            randomParaSets[i].noiseOffset = new Vector2(UnityEngine.Random.Range(0f, 100f), UnityEngine.Random.Range(0f, 100f));
        }
    }

    public void ResetSeed()
    {
        for (int i = 0; i < randomParaSets.Length; i++)
        {
            randomParaSets[i].noiseOffset = new Vector2(0f, 0f);
        }
    }

    public void UpdateMesh()
    {
        if (toErode)
        {
            iterationCount = iterationCount / 100 * 100;
        }

        // Initialization
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();
        meshRenderer.material = meshMaterial;

        terrainMesh = new Mesh();
        terrainMesh.name = "Terrain Mesh";
        vertices = new Vector3[meshPointPerSide * meshPointPerSide];
        triangles = new int[(meshPointPerSide - 1) * (meshPointPerSide - 1) * 6];
        normals = new Vector3[meshPointPerSide * meshPointPerSide];

        // Set vertices
        for (int i = 0; i < meshPointPerSide; i++)  // Row
        {
            for (int j = 0; j < meshPointPerSide; j++)  // Column
            {
                vertices[i * meshPointPerSide + j] = new Vector3(
                    chunkSideLen * ((float)j / (meshPointPerSide - 1) - 0.5f),
                    0,
                    chunkSideLen * ((float)i / (meshPointPerSide - 1) - 0.5f)
                    );
            }
        }
        // Height setting
        if (useNoise)
        {
            RandomizeHNoise();
        }
        else
        {
            RandomizeHMap();
        }
        if (toErode)
        {
            Erode();
        }

        // Set triangles
        for (int i = 0; i < meshPointPerSide - 1; i++)  // Row
        {
            for (int j = 0; j < meshPointPerSide - 1; j++)  // Column
            {
                // The first tiangle
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 0] = i * meshPointPerSide + j;  // Consider this the origin (Left bottom)
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 1] = (i + 1) * meshPointPerSide + j;  // Above the origin
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 2] = i * meshPointPerSide + j + 1;  // To the right of the origin
                // The second triangle
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 3] = i * meshPointPerSide + j + 1;  // To the right of the origin
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 4] = (i + 1) * meshPointPerSide + j;  // Above the origin
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 5] = (i + 1) * meshPointPerSide + j + 1;  // Upper right of the origin
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
        terrainMesh.normals = normals;

        // Apply mesh
        meshFilter.mesh = terrainMesh;
    }

    private void RandomizeHNoise()
    {
        for (int i = 0; i < meshPointPerSide; i++)
        {
            for (int j = 0; j < meshPointPerSide; j++)
            {
                // Calculate height
                float h = 0;
                for (int k = 0; k < randomParaSets.Length; k++)
                {
                    h += Mathf.PerlinNoise(
                        (float)j / (meshPointPerSide - 1) * randomParaSets[k].noiseTiling + randomParaSets[k].noiseOffset.x,
                        (float)i / (meshPointPerSide - 1) * randomParaSets[k].noiseTiling + randomParaSets[k].noiseOffset.y
                        );
                    //h = 1 - Mathf.Abs(h * 2 - 1);
                    h = h * randomParaSets[k].maxHeightDiff - randomParaSets[k].maxDepth;
                }

                vertices[i * meshPointPerSide + j].y = transform.position.y + h;
            }
        }
    }

    private void RandomizeHMap()
    {
        ComputeBuffer heightBuffer = new ComputeBuffer(meshPointPerSide * meshPointPerSide, sizeof(float) * 3);
        heightBuffer.SetData(vertices);
        hMapSamplerCompute.SetTexture(0, "HeightMap", heightMapParaSet.heightMap);
        hMapSamplerCompute.SetFloat("noiseScaler", heightMapParaSet.noiseScaler);
        hMapSamplerCompute.SetBuffer(0, "Pos", heightBuffer);
        hMapSamplerCompute.SetInt("meshPointsPerSide", meshPointPerSide);
        hMapSamplerCompute.Dispatch(0, meshPointPerSide / 10, meshPointPerSide / 10, 1);
        heightBuffer.GetData(vertices);
        heightBuffer.Dispose();

        for (int i = 0; i < meshPointPerSide * meshPointPerSide; i++)
        {
            vertices[i].y = vertices[i].y * heightMapParaSet.maxHeightDiff - heightMapParaSet.maxDepth;
        }
    }

    private void Erode()
    {
        ComputeBuffer heightBuffer = new ComputeBuffer(meshPointPerSide * meshPointPerSide, sizeof(float) * 3);
        heightBuffer.SetData(vertices);
        erosionCompute.SetBuffer(0, "Pos", heightBuffer);
        erosionCompute.SetInt("meshPointsPerSide", meshPointPerSide);
        erosionCompute.SetInt("dropLifeTime", dropLifeTime);
        erosionCompute.Dispatch(0, iterationCount / 100, iterationCount / 100, 1);
        heightBuffer.GetData(vertices);
        heightBuffer.Dispose();
    }
}
