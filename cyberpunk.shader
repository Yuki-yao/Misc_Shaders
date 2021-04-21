Shader "PostScreen/cyberpunk"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Power ("Power", Float) = 0.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Power;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 baseTex = tex2D(_MainTex, i.uv);
                float3 xyz = baseTex.rgb;
                float oldx = xyz.x;
                float oldy = xyz.y;
                float addxy = abs(oldx - oldy) * 0.5;
                float stepxy = step(oldy, oldx);
                float stepyx = 1 - stepxy;

                xyz.x = stepxy * (oldx + addxy) + stepyx * (oldx - addxy);
                xyz.y = stepxy * (oldy - addxy) + stepyx * (oldy + addxy);
                xyz.z = sqrt(xyz.z);

                fixed4 col = fixed4(lerp(baseTex.rgb, xyz, _Power), baseTex.a);
                return col;
            }
            ENDCG
        }
    }
    Fallback Off
}
