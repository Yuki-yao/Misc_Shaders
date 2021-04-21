using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Please attach this script to FrostGlass GameObject
public class GaussianBlur : PostEffectBase
{
    public Shader blurShader;
    private Material blurMaterial;
    public Material material {
        get {
            blurMaterial = CheckShaderAndCreateMaterial(blurShader, blurMaterial);
            return blurMaterial;
        }
    }

    [Range(0.0f, 3.0f)]
    public float blurSize = 1.0f;

    private Dictionary<Camera, CommandBuffer> camBufferDict = new Dictionary<Camera, CommandBuffer>();

    private void OnWillRenderObject() {
        if(!(gameObject.activeInHierarchy && enabled)) {
            Cleanup();
        }
        Camera cam = Camera.current;
        if(!cam) return;
        if(camBufferDict.ContainsKey(cam)) return;

        CommandBuffer buf = new CommandBuffer();
        buf.name = "Grab and blur";
        camBufferDict[cam] = buf;

        int scrCopyID = Shader.PropertyToID("_GrabScreen");
        buf.GetTemporaryRT(scrCopyID, -1, -1, 0, FilterMode.Bilinear);
        buf.Blit(BuiltinRenderTextureType.CurrentActive, scrCopyID);

        int downSample = 1;
        material.SetFloat("_BlurSize", blurSize);
        for(int i = 1; i < 5; ++i) {
            downSample *= 2;

            int blurID01 = Shader.PropertyToID("_BlurTemp01");
            int blurID02 = Shader.PropertyToID("_BlurTemp02");
            buf.GetTemporaryRT(blurID01, -downSample, -downSample, 0, FilterMode.Bilinear);
            buf.GetTemporaryRT(blurID02, -downSample, -downSample, 0, FilterMode.Bilinear);

            buf.Blit(scrCopyID, blurID01);
            buf.Blit(blurID01, blurID02, material, 0);
            buf.Blit(blurID02, blurID01, material, 1);

            buf.SetGlobalTexture("_GrabBlurScreen0" + i, blurID01);
            buf.ReleaseTemporaryRT(blurID01);
            buf.ReleaseTemporaryRT(blurID02);
        }
        buf.SetGlobalTexture("_GrabBlurScreen00", scrCopyID);
        buf.ReleaseTemporaryRT(scrCopyID);

        cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, buf);
    }

    private void Cleanup() {
        foreach(var cam in camBufferDict) {
            if(cam.Key) {
                cam.Key.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, cam.Value);
            }
        }
        camBufferDict.Clear();
        DestroyImmediate(material);
    }

    private void OnEnable() {
        Cleanup();
    }

    private void OnDisable() {
        Cleanup();
    }
}
