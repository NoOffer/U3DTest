using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayMarchingMaster : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private Camera virtualCam;
    [SerializeField] private RenderTexture targetRT;
    [SerializeField] private Material displayMat;

    //[SerializeField] private bool toRender;

    // -------------------------------------------------------------------------------------------------------------------------------- Initialization
    void Awake()
    {
        if (virtualCam == null)
        {
            virtualCam = Camera.main;
        }

        if (targetRT == null)
        {
            targetRT = new RenderTexture(Screen.width, Screen.height, 24);
            targetRT.enableRandomWrite = true;
            targetRT.Create();
        }
    }

    // --------------------------------------------------------------------------------------------------------------------------------------- Updates
    void Update()
    {
        computeShader.SetMatrix("_CameraToWorld", virtualCam.cameraToWorldMatrix);
        computeShader.SetMatrix("_CameraInverseProjection", virtualCam.projectionMatrix.inverse);
        computeShader.SetTexture(0, "Result", targetRT);
        computeShader.Dispatch(0, targetRT.width / 8, targetRT.height / 8, 1);

        displayMat.mainTexture = targetRT;
    }

    // ---------------------------------------------------------------------------------------------------------------------------- Featured Functions
}
