using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerMovement3D : MonoBehaviour
{
    public float speed = 20;
    private Vector3 motion;
    private Rigidbody rb;
    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        motion = new Vector3(Input.GetAxisRaw("Horizontal"), Convert.ToInt32(Input.GetButton("Jump")), Input.GetAxisRaw("Vertical"));
        rb.velocity = motion * speed;
    }
}
