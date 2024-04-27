Shader "LGame/StarActor/Holographic Projection"
{
	Properties
	{
		[HDR]_Color("Color" , Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0.0,1.0)) = 1.0
		_OcclusionMap("Occlusion Map",2D) = "white"{}
		_OcclusionStrength("Occlusion Strength",Range(0,1)) = 1
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		_Voxel("Voxel", Range(0.0,256)) = 128.0
		_Gap("Gap",Range(0.0,1.0)) = 0.5
		_Dither("Dither", Range(0.0,1.0)) = 0.5
		_EdgeDither("Edge Dither", Range(0.0,1.0)) = 0.5
		_Inter("Inter", Range(0.0,16.0)) = 4.0
		_InterWidth("Inter Width", Range(0.0,0.25)) = 0.1
		_InterSpeed("Inter Speed", Range(-32.0,32.0)) = 8.0
		_ColorSplit0("Color Split 0",Range(0.0,4.0)) = 1.0
		_ColorSplit1("Color Split 1",Range(0.0,4.0)) = 1.0
		_ColorSplitR0("Color Split R",Range(-1.0,1.0)) = 0.5
		_ColorSplitG0("Color Split G",Range(-1.0,1.0)) = 0.5
		_ColorSplitB0("Color Split B",Range(-1.0,1.0)) = 0.5
		_ColorSplitR1("Color Split R",Range(-1.0,1.0)) = 0.5
		_ColorSplitG1("Color Split G",Range(-1.0,1.0)) = 0.5
		_ColorSplitB1("Color Split B",Range(-1.0,1.0)) = 0.5
		_Flow("Flow",Range(0.0,8.0)) = 4.0
		_FlowSpeed("Flow Speed",Range(-4.0,4.0)) = 1.0
	}
	SubShader
	{
		Tags {"RenderType" = "UniqueShadow" "Queue" = "AlphaTest" "PerformanceChecks" = "False"}
		LOD 300
			
		Pass
		{
			Stencil {
				Ref 16
				Comp always
				Pass replace
			}
			ColorMask 0
			Cull Off
			ZWrite On
		}
		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			CGPROGRAM
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE LIGHTMAP_SHADOW_MIXING POINT_COOKIE
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma vertex vert
			#pragma fragment frag	
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"	
			#include "Assets/CGInclude/LGameStarActorUtils.cginc"
			#include "Assets/CGInclude/LGameStarActorLighting.cginc"
			struct appdata
			{
				float4 vertex			: POSITION;
				half2 uv0				: TEXCOORD0;
				half2 uv1				: TEXCOORD1;
				half3 normal			: NORMAL;
				half4 tangent			: TANGENT;
			};
			struct v2f
			{
				float4 pos				: SV_POSITION;
				half4 uv				: TEXCOORD0;
				half3 viewDir           : TEXCOORD1;
				half4 tangentToWorld[3]	: TEXCOORD2;
				half4 scrPos			: TEXCOORD5;
				LGAME_STARACTOR_SHADOW_COORDS(6)
			};
			
			fixed4		_Color;
			sampler2D	_MainTex;
			sampler2D	_BumpMap;
			float4		_MainTex_ST;	

			half	_BumpScale;
#ifdef _METALLICGLOSSMAP
			sampler2D   _MetallicGlossMap;
			half        _GlossMapScale;
#else
			half        _Metallic;
			half        _Glossiness;
#endif
			float		_Voxel;
			float		_Gap;
			float		_Flow;
			float		_FlowSpeed;
			float		_ColorSplit0;
			float		_ColorSplitR0;
			float		_ColorSplitG0;
			float		_ColorSplitB0;
			half		_ColorSplit1;
			half		_ColorSplitR1;
			half		_ColorSplitG1;
			half		_ColorSplitB1;
			float		_Dither;
			float		_EdgeDither;
			float		_Inter;
			float		_InterWidth;
			float		_InterSpeed;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex.xyz);
				o.scrPos = ComputeScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				o.viewDir = UnityWorldSpaceViewDir(posWorld);
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				LGAME_STARACTOR_TRNASFER_SHADOW(o)
				return o;
			}	
			#define MOD3 float3(443.8975,397.2973, 491.1871)
			float hash12(float2 p)
			{
				float3 p3 = frac(float3(p.xyx) * MOD3);
				p3 += dot(p3, p3.yzx + 19.19);
				return frac((p3.x + p3.y) * p3.z);
			}
			fixed4 frag (v2f i) : SV_Target
			{ 
				half3 V = normalize(i.viewDir.xyz);
				half3 N = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
				N = normalize(i.tangentToWorld[0].xyz * N.r + i.tangentToWorld[1].xyz * N.g + i.tangentToWorld[2].xyz * N.b);
				half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
		
				half4 Albedo = tex2D(_MainTex, i.uv.xy) * _Color;
#ifdef UNITY_COLORSPACE_GAMMA
				Albedo.rgb = GammaToLinearSpace(Albedo.rgb);
#endif

#ifdef _METALLICGLOSSMAP
				half3 Data = tex2D(_MetallicGlossMap, i.uv).rgb;
				Data.g *= _GlossMapScale;
				half Metallic = Data.r;
				half Smoothness = Data.g;
#else
				half Metallic = _Metallic;
				half Smoothness = _Glossiness;
#endif
				half PerceptualRoughness = 1.0 - Smoothness;
				half Roughness = max(0.001, PerceptualRoughness * PerceptualRoughness);
				half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
				half OneMinusReflectivity = (1.0 - Metallic) * _ColorSpaceDielectricSpec.a;
				half3 DiffColor = Albedo.rgb * OneMinusReflectivity;
				half3 SpecColor = lerp(_ColorSpaceDielectricSpec.rgb, Albedo.rgb, Metallic);
#ifdef _OCCLUSION_UV1
				half3 Occ = Occlusion(i.uv.zw);
#else
				half3 Occ = Occlusion(i.uv.xy);
#endif

				LGameGI GI = FragmentGI(wPos, V, N, Occ.r, PerceptualRoughness);

				half3 H = normalize(GI.direct.dir + V);
				half NoV = abs(dot(N, V));
				half NoL = dot(N, GI.direct.dir);
				half NoH = saturate(dot(N, H));
				half LoH = saturate(dot(GI.direct.dir, H));


				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);
				NoL = saturate(NoL);
				//Diffuse Term
				half3 DiffuseTerm = GI.direct.color  * NoL * atten;

				//Specular Term
				float a2 = Roughness * Roughness;
				float d = (NoH * NoH * (a2 - 1.f) + 1.0f) + 0.00001f;
				half3 SpecularTerm = a2 / (max(0.1f, LoH * LoH) * (Roughness + 0.5f) * (d * d) * 4.0) * SpecColor;
				SpecularTerm = SpecularTerm - 1e-4f;
				SpecularTerm = clamp(SpecularTerm, 0.0, 100.0);
				half SurfaceReduction = (0.6 - 0.08 * PerceptualRoughness);
				SurfaceReduction = 1.0 - Roughness * PerceptualRoughness * SurfaceReduction;
				half GrazingTerm = saturate(Smoothness + (1.0 - OneMinusReflectivity));

				float2 scrUV = i.scrPos.xy / i.scrPos.w;
				scrUV.x *= _ScreenParams.x / _ScreenParams.y;

				//Dither
				float2 Seed = scrUV.xy;
				float3 Rand = hash12(Seed) + hash12(Seed + 0.59374) - 0.5;
				float Dither  = lerp(0.0, 1.0 / 32.0, 0.5) + Rand / 255.0;
				Dither = floor(Dither * 255.0) / 255.0 * 32.0;
				float EdgeDither = saturate(lerp(0.0, Dither, _EdgeDither));
				Dither = saturate(lerp(1.0, Dither, _Dither));

				//Flow
				float Flow = smoothstep(0.0, 1.0, frac(scrUV.y * _Flow - _Time.y * _FlowSpeed));

				//Gap
				float4 ColorSplit0 = float4(_ColorSplitR0, _ColorSplitG0, _ColorSplitB0, 0.0f) * _ColorSplit0;
				float4 Range = frac(scrUV.y * _Voxel + ColorSplit0 + EdgeDither);
				Range = abs(Range - 0.5f) * 2.0f;
				Range = smoothstep(0.0f, _Gap, Range);	
				float Gap = lerp(Range.w, 1.0, Flow);

				//Inter
				float InterRange = scrUV.y * _Inter;
				InterRange = frac(InterRange + floor(_Time.y + InterRange) * 0.1f + scrUV.y);
				InterRange = step(0.5, InterRange) * step(InterRange,_InterWidth + 0.5);
				float Inter = step(frac(_Time.y + scrUV.x), saturate(sin(_Time.y * _InterSpeed) - NoV));
				Inter *= InterRange;
		
				//Color Split——低配干掉
				half3 vN = mul(UNITY_MATRIX_V, half4(N, 0)).xyz;
				half3 vP = -UnityWorldToViewPos(wPos);
				half3 ColorSplit1 = half3(_ColorSplitR1, _ColorSplitG1, _ColorSplitB1) * _ColorSplit1;
				half NoV0 = saturate(dot(vN, normalize(vP + half3(ColorSplit1.x, 0, 0))));
				half NoV1 = saturate(dot(vN, normalize(vP + half3(ColorSplit1.y, 0, 0))));
				half NoV2 = saturate(dot(vN, normalize(vP + half3(ColorSplit1.z, 0, 0))));

				
				//Split Combine——低配干掉
				half3 DiffColorTemp = lerp(half3(NoV0, NoV1, NoV2).xyz, DiffColor, NoV);
				DiffColorTemp = lerp(Range.xyz, DiffColorTemp, Range.x * Range.y * Range.z);
				DiffColor = lerp(DiffColorTemp, DiffColor, Flow);

				half3 Color = (DiffColor  + SpecularTerm) * DiffuseTerm;
				Color += GI.indirect.diffuse * DiffColor;
				Color += SurfaceReduction * GI.indirect.specular *  FresnelLerpFast(SpecColor, GrazingTerm, NoV);

				float Alpha = saturate(Albedo.a * Luminance(Color) * Dither);
				Alpha *= saturate(Gap - Inter);

				return fixed4(Color, Alpha);
			}
			ENDCG
		}
		
	}
	CustomEditor "LGameSDK.AnimTool.LGameStarActorHolographicProjectionShaderGUI"
}
