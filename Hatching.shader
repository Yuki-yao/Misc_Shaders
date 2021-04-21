Shader "Unlit/Hatching"
{
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		UsePass "Unlit/Toon/OUTLINE"
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag 
			
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			float _TileFactor;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv = v.texcoord.xy * _TileFactor;
		
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o; 
			}
			
			fixed4 frag(v2f i) : SV_TARGET {
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed diff = max(0, dot(worldLightDir, i.worldNormal));

				fixed weight0 = smoothstep(0, 0.1667, diff);
				fixed weight1 = smoothstep(0.1667, 0.3333, diff);
				fixed weight2 = smoothstep(0.3333, 0.5, diff);
				fixed weight3 = smoothstep(0.5, 0.6667, diff);
				fixed weight4 = smoothstep(0.6667, 0.8333, diff);
				fixed weight5 = smoothstep(0.8333, 1, diff);

				fixed4 hatchTex0 = tex2D(_Hatch0, i.uv);
				fixed4 hatchTex1 = tex2D(_Hatch1, i.uv);
				fixed4 hatchTex2 = tex2D(_Hatch2, i.uv);
				fixed4 hatchTex3 = tex2D(_Hatch3, i.uv);
				fixed4 hatchTex4 = tex2D(_Hatch4, i.uv);
				fixed4 hatchTex5 = tex2D(_Hatch5, i.uv);
				fixed4 hatchColor = lerp(lerp(lerp(lerp(lerp(lerp(hatchTex0, hatchTex1, weight0), 
					hatchTex2, weight1), hatchTex3, weight2), hatchTex4, weight3), hatchTex5, weight4), fixed4(1, 1, 1, 1), weight5);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
								
				return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}