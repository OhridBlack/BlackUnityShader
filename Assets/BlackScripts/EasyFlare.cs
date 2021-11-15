using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class EasyFlare : PostEffectsBase
{
    public Shader easyFlareShader;
    private Material easyFlareMaterial;

    [Range(1, 8)]
    public int downSample = 2;

    [Range(1, 5)]
    public int ghostIterations = 2;

    [Range(0.0f, 1.0f)]
    public float ghostDispersal = 0.1f;

    [Range(1.0f, 10.0f)]
    public float intensity = 2.0f;

    public Color threshold = new Color(0.9f, 0.9f, 0.9f, 1.0f);

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            material.SetColor("_Threshold", threshold);
            material.SetFloat("_Intensity", intensity);
            material.SetInt("_GhostIterations", ghostIterations);
            material.SetFloat("_GhostDispersal", ghostDispersal);
            Graphics.Blit(source, buffer0, material, 0);


            Graphics.Blit(buffer0, destination,material,1);
            RenderTexture.ReleaseTemporary(buffer0);
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
            easyFlareMaterial = CheckShaderAndCreateMaterial(easyFlareShader, easyFlareMaterial);
            return easyFlareMaterial;
        }
    }
}
