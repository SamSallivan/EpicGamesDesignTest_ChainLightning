using System;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using System.Text;
#endif

[ExecuteInEditMode]
public class GradientColorEffect : MonoBehaviour
{
    public enum GradientModel
    {
        Linear_Horizontal,
        Linear_Vertical,
        Radial,
        Box
    }

    public GradientModel gradientModel = GradientModel.Linear_Horizontal;
    public Gradient gradientConfig;
    [HideInInspector]
    public int gradientTexSize = 32;

    
    [NonSerialized]
    public Material affectMat;
    [HideInInspector]
    public Texture2D autoGradientTex;

    protected void Awake()
    {
#if UNITY_EDITOR
        InitAffectComponent();
#endif
    }
        
    /// <summary>
    /// 为材质球设置渐变贴图
    /// </summary>
    public void EnableGradientEffect(Texture2D gradientTex)
    {
        if (affectMat != null && gradientTex != null)
        {
            affectMat.EnableKeyword("_GRADIENT_ON");
            affectMat.SetTexture("_GradientTex", gradientTex);
        }
        else
        {
            if (affectMat != null)
            {
                DisableGradientEffect();
            }
        }
    }

    public void DisableGradientEffect()
    {
        if (affectMat != null)
        {
            affectMat.DisableKeyword("_GRADIENT_ON");
            affectMat.SetTexture("_GradientTex", null);
        }
        else
        {
            Debug.LogError("mat no find!!");
        }
    }

#if UNITY_EDITOR

    /// <summary>
    /// 初始化关注组件
    /// </summary>
    public void InitAffectComponent()
    {
        // 重置一下affectMat的指向，不然在GUI里替换材质球的时候，修改会应用到旧的材质球上 by kittyjdhe at 07-12-2023
        affectMat = null;
        
        //TODO 粒子池不支持这样的操作。by alkaid at 12-11-2019
        var customPartical = GetComponentInChildren<ParticlePoolComponentBase>();
        if (customPartical != null)
        {
            affectMat = customPartical.renderModle.material;
        }
        
        if (affectMat == null)
        {
            var affectRenderer = GetComponent<Renderer>();
            if (affectRenderer != null)
            {
                affectMat = affectRenderer.sharedMaterial;
            }
        }
    }

#endif

    
}
