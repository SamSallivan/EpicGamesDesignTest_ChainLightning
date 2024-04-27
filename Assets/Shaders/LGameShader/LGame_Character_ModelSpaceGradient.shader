Shader "LGame/Character/ModelSpaceGradient"
{
    Properties
    {
        _MainTex ("Main Texture(RGBA)", 2D) = "white" {} //主纹理
        _MainColor("Main Color" , Color) = (1,1,1,1)//染色
        [NoScaleOffset]_GradientTex ("GradientTex", 2D) = "white" {}
        _Vector("Vector(xyz for position,w for scale)",vector)=(1,1,1,1)
        _GradientSpeed("GradientSpeed",Range(0,1))=0
        _GradientStrength("GradientStrength",Range(0,1))=1
        _RimLightColor("RimLight Color" , Color) = (0,0,0,1)
        _RimLightRange("RimLight Range", Range(0.1,10)) = 1
        _RimLightMultipliers ("RimLight Multipliers", Range(0, 5)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="AlphaTest" "Queue"="AlphaTest"}
        LOD 75
        //Default Pass
        UsePass "Hidden/Character/Shadow/CharacterShadow"
        Pass
        {
            ZWrite On
            Cull Back
            Blend One Zero
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers gles
            #pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/LGameCharacterDgs.cginc" 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                #ifdef _USE_DIRECT_GPU_SKINNING
                    half4 tangent : TANGENT;
                    float4 skinIndices : TEXCOORD2;
                    float4 skinWeights : TEXCOORD3;
                #else
                    float3 normal : NORMAL;
                #endif
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 modelspacepos : TEXCOORD1;
                float rimlight : TEXCOORD2;
            };
            float4              _Vector;
            sampler2D           _GradientTex;
            fixed4              _RimLightColor;
            half                _RimLightRange;
            half                _RimLightMultipliers;
            fixed4              _MainColor;
            sampler2D           _MainTex;
            half4               _MainTex_ST;
            half                _GradientStrength;
            half                _GradientSpeed;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                float4 pos = v.vertex;
                float3 normal;
                #if _USE_DIRECT_GPU_SKINNING
                    float4 tangent;
                    float3 binormal;
                    DecompressTangentNormal(v.tangent, tangent, normal, binormal);
                    pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
                #else
                    normal = v.normal;
                #endif
                float3 worldNormal = UnityObjectToWorldNormal(normal);
                o.modelspacepos = length(pos.xyz - _Vector.xyz);
                float3 worldViewDir = normalize(WorldSpaceViewDir(pos));
                half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
                o.rimlight = pow(fresnel, _RimLightRange);
                o.vertex = UnityObjectToClipPos(pos);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv.xy) * _MainColor;
                half4 gradient = tex2D(_GradientTex , half2(i.modelspacepos.x *_Vector.w,frac( _Time.y * _GradientSpeed)));
                col=lerp(col,gradient,_GradientStrength);
                _RimLightColor.rgb = col.rgb * (1 - _RimLightColor).a + _RimLightColor.rgb;
                col = lerp(col , _RimLightColor , i.rimlight * _RimLightMultipliers);
                return col;
            }
            ENDCG
        }
        //srp pass
        UsePass "Hidden/Character/Shadow Srp/CharacterShadowSrp"
        Pass
        {
            Tags { "LightMode" = "CharacterDefaultSrp" }
            ZWrite On
            Cull Back
            Blend One Zero
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers gles
            #pragma multi_compile __ _USE_DIRECT_GPU_SKINNING
            #include "UnityCG.cginc"
            #include "Assets/CGInclude/LGameCharacterDgs.cginc" 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                #ifdef _USE_DIRECT_GPU_SKINNING
                    half4 tangent : TANGENT;
                    float4 skinIndices : TEXCOORD2;
                    float4 skinWeights : TEXCOORD3;
                #else
                    float3 normal : NORMAL;
                #endif
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 modelspacepos : TEXCOORD1;
                float rimlight : TEXCOORD2;
            };
            float4              _Vector;
            sampler2D           _GradientTex;
            fixed4              _RimLightColor;
            half                _RimLightRange;
            half                _RimLightMultipliers;
            fixed4              _MainColor;
            sampler2D           _MainTex;
            half4               _MainTex_ST;
            half                _GradientStrength;
            half                _GradientSpeed;
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                float4 pos = v.vertex;
                float3 normal;
                #if _USE_DIRECT_GPU_SKINNING
                    float4 tangent;
                    float3 binormal;
                    DecompressTangentNormal(v.tangent, tangent, normal, binormal);
                    pos = CalculateGPUSkin(v.skinIndices, v.skinWeights, v.vertex, tangent, normal, binormal);
                #else
                    normal = v.normal;
                #endif
                float3 worldNormal = UnityObjectToWorldNormal(normal);
                o.modelspacepos = length(pos.xyz - _Vector.xyz);
                float3 worldViewDir = normalize(WorldSpaceViewDir(pos));
                half fresnel = 1 - abs(dot(worldViewDir, worldNormal));
                o.rimlight = pow(fresnel, _RimLightRange);
                o.vertex = UnityObjectToClipPos(pos);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv.xy) * _MainColor;
                half4 gradient = tex2D(_GradientTex , half2(i.modelspacepos.x *_Vector.w,frac( _Time.y * _GradientSpeed)));
                col=lerp(col,gradient,_GradientStrength);
                _RimLightColor.rgb = col.rgb * (1 - _RimLightColor).a + _RimLightColor.rgb;
                col = lerp(col , _RimLightColor , i.rimlight * _RimLightMultipliers);
                return col;
            }
            ENDCG
        }
        UsePass "Hidden/Character/Shadow Srp/CharacterSoftShadowSrp"
        UsePass "Hidden/Character/Outline Srp/CharacterOutlineSrp"
        UsePass "Hidden/Character/Outline Srp/CharacterScreenOutlineSrp"

    }
}
