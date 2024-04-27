#ifndef LGAME_CHARACTER_INCLUDE
    #define LGAME_CHARACTER_INCLUDE
    #include "UnityCG.cginc" 
    struct appdata
    {
        float4 vertex	: POSITION;
        half4 color		: COLOR;
        half4 uv		: TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    struct v2f
    {
        half4 vertexCol	: COLOR;
        float4 pos		: SV_POSITION;
        float4 uvMain	: TEXCOORD0;
        float4 uvSub		: TEXCOORD1;
        #if defined(LGAME_USEFOW) && _FOW_ON
            half2 fowuv	: TEXCOORD2;
        #endif
        half2 customData :TEXCOORD3;
        float3 worldPos	: TEXCOORD4;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

	// Split the Instance Buffer used by VS and FS
    // to avoid 'screen garbled' bug on Adreno510.
	// (The rasterized pixel is different from the final pixel in Frame Buffer)
    // For optimal performance, each Instance Buffer cannot contain more than 32 floats.

	// Instance Buffer for VS
	UNITY_INSTANCING_BUFFER_START(VSIB1)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, _OffsetColor)
	#   define B_OffsetColor UNITY_ACCESS_INSTANCED_PROP(VSIB1,_OffsetColor)
		UNITY_DEFINE_INSTANCED_PROP(half, _OffsetColorLerp)
	#   define B_OffsetColorLerp UNITY_ACCESS_INSTANCED_PROP(VSIB1,_OffsetColorLerp)
        UNITY_DEFINE_INSTANCED_PROP(fixed, _ScaleOnCenter)
	#	define B_ScaleOnCenter UNITY_ACCESS_INSTANCED_PROP(VSIB1,_ScaleOnCenter)
		UNITY_DEFINE_INSTANCED_PROP(half4, _MainTex_ST)
	#   define B_MainTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MainTex_ST)
		UNITY_DEFINE_INSTANCED_PROP(half4, _MainTexTransform)
	#	define B_MainTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MainTexTransform)
		UNITY_DEFINE_INSTANCED_PROP(fixed, _MainTexUvMode)
	#	define B_MainTexUvMode UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MainTexUvMode)
		UNITY_DEFINE_INSTANCED_PROP(half4, _MaskTex_ST)
	#	define B_MaskTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MaskTex_ST)
		UNITY_DEFINE_INSTANCED_PROP(half4, _MaskTexTransform)
	#	define B_MaskTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MaskTexTransform)
		UNITY_DEFINE_INSTANCED_PROP(fixed, _MaskTexUvMode)
	#	define B_MaskTexUvMode UNITY_ACCESS_INSTANCED_PROP(VSIB1,_MaskTexUvMode)
	UNITY_INSTANCING_BUFFER_END(VSIB1)

	UNITY_INSTANCING_BUFFER_START(VSIB2)
        UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveTex_ST)
	#	define B_DissolveTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB2,_DissolveTex_ST)
		UNITY_DEFINE_INSTANCED_PROP(half4, _DissolveTexTransform)
	#	define B_DissolveTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB2,_DissolveTexTransform)
    	UNITY_DEFINE_INSTANCED_PROP(fixed, _DissolveTexUvMode)
	#	define B_DissolveTexUvMode UNITY_ACCESS_INSTANCED_PROP(VSIB2,_DissolveTexUvMode)
		UNITY_DEFINE_INSTANCED_PROP(half4, _WarpTex_ST)
	#	define B_WarpTex_ST UNITY_ACCESS_INSTANCED_PROP(VSIB2,_WarpTex_ST)
		UNITY_DEFINE_INSTANCED_PROP(half4, _WarpTexTransform)
	#	define B_WarpTexTransform UNITY_ACCESS_INSTANCED_PROP(VSIB2,_WarpTexTransform)
		UNITY_DEFINE_INSTANCED_PROP(fixed, _WarpTexUvMode)
	#	define B_WarpTexUvMode UNITY_ACCESS_INSTANCED_PROP(VSIB2,_WarpTexUvMode)
	UNITY_INSTANCING_BUFFER_END(VSIB2)
    
	// Instance Buffer for FS
	UNITY_INSTANCING_BUFFER_START(FSIB)
		UNITY_DEFINE_INSTANCED_PROP(half, _AlphaCtrl)
	#   define B_AlphaCtrl UNITY_ACCESS_INSTANCED_PROP(FSIB,_AlphaCtrl)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
	#   define B_Color UNITY_ACCESS_INSTANCED_PROP(FSIB,_Color)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, _MainWrapMode)
	#	define B_MainWrapMode UNITY_ACCESS_INSTANCED_PROP(FSIB,_MainWrapMode)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, _SubWrapMode)
	#	define B_SubWrapMode UNITY_ACCESS_INSTANCED_PROP(FSIB,_SubWrapMode)
		UNITY_DEFINE_INSTANCED_PROP(half, _DissolveValue)
	#	define B_DissolveValue UNITY_ACCESS_INSTANCED_PROP(FSIB,_DissolveValue)
		UNITY_DEFINE_INSTANCED_PROP(half, _DissolveRangeSize)
	#	define B_DissolveRangeSize UNITY_ACCESS_INSTANCED_PROP(FSIB,_DissolveRangeSize)
		UNITY_DEFINE_INSTANCED_PROP(fixed4, _DissolveRangeCol)
	#	define B_DissolveRangeCol UNITY_ACCESS_INSTANCED_PROP(FSIB,_DissolveRangeCol)
		UNITY_DEFINE_INSTANCED_PROP(half, _WarpIntensity)
	#	define B_WarpIntensity UNITY_ACCESS_INSTANCED_PROP(FSIB,_WarpIntensity)
		UNITY_DEFINE_INSTANCED_PROP(half, _FowBlend)
	#   define B_FowBlend UNITY_ACCESS_INSTANCED_PROP(FSIB,_FowBlend)
        UNITY_DEFINE_INSTANCED_PROP(half, _UseCustomData)
	#	define B_UseCustomData UNITY_ACCESS_INSTANCED_PROP(FSIB,_UseCustomData)
	UNITY_INSTANCING_BUFFER_END(FSIB)

    sampler2D   _MainTex;
    sampler2D	_MaskTex;
    sampler2D	_DissolveTex;
    sampler2D	_WarpTex;
    half4		_BillboardMatrix0;
    half4		_BillboardMatrix1;
    half4		_BillboardMatrix2;		

