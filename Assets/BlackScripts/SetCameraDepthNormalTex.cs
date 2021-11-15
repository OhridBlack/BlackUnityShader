using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class SetCameraDepthNormalTex : MonoBehaviour
{
    private void Start()
    {
        this.GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
    }
}
