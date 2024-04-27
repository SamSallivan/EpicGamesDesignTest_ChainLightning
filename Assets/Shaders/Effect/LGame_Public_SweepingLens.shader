Shader "LGame/Public/SweepingLens"
{
    Properties
    {
		_Color1("Color1" , Color) = (1,0,0,1)
		_Color2("Color2" , Color) = (1,0,0,1)
		_Speed("Speed" , float) = 1
		_MaxScale("Max Scale" , Range(0,4)) = 1.2
		_AlphaCtrl("AlphaCtrl",range(0,1)) = 1

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", float) = 0.0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			#pragma multi_compile __ _USE_DIRECT_GPU_SKINNING

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "Assets/CGInclude/LGameCharacterDgs.cginc" 

            struct appdata
            {
                float4 vertex	: POSITION;
				fixed4 color	: COLOR;
#ifdef _USE_DIRECT_GPU_SKINNING
				float4 skinIndices : TEXCOORD2;
				float4 skinWeights : TEXCOORD3;
#endif
            };

            struct v2f
            {
                float4 vertex	: SV_POSITION;
				fixed4 col		:COLOR; 
            };

			fixed4 	_Color1;
			fixed4 	_Color2;
			half	_Speed;
			half	_MaxScale;
			half	_AlphaCtrl;

            v2f vert (appdata v)
            {
                v2f o;
				float4 pos = v.vertex;
#if _USE_DIRECT_GPU_SKINNING 
			   
				pos = CalculateGPUSkin_L(v.skinIndices, v.skinWeights, v.vertex);
#endif
				half weight = abs(frac(_Time.y * _Speed) -0.5) * 2;
				pos.xyz *= lerp(1, _MaxScale,weight);
                o.vertex = UnityObjectToClipPos(pos);
				o.col = lerp(_Color1 , _Color2 , weight);
				o.col.a *= _AlphaCtrl;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
