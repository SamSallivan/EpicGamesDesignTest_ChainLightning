Shader "LGame/Scene/GrasswithFlower"
{
    Properties
    {
        [HideInInspector] _Mode("__mode", Float) = 0.0
        _Color                    ("草的颜色", Color) = (1,1,1,1)
        _SubColor                ("草第二种颜色",Color)=(1,1,1,1)
        _SubColorStrength        ("颜色切换",Range(0,1))=0.0
        _MainTex                ("Texture", 2D) = "white" {}
        _Offesetx                ("花蒙版所在位置",Range(0,1)) = 0.316
        _FlowerGrow                ("花生长程度0开始生长0.5生长完成",Range(0,0.5)) = 0.0
        _FlowerColor            ("花的颜色",Color)=(1,1,1,1)
        //_Temp1("_Temp1", 2D) = "white" {}
        _LightMap ("LightMap", 2D) = "gray" {}
        _LightMapIntensity("LightMap Intensity",  Range(0,1)) = 1
        _AmbientCol("Ambient Color" , Color) = (0,0,0,0)
        [HideInInspector]_WaverIntensity ("Waver Intensity",  Range(0,1)) = 0.15
        [HideInInspector]_WaverHighCurve  ("Waver High Curve",  Range(0,10)) = 2
        [HideInInspector]_WaverSpeed("Waver speed",  Range(0,10)) = 1
        [HideInInspector]_WaverSpeedNoise("Waver speed Noise",  Range(0,10)) = 1

        [HideInInspector]_HighLightVal("HighLight Value" ,Range(0,1)) = 0
        [SimpleToggle] _EnableLDR("Enable LDR", Float) = 0
        [Toggle] _IsDissolveSecond ("Is DissolveSecond?", Int) = 0  // 溶解世界反向（比如铁男大招  半径内半径外通过该参数取反 或者两个效果溶解切换的表现）

    }

    CGINCLUDE
        #include "UnityCG.cginc"
        #include "Assets/CGInclude/LGameFog.cginc"
        struct appdata
        {
            float4 vertex    : POSITION;
            fixed4 color : COLOR;
            float2 uv        : TEXCOORD0;
            float2 uv2        : TEXCOORD1;
        };

        struct v2f
        {
            float4 vertex    : SV_POSITION;
            float2 uv        : TEXCOORD0;
            float2 uv2        : TEXCOORD1;
            float4 worldPos    :  TEXCOORD2;
#if _FOW_ON || _FOW_ON_CUSTOM
            half2 fowuv        : TEXCOORD3;
#endif
#if (_SOFTSHADOW_ON )
            half4 srcPos    : TEXCOORD4;
#endif

        };

        fixed4                _Color;
        fixed4                _SubColor;
        half                _SubColorStrength;
        sampler2D            _MainTex;
        float4                _MainTex_ST;
        fixed4                _FlowerColor;
        half                _Offesetx;
        half                _FlowerGrow;
        half                _Brightness;
    
#if _LIGHTMAP_ON
        sampler2D            _LightMap;
        fixed4                _AmbientCol;
        half                _LightMapIntensity;
        half                _EnableLDR;
#endif

#if (_SOFTSHADOW_ON )
        fixed4                _ShadowColor;
        sampler2D            _ShadowPrepassTexture;
        half                _WaverSpeedNoise;
#endif
        half                _WaverIntensity;
        half                _WaverHighCurve;
        half                _WaverSpeed;
        float4                _Character_Pos;//x,z 提供坐标，y,提供衰弱，w提供抖动判断
        float4                _Character_Info;
        half                _HighLightVal;
    
        float _IsDissolveSecond;
        #if _ENABLE_DISSOLVE_WORLD
	        uniform vector _DissolveWorldPos;		// 溶解世界 - 中心坐标
	        uniform float _DissolveWorldRadius;		// 溶解世界 - 半径（控制溶解切换的面积）
	        uniform float _DissolveWorldAmount;		// 溶解世界 - 过渡距离（控制过渡边缘效果，默认值0.1）
        #endif

        // 场景过渡：溶解切换
        inline void LGameApplyDissolveWorld(inout float4 finalCol, in float3 worldPos)
        {
	        // 两个场景动态溶解切换过渡效果
	        #if _ENABLE_DISSOLVE_WORLD
		        float3 dis = distance(_DissolveWorldPos, worldPos.xyz); // TODO: 这个后续可以修改为基于相机的距离
		        float3 R = 1 - saturate(dis/_DissolveWorldRadius);  // 获取区域面积信息
                float alpha = 0;
		        if(_IsDissolveSecond == 1) // TODO: 效率优化
		        {
		            alpha = step(R, _DissolveWorldAmount);
		        }
		        else
		        {
			        alpha = step(_DissolveWorldAmount, R);
		        }
                if(alpha == 0)
			    {
				    finalCol.rgb = half3(0,0,0);
			    }
		        // finalCol.a = 0.1;
		        clip(alpha - 0.001);
	        #endif
        }
//        inline float4 AnimateVertex2(float3 worldPos)
//        {
//
//            float2 offset = float2(0, 0);
////#if (_SOFTSHADOW_ON && _RECEIVE_ON)
//                        half4 shadow = tex2Dproj(_Temp1, i.srcPos.xy / i.srcPos.w);
//                        col.rgb = lerp(col.rgb, _ShadowColor.rgb, shadow);
//                        offset = shadow.xy* _WaverSpeedNoise;
////            #endif
//
//            offset += (sin((_Time.y + worldPos.xz - worldPos.y * _WaverHighCurve)*_WaverSpeed) *_WaverIntensity) * worldPos.y*0.5;
//            worldPos.xz += offset;
//            return float4(worldPos, 1);
//        }
        v2f vert(appdata v)
        {
            v2f o;
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            half highMask = saturate(worldPos.y*0.9)* saturate(worldPos.y * 2);
            //half highMask = saturate(worldPos.y);//优化方案
            float distanceRangeR = distance(float3(_Character_Pos.x, 0, _Character_Pos.z), worldPos.xyz);
            half DtoPower = min(1, max(0, -distanceRangeR*0.8 + 1+ _Character_Info.x));
            //half DtoPower = smoothstep(_Character_Info.x, distanceRangeR, _Character_Info.y);
            //DtoPower = smoothstep(0.0,1, DtoPower);
            //DtoPower *= DtoPower;
            float2 offset = float2(0, 0);
            float2 offset2 = float2(0, 0);
            float3 timePosChange = float3(_Time.y, worldPos.zx - worldPos.y * _WaverHighCurve);
            //使用软阴影RT来帮助扰动
            #if (_SOFTSHADOW_ON )
                    float4 shadow = float4(1, 1, 1, 1);
                    o.srcPos = ComputeScreenPos(UnityWorldToClipPos(worldPos.xyz));
                    float2 SPUV = o.srcPos.xy / o.srcPos.w;
            //为了适配DX平台，将UV的Y轴进行翻转，在这里通过UV原点判断，原点在上即为DX平台
            #if UNITY_UV_STARTS_AT_TOP
                    float scale=1 - SPUV.y;
            #else
                    float scale=SPUV.y;
            #endif
                    shadow = tex2Dlod(_ShadowPrepassTexture, float4(SPUV.x,scale, 0, 0));
                    offset += sin(abs(frac(timePosChange.yz + _Time.y) - 0.5) * _Character_Info.w) * 0.3 * shadow * _Character_Pos.y;//
                    //DtoPower = max(DtoPower, shadow);
            #endif
            float4 useToSin = float4(float2(abs(frac(timePosChange.yz + _Time.y * _Character_Pos.w) - 0.5) * _Character_Info.w* _Character_Pos.y), float2((_Time.y + timePosChange.yz) * _WaverSpeed));
            float4 afterSin = sin(useToSin);//合并优化sin计算
            offset += afterSin.xy * worldPos.y * DtoPower;//
            offset2 += afterSin.zw * _WaverIntensity * worldPos.y * 0.5;
            worldPos.xz = worldPos.xz + offset2 * highMask * v.color.a + DtoPower * highMask * _Character_Info.z * normalize(worldPos.xz - _Character_Pos.xz) * _Character_Pos.y + offset * highMask ;//
            float4 mdlPos = float4(worldPos, 1);
            o.vertex = UnityWorldToClipPos(mdlPos.xyz);
            o.worldPos.xyz = worldPos;
            o.worldPos.w = DtoPower;
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.uv2 = v.uv2;
#if _FOW_ON || _FOW_ON_CUSTOM
            o.fowuv = half2 ((worldPos.x - _FOWParam.x) / _FOWParam.z, (worldPos.z - _FOWParam.y) / _FOWParam.w);
#endif
            return o;
        }
    ENDCG
        SubShader
        {
        Tags { "RenderType"="Opaque"  "RenderType"="AlphaTest" }
        LOD 100
        //Pass
        //{
        //    Name "PreZ"
        //    Tags { "LightMode" = "ForwardBase" }
        //    ColorMask 0
        //
        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //
        //    #include "UnityCG.cginc"
        //
        //    fixed4 frag (v2f i) : SV_Target
        //    {
        //        fixed alpha = tex2D(_MainTex, i.uv).a * saturate( i.worldPos.y * 3);
        //        clip(alpha - 0.99);
        //        return 0;
        //    }
        //    ENDCG
        //}
        Pass
        {
            Name "FORWARD"
            BlendOp [_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
            #pragma shader_feature _LIGHTMAP_ON
            #pragma multi_compile __ _SOFTSHADOW_ON
            #include "UnityCG.cginc"
            fixed4 frag (v2f i) : SV_Target
            {
                fixed highLight = _HighLightVal * 2;
                /*---------------------------------------------此处为核心逻辑，其余与草丛shader几乎相同--------------------------------*/
                //花朵生长核心逻辑
                half2 flowuv = i.uv;
                half flowerpart = step(i.uv.x, _Offesetx);
                flowuv.y += (0.5-_FlowerGrow ) * flowerpart;
                fixed4 col = tex2D(_MainTex,flowuv);
                //草丛两种颜色切换
                fixed4 grasscol=lerp(_Color,_SubColor,_SubColorStrength);
                col *=lerp(grasscol,_FlowerColor,flowerpart);
                /*---------------------------------------------核心逻辑计算完成------------------------------------------------------*/
                #if _FOW_ON || _FOW_ON_CUSTOM
					LGameFogApply(col, i.worldPos.xyz, i.fowuv);
            	#endif
                #if _LIGHTMAP_ON
                    fixed3 lightMap = tex2D(_LightMap, i.uv2);
                    col.rgb = col.rgb + (lightMap * 2.0 - 1.0) * (1.0 - _EnableLDR) * _LightMapIntensity;
                    col.rgb = col.rgb * lerp(1.0.rrr, lightMap * 2.0, _EnableLDR * _LightMapIntensity);
                    col.rgb *= 1.0 + _AmbientCol;
                #endif
                    //half4 shadow = float4(1, 1, 1, 1);
//#if (_SOFTSHADOW_ON && _RECEIVE_ON)
                    //float4    shadow = tex2D(_ShadowPrepassTexture, float2(i.srcPos.x, -i.srcPos.y )/ i.srcPos.w);
//#endif
                col.rgb *= 1 + _Brightness + highLight;
                col.a *= saturate(i.worldPos.y * 3);
                return col;
            }
            ENDCG
        }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "GrassSrp" }
            BlendOp [_BlendOp]
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ _FOW_ON _FOW_ON_CUSTOM
            #pragma shader_feature _LIGHTMAP_ON
            #pragma multi_compile __ _SOFTSHADOW_ON
            #pragma multi_compile __ _ENABLE_DISSOLVE_WORLD
            
            #include "UnityCG.cginc"
            fixed4 frag (v2f i) : SV_Target
            {
                fixed highLight = _HighLightVal * 2;
                /*---------------------------------------------此处为核心逻辑，其余与草丛shader几乎相同--------------------------------*/
                //花朵生长核心逻辑
                half2 flowuv = i.uv;
                half flowerpart = step(i.uv.x, _Offesetx);
                flowuv.y += (0.5-_FlowerGrow ) * flowerpart;
                fixed4 col = tex2D(_MainTex, flowuv);
                //草丛两种颜色切换
                fixed4 grasscol=lerp(_Color,_SubColor,_SubColorStrength);
                col *=lerp(grasscol,_FlowerColor,flowerpart);
                /*---------------------------------------------核心逻辑计算完成------------------------------------------------------*/
                
                #if _FOW_ON || _FOW_ON_CUSTOM
                    LGameFogApply(col, i.worldPos.xyz, i.fowuv);
                #endif
                
                #if _LIGHTMAP_ON
                    fixed3 lightMap = tex2D(_LightMap, i.uv2);
                    col.rgb = col.rgb + (lightMap * 2.0 - 1.0) * (1.0 - _EnableLDR) * _LightMapIntensity;
                    col.rgb = col.rgb * lerp(1.0.rrr, lightMap * 2.0, _EnableLDR * _LightMapIntensity);
                    col.rgb *= 1.0 + _AmbientCol;
                #endif
                col.rgb *= 1 + _Brightness + highLight;
                col.a *= saturate(i.worldPos.y * 3);

                // Apply Dissolve World
		        #if _ENABLE_DISSOLVE_WORLD
			        LGameApplyDissolveWorld(col, i.worldPos.xyz);
		        #endif
                
                return col;
            }
            ENDCG
        }
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 10

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Fog { Mode Off }

            CGPROGRAM
            #include "Assets/CGInclude/RenderDebugCG.cginc"
            #pragma vertex vert
            #pragma fragment frag_mipmap  

            fixed4 frag_mipmap(v2f i) : SV_Target
            {
                fixed3 c = 0;
                fixed4 tex = tex2D(_MainTex, i.uv);
                c = tex.rgb;

                return GetMipmapsLevelColor(c,i.uv);
            }
            
            ENDCG
        }
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 5
        Blend One One

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag  

            // fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(0.15, 0.06, 0.03, 0);
            }
            
            ENDCG
        }
    }
    


    //CustomEditor"LGameScenceGrassWithFlowerGUI"
}
