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

public class TerrainGenerator : MonoBehaviour
{
    [Header("Basic Settings")]
    [SerializeField] private float sideLen;
    [SerializeField] private int meshPointPerSide;
    [Header("Custom Settings")]
    [SerializeField] private RandomParaSet[] randomParaSets;
    [SerializeField] private bool flattenOnEdge;
    //[SerializeField] private float flattenRadPercentage;
    [SerializeField] private float flattenStart;
    [SerializeField] private float flattenRng;
    [Header("Update Mesh")]
    [SerializeField] private bool toUpdateMesh;
    [Header("Update PerlinNoise Seed")]
    [SerializeField] private bool toUpdateSeed;

    private Vector3[] vertices;
    private int[] triangles;
    private Mesh terrainMesh;
    private MeshFilter meshFilter;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        if (meshPointPerSide < 2)
        {
            meshPointPerSide = 2;
        }
        if (flattenRng <= 0)
        {
            flattenRng = 0.01f;
        }

        vertices = new Vector3[meshPointPerSide * meshPointPerSide];
        triangles = new int[(meshPointPerSide - 1) * (meshPointPerSide - 1) * 6];
        terrainMesh = new Mesh();
        meshFilter = GetComponent<MeshFilter>();
        UpdateMesh();

        toUpdateMesh = false;
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void Update()
    {
        if (toUpdateMesh)
        {
            UpdateMesh();
            toUpdateMesh = false;
        }
        if (toUpdateSeed)
        {
            UpdateSeed();
            UpdateMesh();
            toUpdateSeed = false;
        }
    }

    // ----------------------------------------------------------------------------------------------------------------------------------------- Debug
    //private void OnDrawGizmos()
    //{

    //}

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    private void UpdateSeed()
    {
        for (int i = 0; i < randomParaSets.Length; i++)
        {
            randomParaSets[i].noiseOffset = new Vector2(Random.Range(0f, 100f), Random.Range(0f, 100f));
        }
    }

    private void RandomizeHeight()
    {
        for (int i = 0; i < meshPointPerSide; i++)
        {
            for (int j = 0; j < meshPointPerSide; j++)
            {
                float h = 0;
                for (int k = 0; k < randomParaSets.Length; k++)
                {
                    h += Mathf.PerlinNoise(
                        j * randomParaSets[k].noiseRngScale + randomParaSets[k].noiseOffset.x + 0.1f,
                        i * randomParaSets[k].noiseRngScale + randomParaSets[k].noiseOffset.y + 0.1f) * randomParaSets[k].maxHeightDiff
                        - randomParaSets[k].maxDepth;
                }
                
                if (flattenOnEdge)
                {
                    float r = new Vector2(j * 2f / (meshPointPerSide - 1) - 1, i * 2f / (meshPointPerSide - 1) - 1).magnitude;
                    h *= Mathf.Cos(Mathf.Clamp01((Mathf.Clamp01(r) - Mathf.Clamp01(flattenStart)) / flattenRng) * Mathf.PI) / 2f + 0.5f;
                }

                vertices[i * meshPointPerSide + j].y = transform.position.y + h;
            }
        }
    }

    private void UpdateMesh()
    {
        // Set vertices
        for (int i = 0; i < meshPointPerSide; i++)  // Row
        {
            for (int j = 0; j < meshPointPerSide; j++)  // Column
            {
                vertices[i * meshPointPerSide + j] = new Vector3(transform.position.x + sideLen / meshPointPerSide * j - sideLen / 2,
                    0,
                    transform.position.z + sideLen / meshPointPerSide * i - sideLen / 2);
            }
        }
        RandomizeHeight();

        // Set triangles
        for (int i = 0; i < meshPointPerSide - 1; i++)  // Row
        {
            for (int j = 0; j < meshPointPerSide - 1; j++)  // Column
            {
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 0] = i * meshPointPerSide + j;
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 1] = (i + 1) * meshPointPerSide + j;
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 2] = i * meshPointPerSide + j + 1;
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 3] = i * meshPointPerSide + j + 1;
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 4] = (i + 1) * meshPointPerSide + j;
                triangles[(i * (meshPointPerSide - 1) + j) * 6 + 5] = (i + 1) * meshPointPerSide + j + 1;
            }
        }
        
        // Update mesh
        terrainMesh.vertices = vertices;
        terrainMesh.triangles = triangles;

        // Apply mesh
        meshFilter.mesh = terrainMesh;
    }
}
