#ifndef SGAME_POSTPROCESSING_INCLUDE
#define SGAME_POSTPROCESSING_INCLUDE

half4 _RenderScaleParam;
half g_bloomMask;
half4 _Threshold;
half4 _Params;

sampler2D _MainTex;
sampler2D _BloomSrcTex;
half4 _BloomSrcTex_TexelSize;
half2 _BloomSrcUvScale;

// upsample only
half _SampleScale;
sampler2D _BloomTex;

// global
uniform sampler2D _GlobalBloomMask;
uniform sampler2D _GlobalOffScreenRT;

// 压暗算法
half3 EncodeFunc(half3 resultCol)
{
    half3 tempCol = resultCol.rgb;
    resultCol.xyz = (-tempCol.xyz) + float3(1.01900005, 1.01900005, 1.01900005);
    resultCol.xyz = tempCol.xyz / resultCol.xyz;
    resultCol.xyz = resultCol.xyz * float3(0.155000001, 0.155000001, 0.155000001);
    return resultCol;
}

struct a2v
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float4 vertex : SV_Position;
    float4 uv : TEXCOORD0;
};

v2f vert(a2v v)
{
    v2f o = (v2f)0;
    o.vertex = UnityObjectToClipPos (v.vertex);
    o.uv.xy = v.uv.xy;
    return o;
}

