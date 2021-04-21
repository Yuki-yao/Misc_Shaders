using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Please attach this script to Main Camera
public class Bloom : PostEffectBase
{
    public Shader bloomShader;
    private Material bloomMaterial;
    public Material material {
        get {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0.0f, 3.0f)]
    public float blurSize = 1.0f;
    [Range(1, 8)]
    public int downSample = 2;
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;


    private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if(material != null) {
            material.SetFloat("_BlurSize", blurSize);
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            int dsWidth = src.width / downSample;
            int dsHeight = src.height / downSample;
            RenderTexture buffer01 = RenderTexture.GetTemporary(dsWidth, dsHeight, 0);
            buffer01.filterMode = FilterMode.Bilinear;
            RenderTexture buffer02 = RenderTexture.GetTemporary(dsWidth, dsHeight, 0);

            Graphics.Blit(src, buffer01, material, 0);

            Graphics.Blit(buffer01, buffer02, material, 1);
            Graphics.Blit(buffer02, buffer01, material, 2);

            material.SetTexture("_Bloom", buffer01);
            Graphics.Blit(src, dest, material, 3);
            RenderTexture.ReleaseTemporary(buffer01);
            RenderTexture.ReleaseTemporary(buffer02);
        }
        else {
            Graphics.Blit(src, dest);
        }
    }
}
