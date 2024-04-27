Shader "LGame/Scene/StarActor/Reflection" {
	Properties {
		[Header(Point Light)]
		_PointLightColor("点光颜色",Color) = (1,1,1,1)
		_PointLightRange("点光范围",float) = 3
		_PointLightIntensity("点光强度",float) = 6.08
		_PointLightPos("点光世界位置xyz",Vector) = (-1.267,1.036,-0.335,0)
		[Header(Default)]
		_Color("基础颜色",Color)=(1,1,1,1)
		_MainTex("基础纹理",2D)="white"{}
		_ReflIntensityTex("反射强度贴图",2D)="white"{}
		_ReflScale("反射强度",Range(0,1))=0
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[Header(Planar Reflection)]
		_Environment("Planar Refletion",2D) = ""{}
		[Header(Cube Reflection)]
		_CubeMap("Cube Map",Cube) = "cube"{}
	}
	SubShader 
	{
		Tags { "Queue"="Geometry"  "RenderType"="Opaque"}

		Pass
		{
			Name "ForwardBase"
			Tags{"LightMode"="ForwardBase"}
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
			fixed4		_Color;
			sampler2D	_MainTex;
			float4		_MainTex_ST;
			sampler2D	_NormalMap;
			float4		_NormalMap_ST;
			sampler2D	_ReflIntensityTex;
			float4		_ReflIntensityTex_ST;
			half		_ReflScale;
			half		_ShadowStrength;
#ifdef _PLANAR_REFLECTION
			sampler2D	_Environment;
#else
			samplerCUBE _CubeMap;
			half4	_CubeMap_HDR;
#endif			
			fixed4		_PointLightColor;
			half4		_PointLightPos;
			half		_PointLightRange;
			half		_PointLightIntensity;
			struct a2v
			{
				float4 uv		:TEXCOORD0 ;
				float4 vertex	:POSITION ;
				float3 normal	:NORMAL;
				float4 tangent	:TANGENT;
			};

			struct v2f
			{
				float4 pos			:SV_POSITION;
				float4 uv			:TEXCOORD0;
				float3 wPos			:TEXCOORD1;
#ifdef _PLANAR_REFLECTION
				float4 ScreenPos		:TEXCOORD2;
#else
				float3 viewDir:TEXCOORD2;
				float3 normalWorld:TEXCOORD3;
#endif
				SHADOW_COORDS(4)
			};
			v2f vert(a2v v)
			{
				v2f o;
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _ReflIntensityTex);
#ifdef _PLANAR_REFLECTION
				o.ScreenPos = ComputeScreenPos(o.pos);
#else
				o.viewDir = UnityWorldSpaceViewDir(o.wPos);
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
#endif
				TRANSFER_SHADOW(o);
				return o;
			}
			fixed4 frag(v2f i) : COLOR
			{
				float len = length(_PointLightPos.xyz - i.wPos);
				float pointParam = 1 - min(len , _PointLightRange) / _PointLightRange;
				pointParam *= pointParam;
				half3 pointLight = _PointLightColor.rgb * _PointLightIntensity * pointParam;
#ifdef _PLANAR_REFLECTION
				half3 indirectSpecular = tex2D(_Environment, i.ScreenPos.xy / i.ScreenPos.w);
#else
				half3 V = normalize(i.viewDir);
				half3 N = normalize(i.normalWorld);
				half3 R = reflect(-V, N);
				half4 Cube = texCUBE(_CubeMap, R);
				half3 indirectSpecular = DecodeHDR(Cube, _CubeMap_HDR);
#endif
				half reflIntensity = tex2D(_ReflIntensityTex ,i.uv.zw).r * _ReflScale;
				half atten = SHADOW_ATTENUATION(i);
				atten = lerp(1.0, atten, _ShadowStrength);
				half4 texCol = tex2D(_MainTex,i.uv.xy) * _Color;
				fixed3 col = texCol+texCol * pointLight + indirectSpecular * reflIntensity;
				col.rgb *= atten;
				return fixed4(col,1.0);	
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
