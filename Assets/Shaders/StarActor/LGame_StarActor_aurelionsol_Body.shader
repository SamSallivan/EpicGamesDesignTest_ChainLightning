Shader "LGame/StarActor/aurelionsol_Body"
{
	Properties
	{
		_Color("Color" , Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaTex("Alpha Texture" , 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}

		[HDR]_RimlightCol("Rimlight Color" ,Color) = (0,0,0,0)
		_RimlightRange("Rimlight Range" , float) = 1
		_MaskTex("Mask Texture" , 2D) = "white" {}

		_HighlightStrength("Highlight Strength",Range(0.0,1.0)) = 0.0
		_HighlightRange("Highlight Range",Range(0.01,1.0)) = 1.0
		
		[SimpleToggle]_UseScreenSpace("UseScreenSpaceStarlight?",Range(0,1))=0
		_StarlightTex("Starlight Texture(RGB)" , 2D) = "black" {} 
		[HDR]_EmissionCol("Emission Color" , Color) = (0,0,0,0)
		_EmissionMap("Emission(Offset for flow)", 2D) = "black" {}
		_FlowSpeed("Flow Speed" , float) = 0
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"	
	#include "Lighting.cginc"	
	struct appdata
	{
		float4 vertex	: POSITION;
		float2 uv		: TEXCOORD0;
		float3 normal	: NORMAL;
		float4 tangent	: TANGENT;
	};

	struct v2f
	{
		float4 pos					: SV_POSITION;
		float4 uv					: TEXCOORD0;
		float4 tangentToWorld[3]	: TEXCOORD1;
		float3 lightDir				: TEXCOORD4;
		float3 viewDir				: TEXCOORD5;
		float2 modelSpacePos		: TEXCOORD6;
	};

	fixed4		_Color;
	sampler2D	_MainTex;
	float4		_MainTex_ST;
	sampler2D	_AlphaTex;
	sampler2D	_BumpMap;

	fixed4		_EmissionCol;
	sampler2D	_EmissionMap;
	float4		_EmissionMap_ST;
	float		_FlowSpeed;

	fixed4		_RimlightCol;
	half		_RimlightRange;
	sampler2D	_MaskTex;
	sampler2D	_StarlightTex;
	float4		_StarlightTex_ST;
					
	fixed4		_RimAurelionsolCol;
	half		_RimAurelionsolMultipliers;
	half		_HighlightRange;
	half		_HighlightStrength;
	half		_UseScreenSpace;
	 float2 useScreenPosAsUV(float4 modelvertpos)
   {
      float originDist=UnityObjectToViewPos(float3(0,0,0)).z;
      float3 viewVertPos= UnityObjectToViewPos(modelvertpos);
      viewVertPos.xy/=viewVertPos.z;
      viewVertPos*=originDist;
      return viewVertPos.xy;
   }
	v2f vert(appdata v)
	{
		v2f o;

		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		o.uv.zw = v.uv * _StarlightTex_ST.xy + frac(_StarlightTex_ST.zw * _Time.x);

		float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		o.pos = UnityObjectToClipPos(v.vertex);
		o.viewDir = UnityWorldSpaceViewDir(posWorld);
		o.lightDir = UnityWorldSpaceLightDir(posWorld);
		float3 normalWorld = UnityObjectToWorldNormal(v.normal);
		float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
		float3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
		o.tangentToWorld[0].xyz = tangentWorld;
		o.tangentToWorld[1].xyz = binormalWorld;
		o.tangentToWorld[2].xyz = normalWorld;
		o.tangentToWorld[0].w = posWorld.x;
		o.tangentToWorld[1].w = posWorld.y;
		o.tangentToWorld[2].w = posWorld.z;
		o.modelSpacePos=_StarlightTex_ST.xy*useScreenPosAsUV(v.vertex)+ frac(_StarlightTex_ST.zw * _Time.x);
		return o;
	}
	fixed4 frag(v2f i) : SV_Target
	{
		float3 wPos = float3(i.tangentToWorld[0].w ,i.tangentToWorld[1].w , i.tangentToWorld[2].w);
		float3 N = UnpackNormal(tex2D(_BumpMap,i.uv.xy));
		N = normalize(i.tangentToWorld[0].xyz * N.x + i.tangentToWorld[1].xyz * N.y + i.tangentToWorld[2].xyz * N.z);
		float3 V = Unity_SafeNormalize(i.viewDir);
		float3 L = normalize(i.lightDir);
		float3 H = Unity_SafeNormalize(L + V);
		float NoH = saturate(dot(N, H));

		float Highlight= pow(NoH, _HighlightRange * 64.0) * _HighlightStrength *_LightColor0.rgb;

		float Mask = tex2D(_MaskTex, i.uv.xy).r;
		half3 Fresnel = pow(1.0 - abs(dot(N, V)), _RimlightRange) * Mask * _RimlightCol.rgb;
		fixed3 Starlight = tex2D(_StarlightTex ,lerp( i.uv.zw,i.modelSpacePos,_UseScreenSpace));
		half EmissionRate = sin(i.uv.y * 20.0 + _Time.y * _FlowSpeed) * 0.5 + 0.5;
		half3 Emission= tex2D(_EmissionMap ,i.uv.xy).rgb * _EmissionCol * EmissionRate;
		fixed4 Color = tex2D(_MainTex, i.uv.xy) * _Color;
		half Alpha = tex2D(_AlphaTex ,i.uv.xy).g;
		Color *= Alpha;
		Color.rgb += Emission + Starlight +  Fresnel + Highlight;
		return  Color;
	}
 	ENDCG

	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType"="Opaque" }
		LOD 100
		Pass
		{
			Blend One OneMinusSrcAlpha
            Cull Front
			ZWrite Off	
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		Pass
		{
			
			Blend One OneMinusSrcAlpha
			Cull Back
			ZWrite Off		
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
       Pass
       {
           ColorMask 0
           Cull Back
           ZWrite On
       }
		Pass
		{
			
			Blend One OneMinusSrcAlpha
			Cull Back
			ZWrite Off	
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
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
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
	}
}
