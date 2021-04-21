using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Please attach this script to Main Camera
public class cyberpunk : PostEffectBase
{
    public Shader cyberpunkShader;
    private Material cyberpunkMaterial;
    public Material material {
        get {
            cyberpunkMaterial = CheckShaderAndCreateMaterial(cyberpunkShader, cyberpunkMaterial);
            return cyberpunkMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float power = 0.0f;

    private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if(material != null) {
            material.SetFloat("_Power", power);
            Graphics.Blit(src, dest, material);
        }
        else {
            Graphics.Blit(src, dest);
        }
    }
}
