Shader "Unlit/Water"
{
    Properties
    {
        _Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _WaveMap ("Wave Map", 2D) = "bump" {}
        _CubeMap ("Environment CubeMap", Cube) = "_Skybox" {}
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
        _Distortion ("Distortion", Range(0, 100)) = 10
        _WaveAmplitude ("Wave Amplitude", Range(0.01, 10.0)) = 1
        _FresnelFactor ("Fresnel Factor", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}

        GrabPass {"_RefractionTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST; 
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed; 
            fixed _WaveYSpeed; 
            float _Distortion; 
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;
            float _WaveAmplitude;
            float _FresnelFactor;

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb * _WaveAmplitude;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb * _WaveAmplitude;
                fixed3 bump = normalize(bump1 + bump2);
                

                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;  // the distortion will be greater at deeper postion
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

                bump = normalize(half3(dot(i.TtoW0.xyz, bump),dot(i.TtoW1.xyz, bump),dot(i.TtoW2.xyz, bump)));
                fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
                fixed3 reflDir = reflect(-viewDir, bump);
                reflDir.y = abs(reflDir.y);  // reflect direction should not below water surface
                fixed3 reflCol = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir).rgb * texColor.rgb * _Color.rgb;

                fixed fresnel = lerp(pow(1 - saturate(dot(viewDir, bump)), 4), 1, _FresnelFactor);
                fixed3 finalColor = lerp(refrCol, reflCol, fresnel);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLightDir + worldViewDir);
                fixed3 specular = _LightColor0.rgb * pow(max(0, dot(halfDir, bump)), 20);

                return fixed4(finalColor + specular, 1);
            }
            ENDCG
        }
    }
}
