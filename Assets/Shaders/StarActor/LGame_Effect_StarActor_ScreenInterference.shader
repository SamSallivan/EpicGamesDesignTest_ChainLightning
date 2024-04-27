Shader "LGame/Effect/StarActor/ScreenInterference"
{
	Properties
	{
		_Color("Color" , Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_EffectTex ("Effect Texture(Tilling控制缩放, offset控制速度)", 2D) = "white" {}
		_EffectCol("Effect Color" , Color) = (0.4,0.1,0,0)
		//Effect
		_DissolveMap("Dissolve Map",2D) = "black"{}
		_Dissolve("Dissolve",Range(0,1)) = 1.0
		_WorldOrigin("World Origin",Vector) = (0,0,0,0)
		_WorldTerminal("World Terminal",Vector) = (0,0,0,0)
		[Enum(Forward,0,Backward,1)]_WorldDirection("World Direction",Float) = 0
		_WorldClip("World Clip", Float) = 0
	}
	SubShader
	{
		Tags {"Queue"="AlphaTest"  "RenderType"="Transparent" }
		LOD 100
		Pass
		{
			Blend One Zero
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag	
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex	: POSITION;
				float2 uv		: TEXCOORD0;
			};
			struct v2f
			{
				float4 pos		: SV_POSITION;
				float4 uv		: TEXCOORD0;
				float3 wPos		: TEXCOORD1;
				float4 screenPos : TEXCOORD2;
			};
			half4		_Color;
			sampler2D	_MainTex;
			float4		_MainTex_ST;		
			sampler2D	_EffectTex;
			float4		_EffectTex_ST;
			fixed4		_EffectCol;	
			half _Dissolve;
			sampler2D _DissolveMap;
			half4 _DissolveMap_ST;
			half3 _WorldOrigin;
			half3 _WorldTerminal;
			half _WorldDirection;
			half _WorldClip;
			void LGame_Effect_WorldClip(half3 wPos, half4 screenPos)
			{

				half2 screenUV = screenPos.xy / screenPos.w;
				screenUV = frac(screenUV*_DissolveMap_ST.xy + _DissolveMap_ST.zw);
				half dissolve = tex2D(_DissolveMap, screenUV).r * _Dissolve;
				half temp = -_WorldDirection * 2.0 + 1.0;
				half3 dir_ot = _WorldTerminal - _WorldOrigin;
				half3 dir_ow = wPos - _WorldOrigin;
				dir_ow = normalize(dir_ot) * length(dir_ow) * dot(normalize(dir_ow), normalize(dir_ot));
				dir_ow = lerp(dir_ow, dir_ot*temp - dir_ow * temp, _WorldDirection);
				half3 dir_oc = dir_ot * (_WorldClip + dissolve);
				dir_oc = lerp(dir_oc, dir_ot*temp - dir_oc * temp, _WorldDirection);
				half c = length(dir_oc) - length(dir_ow);
				clip(c);
			}
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 srcPos = ComputeScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw =  srcPos.xy *_EffectTex_ST.xy/srcPos.w  + _Time.x * _EffectTex_ST.zw;//half2(_InfoVetor.x , srcPos.y *_InfoVetor.y/srcPos.w) + frac(_Time.x * _InfoVetor.zw);
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = srcPos;
				return o;
			}		
			fixed4 frag (v2f i) : SV_Target
			{
				LGame_Effect_WorldClip(i.wPos,i.screenPos);
				fixed4 col = tex2D(_MainTex, i.uv.xy) * _Color;
				fixed3 effect = tex2Dlod(_EffectTex , float4(frac(i.uv.zw),0,0))* _EffectCol; 
				col.rgb += effect;
				col.rgb *= col.a; 
				return col;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#define _WORLD_CLIP
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"		
			ENDCG
		}
	}
}
