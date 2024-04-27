#ifndef LGAME_INGAME_PET_INCLUDED
    #define LGAME_INGAME_PET_INCLUDED
    
    #include "UnityCG.cginc"
    #include "Assets/CGInclude/LGameCharacterDgs.cginc" 
    
    struct a2v_pet
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    #ifdef _COMBINEDTEX_ON
        float2 uv1 : TEXCOORD1;
    #endif
    #ifdef _USE_DIRECT_GPU_SKINNING
        half4 tangent : TANGENT;
        float4 skinIndices : TEXCOORD2;
        float4 skinWeights : TEXCOORD3;
    #else
        float3 normal : NORMAL;
    #endif
    };
    
    struct v2f_pet
    {
        float2 uv : TEXCOORD0;
        float4 pos : SV_POSITION;
    #ifdef _RIMLIGHT
        float4 color : TEXCOORD1;
    #endif
    #if  _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
        half2 uvFlow : TEXCOORD2;
    #endif
    };
    
    sampler2D _MainTex;
    fixed4 _MainTex_ST;
    fixed4 _MainColor;
    
    #if _RIMLIGHT
    fixed4 _RimLightColor;
    half _RimLighRange;
    half _RimLighMultipliers;
    int _RimLightBlendMode;
    #endif
    
    #if _FLOWLIGHTUV ||  _FLOWLIGHTSCREEN
    sampler2D _FlowlightTex;
    half4 _FlowlightTex_ST;
    half _FlowlightMultipliers;
    fixed4 _FlowlightCol;
    int _FlowLightBlendMode;
    #endif
    
    v2f_pet vert (a2v_pet v)
    {
        v2f_pet o;
        UNITY_INITIALIZE_OUTPUT(v2f_pet, o)
        o.pos = UnityObjectToClipPos(v.vertex);
        float3 normal;
    #if _USE_DIRECT_GPU_SKINNING
        float4 tangent;
        float3 binormal;
    
        DecompressTangentNormal(v.tangent, tangent, normal, binormal);
        pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
        v.uv.xy = DecompressUV(v.uv.xy, _uvBoundData);
        /********************************************************************************************************************
        //对偶四元数 by yeyang
        half2x4 q0 = GetDualQuat(v.skinIndices.x);
        half2x4 q1 = GetDualQuat(v.skinIndices.y);
        half2x4 q2 = GetDualQuat(v.skinIndices.z);
        half2x4 q3 = GetDualQuat(v.skinIndices.w);
    
        half2x4 blendDualQuat = q0 * v.skinWeights.x;
        if (dot(q0[0], q1[0]) > 0)
            blendDualQuat += q1 * v.skinWeights.y;
        else
            blendDualQuat -= q1 * v.skinWeights.y;
    
        if (dot(q0[0], q2[0]) > 0)
            blendDualQuat += q2 * v.skinWeights.z;
        else
            blendDualQuat -= q2 * v.skinWeights.z;
    
        if (dot(q0[0], q3[0]) > 0)
            blendDualQuat += q3 * v.skinWeights.w;
        else
            blendDualQuat -= q3 * v.skinWeights.w;
    
        blendDualQuat = NormalizeDualQuat(blendDualQuat);
    
        pos = float4(TransformFromDualQuat(blendDualQuat, v.vertex), 1);
        *********************************************************************************************************************/
    #else
        normal = v.normal;
    #endif
        
    #ifdef _COMBINEDTEX_ON
        float2 deltaPos = (sign(v.uv1) + 1.0) * 0.25;
        o.uv = v.uv * 0.5 + deltaPos;
    #else
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    #endif
        
    #if  _FLOWLIGHTUV
        o.uvFlow = o.uv * _FlowlightTex_ST.xy + frac(_FlowlightTex_ST.zw * _Time.y);
    #elif _FLOWLIGHTSCREEN
        half4 srcPos = ComputeScreenPos(o.pos);
        o.uvFlow = (srcPos.xy / srcPos.w) * _FlowlightTex_ST.xy + frac(_FlowlightTex_ST.zw * _Time.y);
    #endif
        
    #if _RIMLIGHT
        fixed3 worldNormal = UnityObjectToWorldNormal(normal);
        fixed3 worldViewDir = normalize(WorldSpaceViewDir(v.vertex));
        half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
        o.color.a = pow(fresnel, _RimLighRange);
    #endif
        return o;
    }
    
    fixed4 frag (v2f_pet i) : SV_Target
    {
        // sample the texture
        fixed4 col = tex2D(_MainTex, i.uv) * _MainColor;
        #if  _RIMLIGHT
        _RimLightColor.rgb = col.rgb * (1 - _RimLightColor).a + _RimLightColor.rgb;
        // _RimLightBlendMode
        // 0 => multiply(default)
        // 1 => add
        // Use more readable encoding  @bartwang 2022-03-10
        if(any(_RimLightBlendMode))
        {
            col.rgb += i.color.a * _RimLighMultipliers * _RimLightColor; // *mask
        }
        else
        {
            col = lerp(col, _RimLightColor, i.color.a * _RimLighMultipliers /* *mask */);
        }
    #endif
    
    #if _FLOWLIGHTUV || _FLOWLIGHTSCREEN
        half4 flowlightTex = tex2D(_FlowlightTex, i.uvFlow); // *mask
        half4 flowlightColor = _FlowlightCol * _FlowlightMultipliers;
    
        // _FlowLightBlendMode
        // 0 => multiply
        // 1 => add
        // 2 => mask to multiply
        // Use more readable encoding  @yvanliao 2022-03-01
        if(_FlowLightBlendMode>1)
        {
            col.rgb *= lerp(1, flowlightColor.rgb, flowlightTex.rgb * flowlightTex.a);
        }
        else
        {
            flowlightColor *= flowlightTex;
            flowlightColor.rgb *= flowlightColor.a;
            
            if(any(_FlowLightBlendMode))
            {
                col.rgb += flowlightColor.rgb;
            }
            else
            {
                col.rgb *= flowlightColor.rgb;
            }
        }
    #endif
        return col;
    }

#endif