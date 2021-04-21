Shader "Unlit/Burn"
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

        _BurnThreshold ("Burn Threshold", Range(0, 1)) = 0
        _LineWidth ("Burn Line Width", Range(0.0, 0.2)) = 0.1
        _BurnMap ("Burn Map", 2D) = "white" {}
        _BurnFirstColor ("Burn First Color", Color) = (1, 0, 0, 1)
        _BurnSecondColor ("Burn Second Color", Color) = (1, 1, 0, 1)
	}
	SubShader
	{	
		Tags {"RenderType" = "Opaque"}
        Cull Off
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"

		#define USE_UNITY_FOG 0
		#pragma multi_compile_fog

		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _Bump;
		float4 _Bump_ST;
		float _BumpScale;
		fixed4 _Specular;
		float _Gloss;
        float _HalfLambert;

        float _BurnThreshold;
        float _LineWidth;
        sampler2D _BurnMap;
        float4 _BurnMap_ST;
        fixed4 _BurnFirstColor;
        fixed4 _BurnSecondColor;

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 uv :TEXCOORD0;
		};

		struct v2f {
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
			float4 T2W0 : TEXCOORD1;
			float4 T2W1 : TEXCOORD2;
			float4 T2W2 : TEXCOORD3;
            float2 uvBurnMap : TEXCOORD4;
			SHADOW_COORDS(5)
			UNITY_FOG_COORDS(6)
		};

		v2f vert(appdata v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
			fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal).xyz);
			o.uv = float4(TRANSFORM_TEX(v.uv, _MainTex), TRANSFORM_TEX(v.uv, _Bump));
            o.uvBurnMap = TRANSFORM_TEX(v.uv, _BurnMap);
			fixed3 tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
			fixed3 bitangent = cross(worldNormal, tangent) * v.tangent.w;
			o.T2W0 = float4(tangent.x, bitangent.x, worldNormal.x, worldPos.x);
			o.T2W1 = float4(tangent.y, bitangent.y, worldNormal.y, worldPos.y);
			o.T2W2 = float4(tangent.z, bitangent.z, worldNormal.z, worldPos.z);
			TRANSFER_SHADOW(o);

			#if USE_UNITY_FOG
			UNITY_TRANSFER_FOG(o, o.pos);
			#endif

			return o;
		}

		float4 fragBase(v2f i): SV_TARGET {
            fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
            float3 worldPos = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
            float burnCheck = 0.2 * (burn.r - _BurnThreshold) + (worldPos.y - 0.5 * _Time.y);
            clip(burnCheck);

			fixed3 texColor = tex2D(_MainTex, i.uv.xy).rgb;
			fixed3 albedo = _Color.rgb * texColor;

			fixed3 ambient = unity_AmbientSky.xyz * albedo;

			fixed3 tgNormal = UnpackNormal(tex2D(_Bump, i.uv.zw));
			tgNormal.xy *= _BumpScale;
			tgNormal.z = sqrt(1 - saturate(dot(tgNormal.xy, tgNormal.xy)));
			fixed3 normal = normalize(float3(dot(i.T2W0.xyz, tgNormal), dot(i.T2W1.xyz, tgNormal), dot(i.T2W2.xyz, tgNormal)));

			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			
			fixed3 diffuse = _LightColor0.rgb * albedo 
                * lerp(max(0, dot(worldLightDir, normal)), 0.5 + 0.5*max(0, dot(worldLightDir, normal)), _HalfLambert);

			fixed3 halfDir = normalize(worldLightDir + worldViewDir);
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, normal)), _Gloss);

            fixed t = 1 - smoothstep(0, _LineWidth, burnCheck);
            fixed3 burnColor = pow(lerp(_BurnFirstColor, _BurnSecondColor, t), 5);

			UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
			fixed4 col = fixed4(lerp(ambient + (diffuse + specular) * atten, burnColor, t), 1.0);

			#if USE_UNITY_FOG
			UNITY_APPLY_FOG(i.fogCoord, col);
			#endif

			return col;
		}

		float4 fragAdd(v2f i): SV_TARGET {
            fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
            float3 worldPos = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
            float burnCheck = 0.2 * (burn.r - _BurnThreshold) + (worldPos.y - 0.5 * _Time.y);
            clip(burnCheck);

			fixed3 texColor = tex2D(_MainTex, i.uv.xy).rgb;
			fixed3 albedo = _Color.rgb * texColor;

			fixed3 tgNormal = UnpackNormal(tex2D(_Bump, i.uv.zw));
			tgNormal.xy *= _BumpScale;
			tgNormal.z = sqrt(1 - saturate(dot(tgNormal.xy, tgNormal.xy)));
			fixed3 normal = normalize(float3(dot(i.T2W0.xyz, tgNormal), dot(i.T2W1.xyz, tgNormal), dot(i.T2W2.xyz, tgNormal)));

			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			
			fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldLightDir, normal));

			fixed3 halfDir = normalize(worldLightDir + worldViewDir);
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, normal)), _Gloss);

            fixed t = 1 - smoothstep(0, _LineWidth, burnCheck);
            fixed3 burnColor = pow(lerp(_BurnFirstColor, _BurnSecondColor, t), 5);

			UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

			return fixed4(lerp((diffuse + specular) * atten, burnColor, t), 1.0);
		}

		ENDCG

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBase
			#pragma multi_compile_fwdbase

			ENDCG
		}
		Pass
		{
			Tags {"LightMode" = "ForwardAdd"}
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			
			ENDCG
		}
        
        Pass {
            Tags {"LightMode" = "ShadowCaster"}
			CGPROGRAM
			#pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_complie_shadowcaster
            struct v2fShadow {
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            v2fShadow vertShadow(appdata_base v) {
                v2fShadow o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }
            fixed4 fragShadow(v2fShadow i) : SV_TARGET {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
                float3 worldPos = i.worldPos;
                float burnCheck = 0.2 * (burn.r - _BurnThreshold) + (worldPos.y - 0.5 * _Time.y);
                clip(burnCheck);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
	}
	FallBack "Specular"
}