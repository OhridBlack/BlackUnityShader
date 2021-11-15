using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/
[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
///<summary>
///
///</summary>
public class PostEffectsBase : MonoBehaviour
{   protected bool checkSupport()
    {
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            print("This platform does not support image effects and render textures!");
            return false;
        }
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected void checkResources()
    {
        bool isSupported = checkSupport();
        if (isSupported == false)
        {
            NotSupported();
        }
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader,Material material)
    {
        if (shader == null) return null;
        if (shader.isSupported && material && material.shader == shader) return material;
        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material) return material;
            else return null;
        }

    }

    protected void Start()
    {
        checkResources();
    }
}
