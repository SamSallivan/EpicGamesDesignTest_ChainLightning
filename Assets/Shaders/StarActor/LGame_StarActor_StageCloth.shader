Shader "LGame/StarActor/Stage Cloth"
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
		_DetailNormalMap("Detail Normal Map",2D) = "bump"{}
		_DetailSpecularStrength("Detail Specular Strength",Range(0.0,1.0)) = 1.0
		_DetailSpecularPower("Detail Specular Power",Float) = 8.0
		_GlintStrength("Glint Strength",Range(0.0,1.0))=1.0
		_GlintPower("Glint Power",Float) = 0.1
		_GlintSpeed("Glint Power",Float) = 1.0
		_DiamondMap("Diamand Map",2D) = "black"{}
		[Enum(uv0,0,uv1,1)] _OcclusionUVChannel("Occlusion texture UV", Float) = 0
		[HDR]_ReflectionColor("Reflection Color", Color) = (0.5,0.5,0.5)
		_ReflectionMatCap("Reflection Texture", 2D) = "black" {}
		_AmbientCol("Ambient Color" , Color) = (0.3,0.3,0.3,0.3)
		_ShadowColor("Shadow Color" , Color) = (0,0,0,0.667)
		_ShadowFalloff("Shadow Falloff" , Range(0.01,1)) = 0.5
		_ShadowStrength("Self Shadow Strength" , Range(0,1)) = 1
		[HDR]_RakingLightColor("Raking Light Color" , Color) = (0,0,0,0)
		_RakingLightSoftness("Raking Light Softness",Float) = 4.0
		_BrightnessInOcclusion("Brightness In Occlusion" , Range(0,1)) = 0.5
		_BrightnessInShadow("Brightness In Shadow" , Range(0,1)) = 0.5
		_DirLight("Dir Light" , Vector) = (-1,0,0,0)
	}
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"	
	#include "Lighting.cginc"	
	#include "Assets/CGInclude/LGameStarActorCG.cginc"
	sampler2D _DiamondMap;
	float4  _DiamondMap_ST;
	float    _GlintSpeed;
	half	_GlintStrength;
	half	_GlintPower;
	sampler2D _DetailNormalMap;
	float4  _DetailNormalMap_ST;
	half    _DetailSpecularStrength;
	half	_DetailSpecularPower;
	struct ChiffonData
	{
		half3 diffuse;
		half3 specular;
		half3 normal;
		half3 detail_normal;
		half3 view;
		half3 occlusion;
		half metallic;
		half smoothness;
		half roughness;
		half perceptual_roughness;
		half one_minus_reflectivity;
		half glint;
	};
	struct v2f_cloth
	{
		half4 pos				: SV_POSITION;
		half4 uv				: TEXCOORD0;
		half4 detail_uv			: TEXCOORD1;
		half3 viewDir           : TEXCOORD2;
		half4 tangentToWorld[3]	: TEXCOORD3;
		LGAME_STARACTOR_SHADOW_COORDS(6)
	};
	half Glint(half3 viewDir, half3 diamond)
	{
		half random = viewDir.x + viewDir.y + viewDir.z + diamond.r;
		float glint = frac(random) * diamond.g;
		glint = pow(glint, _GlintPower)*diamond.b;
		glint *= (frac(sin(_Time.y*_GlintSpeed)*0.25 + random)*0.5 + 0.5)*_GlintStrength;
		return glint;
	}
	ChiffonData ChiffonDataSetup(v2f_cloth i)
	{
		ChiffonData chiffon;
		half4 albedo = tex2D(_MainTex, i.uv.xy) * _Color;
		albedo.rgb = GammaToLinearSpace(albedo.rgb);
#ifdef _METALLICGLOSSMAP
		half2 metallic_smoothness = tex2D(_MetallicGlossMap, i.uv.xy).rg;
		chiffon.metallic = metallic_smoothness.r;
		chiffon.smoothness = metallic_smoothness.g * _GlossMapScale;
#else
		chiffon.metallic = _Metallic;
		chiffon.smoothness = _Glossiness;
#endif
		half4 _ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
		half3 normal = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
		chiffon.normal = normalize(i.tangentToWorld[0].xyz*normal.r + i.tangentToWorld[1].xyz*normal.g + i.tangentToWorld[2].xyz*normal.b);
#ifdef _OCCLUSION_UV1
		chiffon.occlusion = Occlusion(i.uv.zw);
#else
		chiffon.occlusion = Occlusion(i.uv.xy);
#endif
		half3 detail_normal = UnpackNormal(tex2D(_DetailNormalMap, i.detail_uv));
		chiffon.detail_normal = normalize(i.tangentToWorld[0].xyz*detail_normal.r + i.tangentToWorld[1].xyz*detail_normal.g + i.tangentToWorld[2].xyz*detail_normal.b);
		chiffon.normal = lerp(chiffon.normal,normalize(chiffon.normal + chiffon.detail_normal),chiffon.occlusion.b);
		
		half3 diamond = tex2D(_DiamondMap, i.detail_uv.zw);

		chiffon.view = normalize(i.viewDir);
		chiffon.glint = saturate(Glint(chiffon.view, diamond))*chiffon.occlusion.b;
		chiffon.smoothness =lerp(chiffon.smoothness,1.0, chiffon.glint);
		chiffon.metallic =lerp(chiffon.metallic,1.0, chiffon.glint);
		chiffon.perceptual_roughness = 1.0 - chiffon.smoothness;
		chiffon.roughness = max(0.001, chiffon.perceptual_roughness * chiffon.perceptual_roughness);
		chiffon.one_minus_reflectivity = (1 - chiffon.metallic) * _ColorSpaceDielectricSpec.a;
		chiffon.specular = lerp(_ColorSpaceDielectricSpec.rgb, albedo.rgb, chiffon.metallic);
		chiffon.diffuse = albedo.rgb* chiffon.one_minus_reflectivity;
		return chiffon;
	}

	half DetailSpecular(half3 halfDir, half3 detail_normal)
	{
		half detail_nh = saturate(dot(detail_normal, halfDir));
		return pow(detail_nh, _DetailSpecularPower)*_DetailSpecularStrength;
	}

	half4 LGAME_BRDF_PBS_CHIFFON(LGameGI gi, ChiffonData chiffon, half nv, half nl, half atten)
	{
		half3 halfDir = normalize(gi.direct.dir + chiffon.view);
		half nh = saturate(dot(chiffon.normal, halfDir));
		half lh = saturate(dot(gi.direct.dir, halfDir));
		nl = saturate(nl);
		half effect = chiffon.glint;
		effect *= DetailSpecular(halfDir, chiffon.detail_normal)*chiffon.occlusion.b;
		effect = saturate(effect);

		half3 diffuseTerm = gi.direct.color * atten * nl;
		float a2 = chiffon.roughness * chiffon.roughness;
		half d = nh * nh * (a2 - 1.h) + 1.00001h;
		half specularTerm = a2 / (max(0.1h, lh*lh) * (chiffon.roughness + 0.5h) * (d * d) * 4);
		half surfaceReduction = (0.6 - 0.08*chiffon.perceptual_roughness);
		surfaceReduction = 1.0 - chiffon.roughness *chiffon.perceptual_roughness * surfaceReduction;
		half grazingTerm = saturate(chiffon.smoothness + 1.0 - chiffon.one_minus_reflectivity);
		half3 color = (chiffon.diffuse + specularTerm * chiffon.specular)*diffuseTerm
			+ gi.indirect.specular * effect
			+ gi.indirect.diffuse * chiffon.diffuse
			+ surfaceReduction * gi.indirect.specular * FresnelLerpFast(chiffon.specular, grazingTerm, nv);
		return half4(color, 1.0);
	}
	half4 LGAME_BRDF_PBS_CHIFFON_ADD(LGameDirectLight direct, ChiffonData chiffon,half atten)
	{
		half3 viewDir = normalize(chiffon.view);
		half nl = saturate(dot(chiffon.normal, direct.dir));
		half3 halfDir = normalize(direct.dir + viewDir);
		half lh = saturate(dot(direct.dir, halfDir));
		half nh = saturate(dot(chiffon.normal, halfDir));
		half3 diffuseTerm = direct.color * atten * nl;
		float a2 = chiffon.roughness * chiffon.roughness;
		float d = nh * nh * (a2 - 1.f) + 1.00001f;
		half specularTerm = a2 / (max(0.1f, lh*lh) * (chiffon.roughness + 0.5f) * (d * d) * 4);
		half3 color = chiffon.diffuse * diffuseTerm
			+ specularTerm * diffuseTerm;
		return half4(color, 1.0);
	}
	ENDCG
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "AlphaTest" "PerformanceChecks" = "False" }
		LOD 300
		Stencil {
			Ref 16
			Comp always
			Pass replace
		}
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
			#pragma multi_compile _ _FASTEST_QUALITY
			#pragma multi_compile _ _HARD_SHADOW _SOFT_SHADOW
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			v2f_cloth vert(a2v v)
			{
				v2f_cloth o;
				UNITY_INITIALIZE_OUTPUT(v2f_cloth,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;

				o.detail_uv.xy= TRANSFORM_TEX(v.uv0, _DetailNormalMap);
				o.detail_uv.zw = TRANSFORM_TEX(v.uv0, _DiamondMap);

				o.viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				LGAME_STARACTOR_TRNASFER_SHADOW(o);
				return o;
			}
			//片元着色器
			fixed4 frag(v2f_cloth i) : SV_Target
			{
				ChiffonData chiffon = ChiffonDataSetup(i);
				half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				LGameGI gi = FragmentGI(wPos, chiffon.view,chiffon.normal, chiffon.occlusion.r, chiffon.perceptual_roughness);
				half nl = dot(chiffon.normal, gi.direct.dir);
				half nv = saturate(dot(chiffon.normal, chiffon.view));
				LGAME_STARACTOR_LIGHT_ATTENUATION(atten, i, wPos, nl);
				fixed4 col = LGAME_BRDF_PBS_CHIFFON(gi, chiffon, nv, nl, atten);
				col.rgb = LinearToGammaSpace(col.rgb);
				col.rgb += LGame_RakingLight(wPos, chiffon.view, chiffon.normal, nv, atten, chiffon.occlusion.g);
				return col;
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
			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _OCCLUSION_UV1
			v2f_cloth vertAdd(a2v v)
			{
				v2f_cloth o;
				UNITY_INITIALIZE_OUTPUT(v2f_cloth,o);
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
				o.uv.zw = v.uv1;
				o.viewDir = normalize(UnityWorldSpaceViewDir(posWorld));
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;
				return o;
			}
			half4 fragAdd(v2f_cloth i) : SV_Target
			{
				ChiffonData chiffon = ChiffonDataSetup(i);
				half3 wPos = half3(i.tangentToWorld[0].w, i.tangentToWorld[1].w, i.tangentToWorld[2].w);
				UNITY_LIGHT_ATTENUATION(atten, i, wPos);
				LGameDirectLight direct = LGameDirectLighting(wPos);
				fixed4 col = LGAME_BRDF_PBS_CHIFFON_ADD(direct, chiffon,atten);
				col.rgb = LinearToGammaSpace(col.rgb);
				return col;
			}
			ENDCG
		}
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual
			CGPROGRAM
			#pragma vertex Vert_Shadow
			#pragma fragment Frag_Shadow
			#pragma multi_compile_shadowcaster
			#pragma skip_variants SHADOWS_CUBE
			#include "Assets/CGInclude/LGameStarActorShadowCaster.cginc"
			ENDCG
		}
	}	
	CustomEditor "LGameSDK.AnimTool.LGameStarActorStageClothShaderGUI"
}
