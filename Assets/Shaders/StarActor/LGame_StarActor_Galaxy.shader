Shader "LGame/StarActor/Galaxy"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0.0,1.0)) = 1.0
		_OcclusionMap("Occlusion Map",2D) = "white"{}
		_OcclusionStrength("Occlusion Strength",Range(0,1)) = 1
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[Enum(MatCap,0,CubeMap,1)] _ReflectionType("Reflection Type", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_ReflectionCubeMap("Reflection Texture", Cube) = "" {}
		_AmbientCol("Ambient Color" , Color) = (0.5,0.5,0.5,0.5)
		_ShadowColor("Shadow Color" , Color) = (0,0,0,0.667)
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1

		_StarMap("Star Map",2D) = "black"{}
		[HDR]_StarColor("Star Color", Color) = (0.5 , 0.5 , 0.5 , 0)
		_DetailTiling("Detail Tiling",Float) = 4.0
		_DetailStrength("Detail Strength",Range(0.0,1.0)) = 1.0
		_Distortion("Distortion", Range(0.0,1.0)) = 1.0
		_FlowSpeed("Flow Speed",Float)=0.0
		_BreatheSpeed("Breathe Speed",Float) = 0.0
		_RimPower("Rim Power",Range(0.0,16.0)) = 8.0
	}
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"	
		#include "Lighting.cginc"	
		#include "Assets/CGInclude/LGameStarActorInput.cginc"
		sampler2D _StarMap;
		sampler2D _StarActorTexture;
		float4 _StarMap_ST;
		float _FlowSpeed;
		float _BreatheSpeed;
		half _Distortion;
		half _DetailTiling;
		half _DetailStrength;
		half _RimPower;
		fixed4 _StarColor;
		struct v2f_galaxy
		{
			half4 pos				: SV_POSITION;
			half4 uv				: TEXCOORD0;		
			half4 screenPos			: TEXCOORD1;
			half4 detail_uv			: TEXCOORD2;
			half4 viewDir           : TEXCOORD3;
			half4 tangentToWorld[3]	: TEXCOORD4;
			LGAME_STARACTOR_SHADOW_COORDS(7)
		};
		void GalaxyDataSetup(v2f_galaxy i, out BaseMaterialData base, out half3 viewDir, out half3 wPos)
		{
			//Base
			viewDir = normalize(i.viewDir.xyz);
			wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
			half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
			base.normal = normalize(i.tangentToWorld[0].xyz*normal.r + i.tangentToWorld[1].xyz*normal.g + i.tangentToWorld[2].xyz*normal.b);
			base.occlusion = tex2D(_OcclusionMap, i.uv.xy).g;
			half4 albedo = tex2D(_MainTex, i.uv) * _Color;
#ifdef UNITY_PASS_FORWARDBASE
			float3 star = tex2D(_StarMap, frac(i.detail_uv.xy + sin(_Time.x*_FlowSpeed)));
			star = saturate(star + tex2D(_StarMap, frac(i.detail_uv.zw*_DetailTiling -sin(_Time.x*_FlowSpeed)))*_DetailStrength);
			star *= _StarColor * (1.0+saturate((sin(_Time.y*_BreatheSpeed))));
			float2 offset = base.normal.xy * _Distortion;
			i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
			half4 background = tex2Dproj(_StarActorTexture, UNITY_PROJ_COORD(i.screenPos));

			half NoV = saturate(dot(base.normal, viewDir));
			half factor = pow(NoV,_RimPower)*(1.0 - albedo.a);
			//half3 blend =albedo.rgb * albedo.a + background * (1.0 - albedo.a)+ galaxy.star * (1.0 - albedo.a);
			//half3 blend = albedo.rgb * lerp(2.0-NoV, background, factor) + star * factor;
			half3 blend = albedo.rgb * lerp(1.0.rrrr, background, factor) + star * factor;
			albedo.rgb = GammaToLinearSpace(blend);
#else
			albedo.rgb = GammaToLinearSpace(albedo.rgb);
#endif
			base.opacity = albedo.a;
#ifdef _METALLICGLOSSMAP
			half2 data = tex2D(_MetallicGlossMap, i.uv).rg;
			half metallic = data.r;
			base.smoothness = data.g*_GlossMapScale;
#else
			half metallic = _Metallic;
			base.smoothness = _Glossiness;
#endif
			base.perceptual_roughness = 1 - base.smoothness;
			base.roughness = base.perceptual_roughness * base.perceptual_roughness;
			half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
			base.one_minus_reflectivity = (1 - metallic) * _ColorSpaceDielectricSpec.a;
			base.specColor = lerp(_ColorSpaceDielectricSpec.rgb, albedo.rgb, metallic);
			base.diffColor = albedo.rgb* base.one_minus_reflectivity;
#ifdef _OCCLUSION_UV1
			base.occlusion = tex2D(_OcclusionMap, i.uv.zw).g;
#else
			base.occlusion = tex2D(_OcclusionMap, i.uv.xy).g;
#endif
			base.occlusion = lerp(1.0.rrr, base.occlusion, _OcclusionStrength);
		}
		half4 LGAME_BRDF_PBS_GALAXY(LGameGI gi, BaseMaterialData base, half3 viewDir, half NoL, half atten)
		{
			half3 H = normalize(gi.direct.dir + viewDir);
			half NoV = saturate(dot(base.normal, viewDir));
			NoL = saturate(NoL);
			half NoH = saturate(dot(base.normal, H));
			half LoH = saturate(dot(gi.direct.dir, H));
			half3 diffuseTerm = gi.direct.color * atten * NoL;
			float a2 = base.roughness * base.roughness;
			float d = NoH * NoH * (a2 - 1.f) + 1.00001f;
			half specularTerm = a2 / (max(0.1f, LoH*LoH) * (base.roughness + 0.5f) * (d * d) * 4);
			half surfaceReduction = (0.6 - 0.08*base.perceptual_roughness);
			surfaceReduction = 1.0 - base.roughness *base.perceptual_roughness * surfaceReduction;
			half grazingTerm = saturate(base.smoothness + (1.0 - base.one_minus_reflectivity));
			half3 color = (base.diffColor + specularTerm * base.specColor)*diffuseTerm
				+ gi.indirect.diffuse * base.diffColor
				+ surfaceReduction * gi.indirect.specular * FresnelLerpFast(base.specColor, grazingTerm, NoV);
			return half4(color, 1);
		}
		half4 LGAME_BRDF_PBS_GALAXY_ADD(LGameDirectLight direct, BaseMaterialData base,half3 viewDir, half atten)
		{
			half3 H = normalize(direct.dir + viewDir);
			half NoV = abs(dot(base.normal, viewDir));
			half NoL = saturate(dot(base.normal, direct.dir));
			half NoH = saturate(dot(base.normal, H));
			half LoH = saturate(dot(direct.dir, H));
			half3 diffuseTerm = direct.color * atten * NoL;
			float a2 = base.roughness * base.roughness;
			float d = NoH * NoH * (a2 - 1.f) + 1.00001f;
			half specularTerm = a2 / (max(0.1f, LoH*LoH) * (base.roughness + 0.5f) * (d * d) * 4);
			half3 color = (base.diffColor + specularTerm * base.specColor)*diffuseTerm;
			return half4(color, 1);
		}
		ENDCG
    SubShader
    {
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
		LOD 300

		GrabPass{"_StarActorTexture"}

		Pass
		{
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			ZWrite On
			CGPROGRAM
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight noshadowmask  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			#pragma shader_feature _REFLECTION_CUBEMAP
			v2f_galaxy vert(a2v v)
			{
				v2f_galaxy o;
				UNITY_INITIALIZE_OUTPUT(v2f_galaxy,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeGrabScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;			
				o.viewDir.xyz = normalize(UnityWorldSpaceViewDir(posWorld));
				o.detail_uv.xyzw= posWorld.xyxy*_StarMap_ST.xyxy + _StarMap_ST.zwzw;
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				LGAME_STARACTOR_TRNASFER_SHADOW(o);
				return o;
			}
			fixed4 frag(v2f_galaxy i) : SV_Target
			{
				BaseMaterialData base;
				half3 viewDir;
				half3 wPos;
				GalaxyDataSetup(i,base,viewDir,wPos);
				LGameGI gi = FragmentGI(wPos, viewDir, base.normal, base.occlusion, base.roughness);
				half NoL = dot(base.normal, gi.direct.dir);
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, NoL);

				fixed4 col = LGAME_BRDF_PBS_GALAXY(gi, base, viewDir, NoL, atten);
				col.rgb = LinearToGammaSpace(col.rgb);
				return fixed4(col.rgb,1);
			}
		ENDCG
		}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_fwdadd  
			#pragma skip_variants LIGHTMAP_SHADOW_MIXING SHADOWS_SCREEN LIGHTPROBE_SH SPOT DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_CUBE	
			#pragma vertex vert_add
			#pragma fragment frag_add
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			v2f_galaxy vert_add(a2v v)
			{
				v2f_galaxy o;
				UNITY_INITIALIZE_OUTPUT(v2f_galaxy,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				o.viewDir.xyz = normalize(UnityWorldSpaceViewDir(posWorld));
				o.detail_uv.xyzw = posWorld.xyxy*_StarMap_ST.xyxy + _StarMap_ST.zwzw;
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				return o;
			}
			half4 frag_add(v2f_galaxy i) : SV_Target
			{
				BaseMaterialData base;
				half3 viewDir;
				half3 wPos;
				GalaxyDataSetup(i,base,viewDir,wPos);
				UNITY_LIGHT_ATTENUATION(atten, i, wPos);
				LGameDirectLight direct = LGameDirectLighting(wPos);
				fixed4 col = LGAME_BRDF_PBS_GALAXY_ADD(direct,base,viewDir, atten);
				col.rgb = LinearToGammaSpace(col.rgb);
				return fixed4(col.rgb,1);
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
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"				
			ENDCG
		}
    }
	CustomEditor "LGameSDK.AnimTool.LGameStarActorGalaxyShaderGUI"
}
