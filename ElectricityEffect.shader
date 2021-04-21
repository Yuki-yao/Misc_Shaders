Shader "Unlit/ElectricityEffect"
{
    Properties
    {
		_Color ("Main Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_Bump ("Bump", 2D) = "white" {}
		_BumpScale ("Bump Scale", Float) = 0.0
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
        _HalfLambert ("Half Lambert Lighting", Range(0, 1)) = 0

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _MoveSpeed ("Move Speed", Range(0.2, 2)) = 0.5
        _ElectricityColor ("Electricity Color", Color) = (1, 1, 1, 1)
        _SmoothThreshold("Smooth Threshold", Range(0.0, 0.01)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGINCLUDE
        #include "UnityCG.cginc"

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
        };

        sampler2D _NoiseTex;
        float4 _NoiseTex_ST;
        float _MoveSpeed;
        fixed4 _ElectricityColor;
        float _SmoothThreshold;

        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            half2 uv1 = half2(i.uv.x, i.uv.y + _Time.y * _MoveSpeed);
            half2 uv2 = half2(i.uv.x + _Time.y * _MoveSpeed * 0.97, i.uv.y - _Time.y * _MoveSpeed * 1.35);
            float noise = (tex2D(_NoiseTex, uv1).r + tex2D(_NoiseTex, uv2).r) * 0.5;
            float poweredNoise = pow(noise, 1.5);
            float remappedNoise = poweredNoise * 20 - 10;

            float val = fwidth(saturate(remappedNoise));
            float w = fwidth(val) * 2;
            val = val * smoothstep(-w, w, val-_SmoothThreshold);
            return fixed4(_ElectricityColor.rgb, val);
        }
        ENDCG

        UsePass "Common/MyBumpSpecular/MYBUMPSPEC_FWDBASE"
        UsePass "Common/MyBumpSpecular/MYBUMPSPEC_FWDADD"

        Pass
        {
            Tags {"Queue" = "Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    Fallback "Specular"
}
