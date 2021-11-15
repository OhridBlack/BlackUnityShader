using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class SetCameraTranslating : MonoBehaviour
{
    private Camera myCamera;
    private Transform lookAt;
    private Vector3 up;

    public float r;
    public GameObject gameObjectLookedAt;

    private void Start()
    {
        myCamera = GetComponent<Camera>();
        lookAt = gameObjectLookedAt.transform;
        up = new Vector3(0, 1, 0);
        myCamera.transform.LookAt(lookAt, up);
        r = 5;
    }

    private void Update()
    {
        float theta =Time.time;
        float phi=Time.time;
        float x = r * Mathf.Cos(theta) * Mathf.Cos(phi)+lookAt.position.x;
        float y = r * Mathf.Cos(theta) * Mathf.Sin(phi)+lookAt.position.y;
        float z = r * Mathf.Sin(theta)+lookAt.position.z;
        myCamera.transform.position = new Vector3(x, y, z);
        myCamera.transform.LookAt(lookAt, up);
    }
}
