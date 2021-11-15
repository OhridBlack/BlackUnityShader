using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
Created by BlackFJ
*/

///<summary>
///
///</summary>
public class MotionBlur : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial;

    [Range(0.0f, 0.9f)]
    public float blurAmount;

    private RenderTexture accumulationTexture;

    private void OnDestroy()
    {
        DestroyImmediate(accumulationTexture);
    }

    public void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
        {
            if(accumulationTexture==null || accumulationTexture.width != source.width || accumulationTexture.height != source.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(source.width, source.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(source, accumulationTexture);
            }
            accumulationTexture.MarkRestoreExpected();//make accumulationTexture restore

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);
            Graphics.Blit(source, accumulationTexture, material);//add source to accumulationTexture
            Graphics.Blit(accumulationTexture, destination);
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
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }
}