#if _FOW_ON
    sampler2D	_FOWTexture;
    sampler2D	_FOWLastTexture;
    fixed4		_FogCol;
    fixed4		_FogRangeCol;
    half		_FOWBlend;
    half		_FOWOpenSpeed;
    half4		_FOWParam;
    half		_RangeSize;
    half		_fow;
#endif
    half		_FowBrightness;
    fixed       _TimeScale;
    //onlyforUI
    #if RectClip_On
    float4      _EffectClipRect;
    #endif
    //sampler2D	_FOWTexture;
    //sampler2D	_FOWLastTexture;
    //half4		_FOWParam;	

    inline float2 RotateUV(float2 uv,float2 uvRotate)
    {
        float2 outUV;
        outUV = uv - 0.5 * B_ScaleOnCenter;
        outUV = float2(	outUV.x * uvRotate.y - outUV.y * uvRotate.x ,
                        outUV.x * uvRotate.x + outUV.y * uvRotate.y );
        return outUV + 0.5 * B_ScaleOnCenter;
    }
    inline float2 TransFormUV(float2 argUV,float4 argST , float4 trans)
    {
        float2 result =  RotateUV(argUV , trans.zw)  * argST.xy + argST.zw;
        result += B_ScaleOnCenter * (1 - argST.xy)*0.5;
        return result + frac(trans.xy * _Time.y * _TimeScale);
    }
    inline half2 ScreenUV(half4 pos)
    {
        half4 srcPos = ComputeScreenPos(pos);
        return srcPos.xy /srcPos.w;
    }
    //UI function
    inline float Get2DClipping (in float2 position, in float4 clipRect)
		{
			float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
			return inside.x * inside.y;
		}
    v2f vert (appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);

        #if _BILLBOARD_ON
            float3 center =  UnityWorldToViewPos(unity_ObjectToWorld._14_24_34) ;
            float3x3 m ;
            m[0] = _BillboardMatrix0.xyz;
            m[1] = _BillboardMatrix1.xyz;
            m[2] = _BillboardMatrix2.xyz;
            o.pos = mul(UNITY_MATRIX_P , float4(mul(m,v.vertex.xyz) + center, 1) );
        #else
            o.pos = UnityObjectToClipPos(v.vertex);
        #endif
        half2 uvScr = ScreenUV(o.pos);
        //mainTex UV Transfrom
        #if _SCREENUV_ON
             o.uvMain.xy = any(B_MainTexUvMode) ? uvScr : v.uv.xy;
             o.uvMain.zw = any(B_MaskTexUvMode) ? uvScr : v.uv.xy;
             o.uvSub.xy	 = any(B_DissolveTexUvMode) ? uvScr : v.uv.xy;
             o.uvSub.zw	 = any(B_WarpTexUvMode) ? uvScr : v.uv.xy;
        #else
             o.uvMain = v.uv.xyxy;
             o.uvSub = v.uv.xyxy;
        #endif
        o.uvMain.xy = TransFormUV(o.uvMain.xy, B_MainTex_ST, B_MainTexTransform);
        #if _MASK_ON
            o.uvMain.zw = TransFormUV(o.uvMain.zw, B_MaskTex_ST, B_MaskTexTransform);
        #endif
        #if _DISSOLVE_ON
            o.uvSub.xy	= TransFormUV(o.uvSub.xy , B_DissolveTex_ST , B_DissolveTexTransform);
            o.customData.xy = v.uv.zw;
        #endif
        #if	_WARP_ON
            o.uvSub.zw	= TransFormUV(o.uvSub.zw, B_WarpTex_ST, B_WarpTexTransform);
        #endif
        //UI region
        o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz,1.0)).xyz;
        #if defined(LGAME_USEFOW) && _FOW_ON
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.fowuv = half2 ((worldPos.x -_FOWParam.x)/_FOWParam.z, (worldPos.z -_FOWParam.y)/_FOWParam.w);
        #endif
		o.vertexCol.rgb = lerp(v.color.rgb, B_OffsetColor.rgb, B_OffsetColorLerp);
        o.vertexCol.a = v.color.a;
        return o;
    }
    fixed4 frag (v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        #if	_WRAPMODE_ON
            float4 uvSub = lerp(saturate(i.uvSub) , frac(i.uvSub) , B_SubWrapMode);
            float2 uvdissolveTex = uvSub.xy;
            float2 uvWarpTex = uvSub.zw;
        #   if	_WARP_ON
                fixed2 warpTex = UnpackNormal(tex2D(_WarpTex, uvWarpTex, float2(0, 0), float2(0, 0))).xy;
                i.uvMain.xy -= warpTex * B_WarpIntensity;
        #   endif
            float4 uvMain = lerp(saturate(i.uvMain) , frac(i.uvMain) , B_MainWrapMode);
            float2 uvMainTex = uvMain.xy;
            float2 uvMask = uvMain.zw;
        #else
            float2 uvMainTex = i.uvMain.xy;
            float2 uvMask = i.uvMain.zw;
            float2 uvdissolveTex = i.uvSub.xy;
            float2 uvWarpTex = i.uvSub.zw;
            #if	_WARP_ON
                fixed2 warpTex = UnpackNormal(tex2D(_WarpTex, uvWarpTex, float2(0, 0), float2(0, 0))).xy;
                uvMainTex -= warpTex * B_WarpIntensity;
            #endif
        #endif
        fixed4 col = tex2D(_MainTex, uvMainTex, float2(0, 0), float2(0, 0)) * B_Color;
        #if _MASK_ON
            fixed mask = tex2D(_MaskTex, uvMask, float2(0, 0), float2(0, 0)).r ;
            col.a *= mask;
        #endif

        #if	_DISSOLVE_ON
            fixed dissolveTex = tex2D(_DissolveTex, uvdissolveTex, float2(0, 0), float2(0, 0)).r;
            half disValue = lerp(B_DissolveValue,i.customData.x,B_UseCustomData) * 2 -0.5;
            fixed dissolve =  smoothstep(disValue - B_DissolveRangeSize,disValue + B_DissolveRangeSize, dissolveTex);
            fixed4 rangeCol	= (1- dissolve) * B_DissolveRangeCol * dissolve ;
            col.rgb = lerp(B_DissolveRangeCol.rgb ,col.rgb ,dissolve) * dissolve;
            col.a *= dissolve;
        #endif
        col*= i.vertexCol;
        #if RectClip_On
        col.a *= Get2DClipping(i.worldPos.xy , _EffectClipRect);
        #endif
        col.rgb *= col.a;
        #if defined(LGAME_USEFOW) && _FOW_ON
            fixed fowTex = fixed(tex2D(_FOWTexture, i.fowuv).r);
            fixed fowLast = fixed(tex2D(_FOWLastTexture, i.fowuv).r);
            //col *= 1 - lerp(fowLast, fowTex, B_FowBlend);

            fixed add = max(0, fowTex.r - fowLast.r);
            fixed less = -min(0, fowTex.r - fowLast.r);
            fixed mid = fowTex.r - add;

            fixed b = mid + add * _FOWBlend + less * saturate(_FOWOpenSpeed);
            fixed4 fowCol = lerp(_FogRangeCol, _FogCol, b);

            col *= saturate(lerp(1.0.rrrr, fowCol, b * (1 - _FowBrightness)));
        #endif
        return col * B_AlphaCtrl;

    }
#endif  