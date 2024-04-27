/********************************************************************************************************
@YcanLiao
2017-07-28 10:28:40

基于深度图的水Shader
根据深度在交界处逐渐透明，并产生冲击岸边的海浪

不能接收实时光
*********************************************************************************************************/
Shader "LGame/Scene/Wave_depth_water"
{
	Properties {	
    _WaterColor("WaterColor",Color) = (0,0.25,0.4,1)//海水颜色
    _FarColor("FarColor",Color)=(0.2,1,1,0.3)//反射颜色
	_WaterTex("Water Texture", 2D) = "white" {}//主纹理

	[Space(20)]
	_NoiseTex("Noise", 2D) = "white" {} //海浪躁波纹理
	_NoiseIntensity ("Noise Intensity", Range(0,10)) = 1//海浪躁波强度
	_NoiseWaveDir("Noise Wave Direction(xy&zw)",vector)=(1,1,-1,1)//纹理流动方向

	[Space(20)]
	[hdr]_EdgeColor("EdgeColor",Color)=(0,1,1,0)//边缘颜色
	_EdgeTex("EdgeTex",2D)="white" {}//边缘贴图

	_EdgeRange("Edge Range",Range(0.1,10))=.4//边缘过渡强度
	_WaveSpeed("Wave Speed",Range(0,10))=1//海浪速度

	[Space(20)]
	_CurveTex("Curve Texture" , 2D) = "white" {}//曲线贴图
	_DepthTex("DepthTex",2D)="white" {}//海浪贴图

	[Space(20)]
	_FogCol("Fog Color" , Color) = (0.02,0.0,0.07,0.6)//战争迷雾颜色
	}
		SubShader
		{
			Tags
			{ 

			"LightMode"="ForwardBase" 
            "Queue" = "AlphaTest-10"
			"IgnoreProjector"="true"
            "RenderType" = "TransparentCuout" 
            }
			
			LOD 200
		Pass
		{
			Name "FORWARD"
						
			//ColorMask RGB
			Fog { Mode Off }
			ZWrite off	
			Blend One OneMinusSrcAlpha

		    CGPROGRAM
	        #pragma vertex vert
	        #pragma fragment frag
			//#pragma multi_compile _FOW_OFF _FOW_ON _FOWX_ON
            #pragma target 3.0
            #include "UnityCG.cginc"

			fixed4 _WaterColor;
			fixed4 _FarColor;

			sampler2D _WaterTex;
			half4 _WaterTex_ST;

			sampler2D _NoiseTex;
			half4 _NoiseTex_ST;
			half _NoiseIntensity;
			half4 _NoiseWaveDir;

			sampler2D _CurveTex;
			half4 _CurveTex_ST;
			half _Test;

			sampler2D _EdgeTex;
			half4 _EdgeTex_ST;
			fixed4 _EdgeColor;
			half _EdgeRange;
			half _WaveSpeed;

			sampler2D _DepthTex;

		    
			struct a2v 
			{
				half4 vertex:POSITION;
				half4 texcoord:TEXCOORD0;
				half3 normal : NORMAL;
			};
			struct v2f
			{
				half4 pos : SV_POSITION;
				half4 uvMain : TEXCOORD0;
				half4 uvNoise : TEXCOORD1;
				half2 uvEdge : TEXCOORD2;
				//#ifndef _FOW_OFF
				//	half2 fowuv :TEXCOORD3;
				//#endif
				fixed4 color : COLOR;
			};



			v2f vert(a2v v)
			{
				v2f o;
				o.pos =  UnityObjectToClipPos(v.vertex);
			    float3 wPos		= mul(unity_ObjectToWorld,v.vertex).xyz;
				o.uvMain.xy		= v.texcoord; 
				o.uvMain.zw		= wPos.xz * _WaterTex_ST.xy * 0.1  + frac( _WaterTex_ST.zw * _Time.y);
			    o.uvNoise		= wPos.xzxz * _NoiseTex_ST * half4(0.1,0.1,0.13,0.13) + frac( _NoiseWaveDir * _Time.y);
				o.uvEdge		= wPos.xzxz * _EdgeTex_ST.xy  + frac( _EdgeTex_ST.zw * _Time.y);

			    half3 normal = UnityObjectToWorldNormal(v.normal);
			    half3 viewDir = WorldSpaceViewDir(v.vertex);
				half fresnel= 1-saturate(dot(normalize(normal) , normalize(viewDir))); 
				o.color = fresnel;

				//#if  _FOW_ON
				//	o.fowuv = float2((wPos.x -_FOWParam.x)/_FOWParam.z, (wPos.z -_FOWParam.y)/_FOWParam.w);
				//#endif

				return o;
			}


			fixed4 frag(v2f i):  SV_Target 
			{

				//噪音纹理
				half2 noise = (tex2D(_NoiseTex , i.uvNoise.xy) * tex2D(_NoiseTex , i.uvNoise.zw) * 2 - 1).xy * _NoiseIntensity;

				//海水颜色
			    fixed4 col = tex2D(_WaterTex , i.uvMain.zw + noise) *  _WaterColor;


			    //计算菲涅耳反射

			    col=lerp(col,_FarColor,i.color); 
				col.rgb *= col.a;
			    //计算海水边缘以及海浪
			    half depth = tex2D(_DepthTex,i.uvMain.xy).r;
			    depth = saturate(depth*_EdgeRange);  



			   	half wave1 = tex2D(_CurveTex , half2(.5- depth - _Time.y * _WaveSpeed , 0.1)+ noise*2 ).r;
				half wave2 = tex2D(_CurveTex , half2(1- depth - _Time.y * _WaveSpeed , 0.1)+ noise*2 ).r;
				
				half edgeTex = tex2D(_EdgeTex,i.uvEdge);
				
			    col += edgeTex*edgeTex * _EdgeColor * (wave2 + wave1)* (1- depth);
				
				//战争迷雾
				//#ifdef  _FOW_ON
				//	fixed fowTex = tex2D( _FOWTexture, i.fowuv ).r;
				//	col = fowTex;//lerp( _FogCol , 1 ,  1-fowTex);
				//#elif _FOWX_ON
				//	fixed fowTex = tex2D( _FOWTexture, i.fowuv ).a;
				//	col = lerp( _FogCol , 1 ,  1-fowTex);
				//#endif

				//#ifdef  _FOW_ON
				//	fixed4 fowTex = tex2D(_FOWTexture, i.fowuv);
				//	fixed4 fowLast = tex2D(_FOWLastTexture, i.fowuv);
				//	fixed b = smoothstep(0.5 - _RangeSize, 0.5 + _RangeSize, lerp(fowLast.r, fowTex.r, _FOWBlend));
				//	fixed4 fowCol = lerp(_FogRangeCol, _FogCol, b);

				//	col *= saturate(lerp(1.0.rrrr, fowCol, b * (1 - _FowBrightness)));
				//#endif

				col *= depth;

			    return col ;
			}
		ENDCG
		}
	}
	FallBack OFF
}