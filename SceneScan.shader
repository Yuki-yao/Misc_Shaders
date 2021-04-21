Shader "PostEffect/SceneScan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanColor ("Scan Color", Color) = (1, 1, 1, 1)
        _ScanSpeed ("Scan Speed", Float) = 0.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        fixed4 _ScanColor;
        float _ScanSpeed;

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float2 uv_depth : TEXCOORD1;
            float4 pos : SV_POSITION;
        };

        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            float linearDepth = LinearEyeDepth(depth);
            float power = 1 - saturate(abs((_Time.y * 5 - linearDepth) % 30) * 2);
            fixed4 baseTex = tex2D(_MainTex, i.uv);
            return lerp(baseTex, _ScanColor, power);
        }
        ENDCG

        Pass
        {
            // No culling or depth
            Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
    Fallback Off
}
