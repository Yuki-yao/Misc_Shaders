using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Please attach this script to Main Camera
public class SceneScan : PostEffectBase
{
    public Shader sceneScanShader;
    private Material sceneScanMaterial;
    public Material material {
        get {
            sceneScanMaterial = CheckShaderAndCreateMaterial(sceneScanShader, sceneScanMaterial);
            return sceneScanMaterial;
        }
    }
    private Camera myCamera;
    public Camera _camera {
        get {
            if(myCamera == null)
                myCamera = GetComponent<Camera>();
            return myCamera;
        }
    }

    public Color scanColor;
    [Range(0.0f, 10.0f)]
    public float scanSpeed;

    private void OnEnable() {
        _camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if(material != null) {
            material.SetColor("_ScanColor", scanColor);
            material.SetFloat("_ScanSpeed", scanSpeed);
            Graphics.Blit(src, dest, material);
        }
        else {
            Graphics.Blit(src, dest);
        }
    }
}
