using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class NormalProcessor : MonoBehaviour
{
    struct NormalInfo
    {
        public Vector3 pos;
        public Vector3 dir;
    }

    [SerializeField] private Mesh targetMesh;
    [SerializeField] private float sizeMultiplier = 1.0f;
    [SerializeField] private Color gizmosColor;
    [Min(0)]
    [SerializeField] private float lineLenMultiplier = 1.0f;

    private List<NormalInfo> normalCache;

    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(
            "Triangle: " + targetMesh.triangles.Length / 3 +
            " Vertices: " + targetMesh.vertices.Length +
            " Normals: " + targetMesh.normals.Length +
            " UVs: " + targetMesh.uv.Length
            );

        GetComponent<MeshFilter>().mesh = targetMesh;

        transform.localScale = Vector3.one * sizeMultiplier;

        normalCache = new List<NormalInfo>();

        UpdateNormal();
    }

    // Update is called once per frame
    void Update()
    {
        transform.localScale = Vector3.one * sizeMultiplier;
    }

    public void UpdateNormal()
    {
        if (targetMesh == null)
        {
            return;
        }

        //Dictionary<Vector3, List<Vector3>> normalDict = averagingNormal();

        normalCache.Clear();
        for (int i = 0; i < targetMesh.normals.Length; i++)
        {
            Matrix4x4 transformMat = transform.localToWorldMatrix;
            Vector3 vertexPos = targetMesh.vertices[i];

            NormalInfo n = new NormalInfo();
            n.dir = transformMat.MultiplyVector(targetMesh.normals[i]);
            //n.dir = transformMat.MultiplyVector(normalDict[vertexPos][0]).normalized;
            n.pos = transformMat.MultiplyPoint(vertexPos);
            normalCache.Add(n);
        }
    }

    public void averageNormal()
    {
        if (targetMesh == null)
        {
            return;
        }

        int[] triangles = targetMesh.triangles;
        Vector3[] vertices = targetMesh.vertices;

        Dictionary<Vector3, List<Vector3>> normalDict = new Dictionary<Vector3, List<Vector3>>();

        for (int i = 0; i < triangles.Length; i += 3)
        {
            Vector3 a = vertices[triangles[i + 1]] - vertices[triangles[i]];
            Vector3 b = vertices[triangles[i + 2]] - vertices[triangles[i]];
            Vector3 faceNormal = Vector3.Cross(a, b);

            for (int j = 0; j < 3; j++)
            {
                if (normalDict.ContainsKey(vertices[triangles[i + j]]))
                {
                    normalDict[vertices[triangles[i + j]]].Add(faceNormal);
                }
                else
                {
                    normalDict.Add(vertices[triangles[i + j]], new List<Vector3> { faceNormal });
                }
            }
        }

        foreach (Vector3 idx in normalDict.Keys)
        {
            Vector3 avgNormal = Vector3.zero;
            foreach (Vector3 n in normalDict[idx])
            {
                avgNormal += n;
            }
            avgNormal /= normalDict[idx].Count;
            normalDict[idx][0] = avgNormal;
        }

        Vector3[] avgNormals = targetMesh.normals;
        for (int i = 0; i < vertices.Length; i++)
        {
            avgNormals[i] = normalDict[vertices[i]][0];
        }
        //targetMesh.normals = avgNormals;
        targetMesh.SetUVs(1, avgNormals);
    }

    private void OnDrawGizmos()
    {
        if (normalCache == null || normalCache.Count < 1)
        {
            return;
        }

        Gizmos.color = gizmosColor;

        for (int i = 0; i < normalCache.Count; i++)
        {
            Gizmos.DrawRay(normalCache[i].pos, normalCache[i].dir * lineLenMultiplier);
        }
    }
}
