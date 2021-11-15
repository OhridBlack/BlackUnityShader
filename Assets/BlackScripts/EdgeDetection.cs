using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDectShader;
    private Material edgeDectMaterial;

    [Range(0.0f, 1.0f)]
    public float edgeOnly = 0.0f;

    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

    public Material material
    {
        get
        {
            edgeDectMaterial = CheckShaderAndCreateMaterial(edgeDectShader, edgeDectMaterial);
            return edgeDectMaterial;
        }
    }
}