// 提取亮度阈值,获得高亮部分信息
half4 frag_Prefilter(v2f i) : SV_Target
{
    half4 SV_Target0;
    i.uv.xyzw = min(i.uv.xyxy, _RenderScaleParam.zwzw);
    half4 bloomUVScale =  _BloomSrcTex_TexelSize.xyxy * _BloomSrcUvScale.xyxy;

    // First
    half4 tempUV = i.uv.zwzw + bloomUVScale.zwzw * float4(-2.0, -1.0, 0.0, -1.0);
    fixed3 bloomMask = tex2D(_GlobalBloomMask, tempUV.xy);
    fixed4 screenRTCol1 = tex2D(_GlobalOffScreenRT, tempUV.xy);
    fixed4 screenRTCol2 = tex2D(_GlobalOffScreenRT, tempUV.zw);
    
    float invLuminance1 = 1.0 / (dot(screenRTCol1.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    float invLuminance2 = 1.0 / (dot(screenRTCol2.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    half invLuminanceSum = invLuminance1 + invLuminance2;
    
    half4 resultCol = screenRTCol1 * invLuminance1 + screenRTCol2 * invLuminance2;

    // Second
    tempUV = i.uv.zwzw + bloomUVScale.zwzw * float4(2.0, -1.0, -2.0, 1.0);
    screenRTCol1 = tex2D(_GlobalOffScreenRT, tempUV.xy);
    screenRTCol2 = tex2D(_GlobalOffScreenRT, tempUV.zw);
    
    invLuminance1 = 1.0 / (dot(screenRTCol1.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol += screenRTCol1 * invLuminance1;
    invLuminanceSum += invLuminance1;
    
    invLuminance2 = 1.0 / (dot(screenRTCol2.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol += screenRTCol2 * invLuminance2;
    invLuminanceSum += invLuminance2;

    // Third
    tempUV = i.uv.xyzw + bloomUVScale.xyzw * float4(0.0, 1.0, 2.0, 1.0);
    screenRTCol1 = tex2D(_GlobalOffScreenRT, tempUV.xy);
    screenRTCol2 = tex2D(_GlobalOffScreenRT, tempUV.zw);
    
    invLuminance1 = 1.0 / (dot(screenRTCol1.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol += screenRTCol1 * invLuminance1;
    invLuminanceSum += invLuminance1;
    
    invLuminance2 = 1.0 / (dot(screenRTCol2.rgb, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol += screenRTCol2 * invLuminance2;
    invLuminanceSum += invLuminance2;

    // OutPut
    resultCol /= invLuminanceSum;
    resultCol.a = 1; // ---------------------------------  test todo： 待删除测试看效果变化
    // return resultCol; // print test
    
    // 将 resultCol 进行压暗处理
    resultCol.rgb = EncodeFunc(resultCol.rgb);
    
    // 剔除一些非亮色元素，保证颜色不会超出范围（避免彩虹色）
    float avg = dot(resultCol.rgb, 0.3333);
    float invAvg = resultCol.a / max(avg, 0.01);
    resultCol.rgb *= clamp(invAvg, 0.0, 1.0);
    
    // 通过 _Params.x 将最终颜色限制下最大值
    resultCol.rgb = clamp(resultCol.rgb, float3(0, 0, 0), _Params.xxx); // _Params.xxx = minLimit

    // 阈值提取
    float2 thresholdOffset = _Threshold.yx;
    float thresholdMin = 0.0001;
    float thresholdMax = _Threshold.z;
    float thresholdIntensity = _Threshold.w;
    
    // 计算
    half3 temp;
    float maxChanel =  max(max(resultCol.r, resultCol.g), resultCol.b); // 取 resultCol.rgb 中的最大值
    temp.xy = maxChanel - thresholdOffset;
    maxChanel = max(maxChanel, 9.99999975e-05);
    temp.x = clamp(temp.x, 0.0, thresholdMax);
    temp.x = pow(temp.x, 2.0) * thresholdIntensity;
    maxChanel = max(temp.y, temp.x) / maxChanel;
    resultCol.rgb *= maxChanel;
    
    SV_Target0.rgb = -min(-resultCol.rgb, 0.0);
    // SV_Target0.rgb = (resultCol.rgb);

    // return half4(bloomMask.rgb, 1.0);
    half maskValue = min(bloomMask.r+bloomMask.g+bloomMask.b, 1.0);
    // return half4(maskValue, maskValue,maskValue, 1.0);
    half3 withMaskResColor = lerp(half3(0,0,0), SV_Target0.rgb, maskValue);
    // return half4(withMaskResColor.rgb, 1.0);
    SV_Target0.rgb = lerp(SV_Target0.rgb, withMaskResColor, g_bloomMask);
    SV_Target0.a = 1.0;
    
    return SV_Target0;
}

// 降采样
half4 frag_downsample(v2f i) : SV_Target
{
    half4 SV_Target0 = (0,0,0,1);;
    half4 resultCol = (0,0,0,1);
    half luminancelSum = 0;
    half4 bloomUVScale = _BloomSrcTex_TexelSize.xyxy * _BloomSrcUvScale.xyxy;

    // First
    half4 newUV1 = i.uv.xyxy + bloomUVScale.xyzy * float4(-1.0, -1.0, 1.0, -1.0);
    fixed3 bloomCol1 = tex2D(_BloomSrcTex, newUV1.zw).xyz;
    fixed3 bloomCol2 = tex2D(_BloomSrcTex, newUV1.xy).xyz;

    half invLuminance1 = 1.0 / (dot(bloomCol1, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol.rgb = invLuminance1 * bloomCol1;
    half invLuminance2 = 1.0 / (dot(bloomCol2, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol.rgb += invLuminance2 * bloomCol2;
    
    luminancelSum = invLuminance1 + invLuminance2;

    // Second
    half4 newUV2 = i.uv.xyxy + bloomUVScale.xwzw * float4(-1.0, 1.0, 1.0, 1.0);
    bloomCol1.rgb = tex2D(_BloomSrcTex, newUV2.xy).xyz;
    bloomCol2.rgb = tex2D(_BloomSrcTex, newUV2.zw).xyz;

    invLuminance1 = 1.0 / (dot(bloomCol1, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol.rgb += (invLuminance1 * bloomCol1);
    invLuminance2 = 1.0 / (dot(bloomCol2, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    resultCol.rgb += (invLuminance2 * bloomCol2);
    
    luminancelSum += (invLuminance1 + invLuminance2); 

    // Last
    fixed3 bloomCol = tex2D(_BloomSrcTex, i.uv.xy).xyz;
    half luminace = 1.0 / (dot(bloomCol, float3(0.2126, 0.7152, 0.0722)) + _Params.y);
    bloomCol.rgb *= luminace;
    
    luminancelSum += (luminace * 4);
    resultCol.rgb += bloomCol.rgb * float3(4.0, 4.0, 4.0);
    
    SV_Target0.rgb = resultCol.rgb / luminancelSum;
    SV_Target0.a = 1.0;
    return SV_Target0;
}

// 升采样
half4 frag_upsample(v2f i) : SV_Target
{
    half4 SV_Target0;
    half sampleScale = _SampleScale * 0.5;
    half2 bloomUVScale = (_BloomSrcTex_TexelSize.xy * sampleScale);
    half4 newUV = half4(0,0,0,0);

    // First
    newUV = i.uv.xyxy + bloomUVScale.xyxy * float4(-2.0, 0.0, -1.0, 1.0);
    fixed3 bloomCol1 = tex2D(_BloomSrcTex, newUV.xy).xyz;
    fixed3 bloomCol2 = tex2D(_BloomSrcTex, newUV.zw).xyz;
    fixed3 resultCol = bloomCol1 + (bloomCol2 * 2.0);

    // Second
    newUV = i.uv.xyxy + bloomUVScale.xyxy * float4(0.0, 2.0, 2.0, 0.0); 
    bloomCol1.xyz = tex2D(_BloomSrcTex, newUV.xy).xyz;
    bloomCol2.xyz = tex2D(_BloomSrcTex, newUV.zw).xyz;
    resultCol += bloomCol1;
    resultCol += bloomCol2;
    
    // Third
    newUV = i.uv.xyxy + bloomUVScale.xyxy * float4(1.0, -1.0, 0.0, -2.0);
    bloomCol1 = tex2D(_BloomSrcTex, newUV.xy).xyz;
    bloomCol2 = tex2D(_BloomSrcTex, newUV.zw).xyz;
    resultCol += bloomCol1 * float3(2.0, 2.0, 2.0);
    resultCol += bloomCol2;
    
    // 111
    newUV.xy = i.uv.xy + (_BloomSrcTex_TexelSize.xy * sampleScale.xx);
    bloomCol1 = tex2D(_BloomSrcTex, newUV.xy).xyz;
    resultCol += (bloomCol1 * float3(2.0, 2.0, 2.0));

    // 222
    newUV.xy = i.uv.xy - (_BloomSrcTex_TexelSize.xy * sampleScale.xx);
    bloomCol1 = tex2D(_BloomSrcTex, newUV.xy).xyz;
    resultCol += (bloomCol1 * float3(2.0, 2.0, 2.0));
    
    fixed3 newBloomCol = tex2D(_BloomTex, i.uv.xy).xyz;
    SV_Target0.xyz = resultCol.rgb * float3(0.0833333358, 0.0833333358, 0.0833333358) + newBloomCol.rgb;
    SV_Target0.w = 1.0;
    
    return SV_Target0;
}

#endif