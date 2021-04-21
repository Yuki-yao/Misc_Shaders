Shader "PostEffect/Bloom"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
        _LuminaceThreshold ("Luminance Threshold", Float) = 0.5
        _Bloom ("Bloom (RGB)", 2D) = "black" {}
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminaceThreshold;
        float _BlurSize;

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
        };

        v2f vertExtract (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed4 fragExtract (v2f i) : SV_Target
        {
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = clamp(Luminance(c.rgb) - _LuminaceThreshold, 0.0, 1.0);
            return c * val;
        }

        struct v2fBloom {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        v2fBloom vertBloom(appdata_img v) {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0) {
                o.uv.w = 1 - o.uv.w;
            }
            #endif

            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_TARGET {
            float3 worldPos = mul(unity_ObjectToWorld, i.pos);
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw) * (sin(_Time.y*4 + worldPos.x * 0.005)*2);
        }

        ENDCG

        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vertExtract
            #pragma fragment fragExtract
            ENDCG
        }

        UsePass "PostEffect/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "PostEffect/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

        Pass {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    Fallback Off
}
