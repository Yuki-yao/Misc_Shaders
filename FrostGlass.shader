Shader "Unlit/FrostGlass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Opaque" "LightMode"="Always" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GrabBlurScreen00;
            float4 _GrabBlurScreen00_TexelSize;
            sampler2D _GrabBlurScreen01;
            sampler2D _GrabBlurScreen02;
            sampler2D _GrabBlurScreen03;
            sampler2D _GrabBlurScreen04;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 uvgrab : TEXCOORD0;
                half2 uvMain : TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvgrab = ComputeGrabScreenPos(o.pos);
                #if UNITY_UV_STARTS_AT_TOP
                if(_GrabBlurScreen00_TexelSize.y < 0)
                    o.uvgrab.y = (1 - o.uvgrab.y) * o.uvgrab.w;
                #endif

                o.uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col0 = tex2Dproj(_GrabBlurScreen00, UNITY_PROJ_COORD(i.uvgrab));
                fixed4 col1 = tex2Dproj(_GrabBlurScreen01, UNITY_PROJ_COORD(i.uvgrab));
                fixed4 col2 = tex2Dproj(_GrabBlurScreen02, UNITY_PROJ_COORD(i.uvgrab));
                fixed4 col3 = tex2Dproj(_GrabBlurScreen03, UNITY_PROJ_COORD(i.uvgrab));
                fixed4 col4 = tex2Dproj(_GrabBlurScreen04, UNITY_PROJ_COORD(i.uvgrab));

                fixed dirt = tex2D(_MainTex, i.uvMain).r;
                float weight0 = smoothstep(0.0, 0.25, dirt);
                float weight1 = smoothstep(0.25, 0.5, dirt);
                float weight2 = smoothstep(0.5, 0.95, dirt);
                float weight3 = smoothstep(0.95, 1, dirt);

                return lerp(lerp(lerp(lerp(col0, col1, weight0), col2, weight1), col3, weight2), col4, weight3) * fixed4(0.9, 0.8, 1, 1);
            }
            ENDCG
        }
    }
}
