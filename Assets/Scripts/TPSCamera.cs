using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TPSCamera : MonoBehaviour
{
    public GameObject target;
    public Vector3 camPosOffset;
    public LayerMask physicalCamCheckMask;
    public float mouseSensitivity;
    public float adsSensitivity;
    public float maxElevationAngle;
    public float usualPOV;
    public float adsPOV;
    //public float minADSScale;
    //public float maxADSScale;

    private float camDis;
    private Vector3 relativeCamDir;
    private RaycastHit physicalCamCheckHit;

    // Start is called before the first frame update
    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;

        maxElevationAngle = -Mathf.Sin(maxElevationAngle * Mathf.PI / 180f);
        camDis = (transform.position - target.transform.position - camPosOffset).magnitude;
        relativeCamDir = (transform.position - target.transform.position - camPosOffset).normalized;
    }

    private void FixedUpdate()
    {
        // Move Camera
        transform.position = Vector3.Lerp(transform.position, GetTargetPos(), 0.5f);
    }

    // Update is called once per frame
    void Update()
    {
        // Adjust zoom level
        if (Input.GetMouseButton(1)) // ADS
        {
            Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, adsPOV, 0.1f);
            AdjustDirection(adsSensitivity);  // Direction Calculation
        }
        else  // Non-ADS
        {
            Camera.main.fieldOfView = Mathf.Lerp(Camera.main.fieldOfView, usualPOV, 0.1f);
            AdjustDirection(mouseSensitivity);  // Direction Calculation
        }
    }

    private Vector3 RotateAroundY(Vector3 original, float theta)
    {
        original.x = original.x * Mathf.Cos(theta) - original.z * Mathf.Sin(theta);
        original.z = original.z * Mathf.Cos(theta) + original.x * Mathf.Sin(theta);
        return original;
    }

    private void AdjustDirection(float sensitivity)
    {
        relativeCamDir = RotateAroundY(relativeCamDir, -Input.GetAxis("Mouse X") * sensitivity);
        relativeCamDir.y = Mathf.Clamp(relativeCamDir.y - Input.GetAxis("Mouse Y") * sensitivity, maxElevationAngle, Mathf.Infinity);
        relativeCamDir = relativeCamDir.normalized;

        transform.Rotate(Vector3.up, Input.GetAxis("Mouse X") * sensitivity * 180 / Mathf.PI, Space.World);
        transform.Rotate(transform.right, -Input.GetAxis("Mouse Y") * sensitivity * 180 / Mathf.PI, Space.World);
    }

    private Vector3 GetTargetPos()
    {
        if (Physics.Raycast(target.transform.position + camPosOffset,
            relativeCamDir,
            out physicalCamCheckHit,
            camDis,
            physicalCamCheckMask))
        {
            return physicalCamCheckHit.point;
        }
        else
        {
            return target.transform.position + camPosOffset + camDis * relativeCamDir;
        }
    }
}
