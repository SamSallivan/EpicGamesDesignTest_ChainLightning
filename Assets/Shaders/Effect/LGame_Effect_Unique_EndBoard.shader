Shader "LGame/Effect/Unique/EndBoard"
{
    Properties
    {
		[HideInInspector] _OptionMode("__OptionMode",float) = 0	
		[HideInInspector] _BlendMode ("__BlendMode",float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
		[Enum(Off, 0, On, 1)] _ZWriteMode ("__ZWriteMode", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("__CullMode", float) = 2
		[Enum(Less, 2, Greater, 5 ,Always , 8)] _ZTestMode ("__ZTestMode", Float) = 2

		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}

		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5


		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Scale", Float) = 1.0
		
		_ReflectionColor("Reflection Color", Color) = (0.5 , 0.5 , 0.5 , 0)

		_ReflectionMatCap ("Reflection MatCap", 2D) = "" {}

		[hdr]_LightCol("Light Color" , Color) = (1,1,1,1)
		_LightDir("Light Direction" , vector) = (0,1,0,0)

		[hdr]_EmissionColor("Color", Color) = (0,0,0)						    
		_EmissionMap("Emission", 2D) = "white" {}	

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
        LOD 100

        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWriteMode]
        ZTest [_ZTestMode]
        Cull [_CullMode]
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex	: POSITION;
				float3 normal	: NORMAL;
				half4 tangent	: TANGENT;
                float2 uv		: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex			: SV_POSITION;
				float4 uv				: TEXCOORD0;
				half4 tangentToWorld[3]	: TEXCOORD1; 
            };

			fixed4		_Color;
            sampler2D	_MainTex;
            float4		_MainTex_ST;

			sampler2D	_BumpMap;
			float4		_BumpMap_ST;
			half		_BumpScale;

			half		_Metallic;
			half		_Glossiness;


			fixed4		_ReflectionColor;
			half		_ReflectionMapScale;
			sampler2D	_ReflectionMatCap;

			half4		_LightCol;
			half4		_LightDir;

				sampler2D	_EmissionMap;
				half4		_EmissionColor;	

			inline half Pow4 (half x)
			{
			    return x*x*x*x;
			}
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _BumpMap);

				//世界空间顶点坐标
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorld[0].w = posWorld.x;
				o.tangentToWorld[1].w = posWorld.y;
				o.tangentToWorld[2].w = posWorld.z;

				//切线转世界空间的矩阵
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float3 tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				half3 binormalWorld = cross(normalWorld, tangentWorld) * v.tangent.w * unity_WorldTransformParams.w;
				o.tangentToWorld[0].xyz = tangentWorld;
				o.tangentToWorld[1].xyz = binormalWorld;
				o.tangentToWorld[2].xyz = normalWorld;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				half3 worldPos = half3(i.tangentToWorld[0].w , i.tangentToWorld[1].w , i.tangentToWorld[2].w);
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half3 worldLightDir = normalize(_LightDir.xyz);
				half3 halfDir = normalize(worldViewDir + worldLightDir);

				half3 tangent = i.tangentToWorld[0].xyz;
				half3 binormal = i.tangentToWorld[1].xyz;
				half3 normal = i.tangentToWorld[2].xyz;
				half3 normalTangent = UnpackNormalWithScale(tex2D (_BumpMap, i.uv.zw), _BumpScale) ;
				half3 worldNormal = normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);

				fixed4 texCol = tex2D(_MainTex, i.uv) * _Color;


				half metallic = _Metallic;
				half smoothness = _Glossiness;


				half nh = saturate(dot(worldNormal, halfDir));
				half lh = saturate(dot(worldLightDir, halfDir));
				half nv = abs(dot(worldNormal, worldViewDir));

				// Specular term
				half perceptualRoughness = 1 - smoothness;
				half roughness = perceptualRoughness * perceptualRoughness;
				half a = roughness;
				half a2 = a * a;
				half d = nh * nh * (a2 - 1.h) + 1.00001h;
				half specularTerm = a / (max(0.32h, lh) * (1.5h + roughness) * d);

				half3 specColor = lerp(0.22.rrr, texCol.rgb, _Metallic);

				// Reflection
				perceptualRoughness = perceptualRoughness * (1.7 - 0.7*perceptualRoughness);
				half mip = perceptualRoughness * 6;

				
				half3 viewNormal = mul(UNITY_MATRIX_V , half4(worldNormal.xyz,0)).xyz;
				half3 viewPos = UnityWorldToViewPos(worldPos);
				float3 r = normalize(reflect(viewPos, viewNormal));
				float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
				half2 matcapUV = r.xy/m + 0.5;

				fixed4 ReflectionMatcapCol = tex2Dlod(_ReflectionMatCap , half4(matcapUV, 0, mip)) * _ReflectionColor;

				half oneMinusReflectivity = (1 - _Metallic) * 0.78;
				half3 diffColor = texCol.rgb * oneMinusReflectivity ;
		
				half surfaceReduction = (0.6 - 0.08*perceptualRoughness);
				half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

				half fresnel = Pow4(1 - nv);					
				half alpha = lerp(texCol.a , ReflectionMatcapCol.a, fresnel) ;

				half3 emission = tex2D(_EmissionMap, i.uv.xy).rgb * _EmissionColor.rgb; 


				half3 col = diffColor + specularTerm * specColor * _LightCol + 	emission +
							ReflectionMatcapCol * lerp(  specColor, grazingTerm, fresnel); 

                return half4(saturate( col * _Color.a), _Color.a);
            }
            ENDCG
        }
    }
}
