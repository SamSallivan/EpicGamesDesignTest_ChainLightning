Shader "LGame/Scene/StarActor/Reflection_Transparent" {
	Properties {
		[Header(Default)]
		_Color("基础颜色",Color)=(1,1,1,1)
		_AlphaTex("透明纹理",2D)="white"{}
		_ReflIntensityTex("反射强度贴图",2D)="white"{}
		_ReflScale("反射强度",Range(0,1))=0
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[Header(Planar Reflection)]
		_Environment("Planar Refletion",2D)=""{}
		[Header(Cube Reflection)]
		_CubeMap("Cube Map",Cube) = "cube"{}
	}
	SubShader 
	{
		Tags { "Queue"="Geometry"  "RenderType"="Opaque"}

		Pass
		{
			Name "ForwardBase"
			Tags{"LightMode" = "ForwardBase"}
			Stencil {
				Ref 0
				Comp always
				Pass replace
			}
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite Off
			LOD 200
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE
			#pragma multi_compile _ _PLANAR_REFLECTION
			#pragma target 3.0
			#include "AutoLight.cginc"	
			#include "Lighting.cginc"
			#include "UnityCG.cginc"
			sampler2D	_AlphaTex;
			sampler2D	_ReflIntensityTex;
			float4		_AlphaTex_ST;
			float4		_ReflIntensityTex_ST;
			fixed4		_Color;
			half		_ReflScale;
			half		_ShadowStrength;
#ifdef _PLANAR_REFLECTION
			sampler2D	_Environment;
#else
			samplerCUBE _CubeMap;
			half4	_CubeMap_HDR;
#endif
			
			struct a2v
			{
				half4 uv		:TEXCOORD0 ;
				half4 vertex	:POSITION ;
				half3 normal	:NORMAL;
			};

			struct v2f
			{
				float4 pos			:SV_POSITION;
				half4 uv			:TEXCOORD0;	
				half3 wPos			:TEXCOORD1;
#ifdef _PLANAR_REFLECTION
				half4 ScreenPos		:TEXCOORD2;
#else
				half3 viewDir:TEXCOORD2;
				half3 normalWorld:TEXCOORD3;
#endif
				SHADOW_COORDS(4)
			}; 
			v2f vert(a2v v)
			{
				v2f o;
				o.wPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.pos=UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv,_AlphaTex);
				o.uv.zw = TRANSFORM_TEX(v.uv,_ReflIntensityTex);
#ifdef _PLANAR_REFLECTION
				o.ScreenPos = ComputeScreenPos(o.pos);
#else
				o.viewDir = UnityWorldSpaceViewDir(o.wPos);
				o.normalWorld=UnityObjectToWorldNormal(v.normal);
#endif
				TRANSFER_SHADOW(o);
				return o;
			}
			fixed4 frag(v2f i) : COLOR
			{
#ifdef _PLANAR_REFLECTION
				half3 indirectSpecular = tex2D(_Environment,i.ScreenPos.xy/i.ScreenPos.w) ;
#else
				half3 V = normalize(i.viewDir);
				half3 N = normalize(i.normalWorld);
				half3 R = reflect(-V,N);
				half4 Cube = texCUBE(_CubeMap, R);
				half3 indirectSpecular = DecodeHDR(Cube, _CubeMap_HDR);
#endif
				half reflIntensity = tex2D(_ReflIntensityTex ,i.uv.zw).r * _ReflScale;
				half atten = SHADOW_ATTENUATION(i);
				atten = lerp(1.0, atten, _ShadowStrength);
				half alpha = tex2D(_AlphaTex,i.uv.xy).r * _Color.a;
				fixed3 col = _Color.rgb + indirectSpecular * reflIntensity;
				col.rgb *= atten;
				return fixed4(col,alpha);	
			}
			ENDCG
		}	
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZTest LEqual
			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			//#pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#include "UnityCG.cginc"
			struct v2f_shadow
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f_shadow vert_shadow(appdata_base v)
			{
				v2f_shadow o;
				UNITY_SETUP_INSTANCE_ID(v);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			float4 frag_shadow(v2f_shadow i) : COLOR
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
