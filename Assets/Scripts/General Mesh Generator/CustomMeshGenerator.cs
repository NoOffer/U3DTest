using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomMeshGenerator : MonoBehaviour
{
    [SerializeField] private Vector3 meshCenter;
    [Min(1)]
    [SerializeField] private Vector2 meshDimensions;
    [Min(2)]
    [SerializeField] private Vector2 meshPointsPerSide;
    [SerializeField] private Material meshMaterial;

    private Vector3[] vertices;
    private int[] triangles;
    private Vector3[] normals;

    private Mesh resultMesh;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void Update()
    {
        
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
    public void GenerateMesh()
    {
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();

        GeneratePlane();

        meshFilter.mesh = resultMesh;
        meshRenderer.material = meshMaterial;
    }

    private void GeneratePlane()
    {
        resultMesh = new Mesh();
        resultMesh.name = "Custom Plane";

        vertices = new Vector3[(int)meshPointsPerSide.x * (int)meshPointsPerSide.y];
        triangles = new int[((int)meshPointsPerSide.x - 1) * ((int)meshPointsPerSide.y - 1) * 6];
        normals = new Vector3[(int)meshPointsPerSide.x * (int)meshPointsPerSide.y];

        // Setup vertices
        for (int i = 0; i < meshPointsPerSide.x; i++)
        {
            for (int j = 0; j < meshPointsPerSide.y; j++)
            {
                vertices[i * (int)meshPointsPerSide.y + j] = new Vector3(
                    ((float)i / (meshPointsPerSide.x - 1) - 0.5f) * meshDimensions.x + meshCenter.x,
                    meshCenter.y,
                    ((float)j / (meshPointsPerSide.y - 1) - 0.5f) * meshDimensions.y + meshCenter.z
                    );
            }
        }

        // Setup triangles
        for (int i = 0;i < meshPointsPerSide.x - 1; i++)
        {
            for (int j = 0;j < meshPointsPerSide.y -1; j++)
            {
                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 0] = i * (int)meshPointsPerSide.y + j;
                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 1] = i * (int)meshPointsPerSide.y + j + 1;
                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 2] = (i + 1) * (int)meshPointsPerSide.y + j;

                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 3] = i * (int)meshPointsPerSide.y + j + 1;
                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 4] = (i + 1) * (int)meshPointsPerSide.y + j + 1;
                triangles[(i * ((int)meshPointsPerSide.y - 1) + j) * 6 + 5] = (i + 1) * (int)meshPointsPerSide.y + j;
            }
        }

        // Setup normals
        for (int i = 0; i < meshPointsPerSide.x; i++)
        {
            for (int j = 0; j < meshPointsPerSide.y; j++)
            {
                normals[i * (int)meshPointsPerSide.y + j] = Vector3.up;
            }
        }

        resultMesh.vertices = vertices;
        resultMesh.triangles = triangles;
        resultMesh.normals = normals;
    }
}
