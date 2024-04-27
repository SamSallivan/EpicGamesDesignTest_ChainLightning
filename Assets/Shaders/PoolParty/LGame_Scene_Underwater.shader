Shader "LGame/Scene/Underwater"{
	Properties{
		[Header(Default)]
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)",2D) = "white"{}
		[Header(Caustic)]
		_CausticsStrength("Caustic Strength",Float) = 0.365
		_CausticsScale("Caustic Scale",Float) = 0
		_CausticsStartLevel("Caustic Start Level",Float) = 0
		_CausticsShallowFadeDistance("Caustic Shallow Fade Distance",Float) = 0
		[Header(Static Caustic)]
		_CausticMap("Static Caustic Map",2D) = "white"{}
		_CausticsDrift("Static Caustic Drift",Vector) = (0,0,0,0)
		_AmbientColor("Ambient Color",Color) = (0,0,0,0)
		_LightOrientationRow0("",Vector) = (0,0,0,0)
		_LightOrientationRow1("",Vector) = (0,0,0,0)
		_LightOrientationRow2("",Vector) = (0,0,0,0)
		_LightOrientationRow3("",Vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags{ "Queue" = "Geometry"  "RenderType" = "Opaque" }

		Pass
		{
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#pragma multi_compile _DYNAMIC_CAUSTIC _STATIC_CAUSTIC
			fixed4	_Color;
			fixed4	_AmbientColor;
			sampler2D _MainTex;
			#if _STATIC_CAUSTIC
				sampler2D	_CausticMap;
			#endif
			float4	_MainTex_ST;
			half _WaterHeight;
			half _CausticsShallowFadeDistance;
			half _CausticsScale;
			half _CausticsStrength;
			float4 _CausticsDrift;
			float4 _LightOrientationRow0;
			float4	_LightOrientationRow1;
			float4	_LightOrientationRow2;
			float4	_LightOrientationRow3;
		struct a2v
		{
			half4 uv		:TEXCOORD0;
			half4 uv0		:TEXCOORD1;
			half4 vertex	:POSITION;
			half3 normal	:NORMAL;
		};

		struct v2f
		{
			float4 vertex		:SV_POSITION;
			half4 uv			:TEXCOORD0;
			half3 wPos			:TEXCOORD1;
			half3 normal		:TEXCOORD2;
		};

	v2f vert(a2v v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);
		o.uv.zw = v.uv0 * unity_LightmapST.xy + unity_LightmapST.zw;
		o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		o.normal = UnityObjectToWorldNormal(v.normal);
		return o;
	}
	float CausticMap(float2 uv, float time) {
		float3x3 mat = float3x3(2, 1, -2, 3, -2, 1, 1, 2, 2);
		float3 vec1 = mul(mat*0.5, float3(uv, time));
		float3 vec2 = mul(mat*0.4, vec1);
		float3 vec3 = mul(mat*0.3, vec2);
		float caustic = min(length(frac(vec1) - 0.5), length(frac(vec2) - 0.5));
		caustic = min(caustic, length(frac(vec3) - 0.5));
		caustic = pow(caustic, 7.0)*25.;
		return caustic;
	}
	fixed4 frag(v2f i) : COLOR
	{
		//基本颜色
		half4 col = tex2D(_MainTex,i.uv) * _Color;
		float4x4 lightOrientation = float4x4(_LightOrientationRow0, _LightOrientationRow1, _LightOrientationRow2, _LightOrientationRow3);
		// Caustics projection for texels below water level
		if (i.wPos.y < _WaterHeight) {
			// Fade out caustics for shallow water
			float fadeFactor = min(1.0f, (_WaterHeight - i.wPos.y) / _CausticsShallowFadeDistance);
			float3 upVec = float3(0, 1, 0);
			float belowFactor = min(1.0, max(0.0, dot(i.normal, upVec) + 0.5));
			// Calculate the projected texture coordinate in the caustics texture
#if _DYNAMIC_CAUSTIC
			float3 worldCoord = i.wPos/_CausticsScale;
#elif _STATIC_CAUSTIC
			float3 drift = _CausticsDrift * _Time.y;
			float3 worldCoord = (i.wPos + drift) / _CausticsScale;
#endif
			float2 causticsUV = mul(float4(worldCoord,1), lightOrientation).xy;
			// Calculate caustics light emission
			#if _DYNAMIC_CAUSTIC
				col.rgb += CausticMap(causticsUV,_Time.y) * fadeFactor * belowFactor*_CausticsStrength;
			#elif _STATIC_CAUSTIC
				col.rgb += tex2D(_CausticMap,causticsUV) * fadeFactor * belowFactor*_CausticsStrength;
			#endif
		}
		fixed4 lightmap = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv.zw);
		lightmap = fixed4(DecodeLightmap(lightmap), 1);
		col.rgb = col.rgb * (lightmap + _AmbientColor.rgb);
		return fixed4(col.rgb, 1);
	}
		ENDCG
	}
	Pass
	{
		Tags{ "LightMode" = "ShadowCaster" }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_shadowcaster
		#include "UnityCG.cginc"

		struct v2f {
			V2F_SHADOW_CASTER;
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			return o;
		}

		float4 frag(v2f i) : SV_Target
		{
			SHADOW_CASTER_FRAGMENT(i)
		}
		ENDCG
		}
	}
}
