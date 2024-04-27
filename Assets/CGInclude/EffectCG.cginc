#ifndef EFFECT_CG_INCLUDE  
#define EFFECT_CG_INCLUDE

    half4x4 transformMatrix = half4x4(1,-1,0,1,
                                    1,1,0,1,
                                    0,0,1,0,
                                    0,0,0,1);

    inline float2 RotateUV(float2 uv,half2 uvRotate)
    {
        float2 outUV;
        
        outUV = uv - half2(0.5, 0.5);
        outUV = float2(cross(outUV.xyx , uvRotate.xyx).z + 0.5, dot(outUV.xy , uvRotate.xy) + 0.5);
        return outUV;
    }

    inline float2 TransFormUV(float2 argUV,half4 argTM, fixed flag)
    {
        float2 result = argUV.xy * argTM.xy + argTM.zw;
        result += flag * (1 - argTM.xy)*0.5;

        return result;
    }

    inline half4x4 GetUVTransform(half4 argTM , half2 uvRotate , fixed flag)
    {
        half2 offset = argTM.zw + flag * (1 - argTM.xy)*0.5;
        transformMatrix[0] = half4(argTM.x * uvRotate.y,-argTM.y * uvRotate.x,0,offset.x);
        transformMatrix[1] = half4(argTM.x * uvRotate.x,argTM.y * uvRotate.y,0,offset.y);
        return transformMatrix;
    }

#endif  