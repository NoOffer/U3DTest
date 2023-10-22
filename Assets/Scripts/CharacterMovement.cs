using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class CharacterMovement : MonoBehaviour
{
    public static CharacterMovement instance;

    [SerializeField] private Transform targetCamTransform;
    [Header("Move Speed")]
    [SerializeField] private float horizontalSpeed;
    [Header("Jump Force")]
    [SerializeField] private float jumpSpeed;
    [Header("Gravity Settings")]
    [SerializeField] private float gravity;
    [SerializeField] private float extraGravity;
    [SerializeField] private float coyoteTime;
    [Header("Ground Check Settings")]
    [SerializeField] private Vector3 groundCheckOffset;
    [SerializeField] private float groundCheckR;
    [SerializeField] private LayerMask whatIsGround;

    private CharacterController characterController;

    private float verticalSpeed;
    private float jumpKeyDownT;
    private bool grounded;

    // Start is called before the first frame update
    void Start()
    {
        if (instance == null)
        {
            instance = this;
        }

        characterController = GetComponent<CharacterController>();

        verticalSpeed = 0f;
        jumpKeyDownT = -coyoteTime - 1f;
        grounded = false;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space)) jumpKeyDownT = Time.time;
    }

    private void FixedUpdate()
    {
        transform.rotation = Quaternion.Euler(0, targetCamTransform.rotation.eulerAngles.y, 0);

        Vector3 movementVec =
            (transform.right * Input.GetAxisRaw("Horizontal") + transform.forward * Input.GetAxisRaw("Vertical")).normalized;
        characterController.Move(movementVec * horizontalSpeed * Time.fixedDeltaTime);

        grounded = Physics.CheckSphere(transform.position + groundCheckOffset, groundCheckR, whatIsGround);
        if (grounded)
        {
            if (Time.time < jumpKeyDownT + coyoteTime) verticalSpeed = jumpSpeed;
        }
        else
        {
            verticalSpeed += gravity * Time.fixedDeltaTime;
            if (!Input.GetKey(KeyCode.Space)) verticalSpeed += extraGravity * Time.fixedDeltaTime;
        }

        characterController.Move(Vector3.up * verticalSpeed * Time.fixedDeltaTime);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = grounded ? Color.green : Color.red;

        Gizmos.DrawWireSphere(transform.position + groundCheckOffset, groundCheckR);
    }
}
