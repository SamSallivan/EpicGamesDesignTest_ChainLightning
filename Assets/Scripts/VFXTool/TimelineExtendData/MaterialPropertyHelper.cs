using System;
using System.Collections.Generic;
using UnityEngine;

public class MaterialPropertyHelper
{
    private static MaterialPropertyHelper instance = null;
    public static MaterialPropertyHelper Instance
    {
        get
        {
            if (instance == null)
            {
                instance = new MaterialPropertyHelper();
                instance.Init();
            }
            return instance;
        }
    }

    private enum ShaderPropertyType
    {
        _Unknow,
        _Buffer,
        _Color,
        _ConstantBufer,
        _Float,
        _FloatArray,
        _Int,
        _Matrix,
        _MatrixArray,
        _Texture,
        _Vector,
        _VectorArray,
    }
    private class ShaderPropertyData
    {
        public string name = string.Empty;
        public List<Shader> shaders = new List<Shader>(8);
        public ulong shaderPropertys = 0;
    }
    private string[] shaderPropertyStrs = new string[64];
    private ShaderPropertyType[] shaderPropertyTypes = new ShaderPropertyType[64];
    private List<ShaderPropertyData> shaderPropertyDatas = new List<ShaderPropertyData>(32);

    public Dictionary<string, int> materialPropertyIds = new Dictionary<string, int>(32);
    public Dictionary<Renderer, MaterialPropertyBlock> materialPropertyBlocks = new Dictionary<Renderer, MaterialPropertyBlock>(10000);

    private const string cCommonShader = "ALL";
    
    /// <summary>
    /// init
    /// </summary>
    public void Init()
    {
        //shaderPropertyDatas = new List<ShaderPropertyData>(32);
        //materialPropertyIds = new Dictionary<string, int>(32);
        //materialPropertyBlocks = new Dictionary<Renderer, MaterialPropertyBlock>(8000);

        InitPropertyIDs();
    }

    /// <summary>
    /// Detach shader link.
    /// </summary>
    public void Clear()
    {
        for (int i = 0; i < shaderPropertyDatas.Count; ++ i)
        {
            var item = shaderPropertyDatas[i];
            item.shaders.Clear();
        }

        materialPropertyBlocks.Clear();
    }
    
    private void InitPropertyIDs()
    {
        RegistShaderProperty(cCommonShader, "_Color", ShaderPropertyType._Color);
        RegistShaderProperty(cCommonShader, "_MainTex", ShaderPropertyType._Texture);
        RegistShaderProperty(cCommonShader, "_AlphaCtrl", ShaderPropertyType._Float);

        RegistShaderProperty("PhotonShader/Effect/Default", "_Multiplier", ShaderPropertyType._Float);
        RegistShaderProperty("PhotonShader/Effect/Default", "_TintColor", ShaderPropertyType._Color);
        RegistShaderProperty("PhotonShader/Effect/Default", "_EmisColor", ShaderPropertyType._Color);
        RegistShaderProperty("PhotonShader/Effect/Default", "_FowBlend", ShaderPropertyType._Float);
        //RegistShaderProperty("PhotonShader/Effect/Default", "_MainTex_ST", ShaderPropertyType._Vector);
        //RegistShaderProperty("PhotonShader/Effect/Default", "_MaskTex", ShaderPropertyType._Texture);
        //RegistShaderProperty("PhotonShader/Effect/Default", "_MaskTex_ST", ShaderPropertyType._Vector);

        RegistShaderProperty("PhotonShader/Effect/Default_Custom", "_FowBlend", ShaderPropertyType._Float);
        RegistShaderProperty("LGame/Effect/Model Transparent(No Shadow)", "_FowBlend", ShaderPropertyType._Float);
        RegistShaderProperty("UI/Alpha Mask FOWTexture", "_FowBlend", ShaderPropertyType._Float);

        RegistShaderProperty("Custom/StencilMask", "_Stencil", ShaderPropertyType._Int);
        RegistShaderProperty("Custom/StencilMask", "_StencilOp", ShaderPropertyType._Int);
        RegistShaderProperty("Custom/StencilMask", "AttrStencilCompId", ShaderPropertyType._Int);
        RegistShaderProperty("Custom/StencilMask", "AttrStencilReadMaskId", ShaderPropertyType._Int);
        RegistShaderProperty("Custom/StencilMask", "AttrStencilWriteMaskId", ShaderPropertyType._Int);
        RegistShaderProperty("Custom/StencilMask", "AttrColorMaskId", ShaderPropertyType._Color);
        RegistShaderProperty("Custom/StencilMask", "_MainTex", ShaderPropertyType._Texture);

        //RegistShaderProperty(cCommonShader, "_ClipRect", ShaderPropertyType._Vector);
        RegistShaderProperty("UI/Transparent Color Alpha", "_ClipRect", ShaderPropertyType._Vector);
        RegistShaderProperty("UI/Transparent Color Alpha Font", "_ClipRect", ShaderPropertyType._Vector);
        RegistShaderProperty("UI/Default", "_ClipRect", ShaderPropertyType._Vector);

        AnalyseShaderProperty();

        for (int i = 0; i < shaderPropertyStrs.Length; ++ i)
        {
            var item = shaderPropertyStrs[i];
            if (!string.IsNullOrEmpty(item))
            {
                GetPropertyID(item);
            }
        }
    }
    
    public int GetPropertyID(string id)
    {
        int ret = 0;
        if (!materialPropertyIds.TryGetValue(id, out ret))
        {
            ret = Shader.PropertyToID(id);
            materialPropertyIds.Add(id, ret);
        }

        return ret;
    }

    public MaterialPropertyBlock GetPropertyBlock(Renderer renderer)
    {
        if (renderer == null)
        {
            return null;
        }

        MaterialPropertyBlock block = null;
        if (!materialPropertyBlocks.TryGetValue(renderer, out block))
        {
            block = new MaterialPropertyBlock();
            renderer.GetPropertyBlock(block);
            //InitRendererPropertyBlock(renderer, block);
            materialPropertyBlocks.Add(renderer, block);
        }

        return block;
    }

    public void RemovePropertyBlock(Renderer renderer)
    {
        if (renderer == null)
        {
            return;
        }

        if (materialPropertyBlocks.ContainsKey(renderer))
        {
            materialPropertyBlocks.Remove(renderer);
        }
    }

    /// <summary>
    /// 刷新MaterialPropertyBlock数据
    /// mark:由于现在无法在项目侧仅改变block某个数据，从而只能去刷新
    /// add by alkaidfang at 12/24/2020 for PauseEffect use only.
    /// </summary>
    public void UpdatePropertyBlock(Renderer renderer, MaterialPropertyBlock block)
    {
        if (renderer != null && block != null)
        {
            renderer.GetPropertyBlock(block);
        }
    }

    private void RegistShaderProperty(string shaderName, string property, ShaderPropertyType pType)
    {
        int propertyIndex = 0;
        for (int i = 0; i < shaderPropertyStrs.Length; ++i)
        {
            var proName = shaderPropertyStrs[i];
            if (proName == property || proName == null)
            {
                shaderPropertyStrs[i] = property;
                shaderPropertyTypes[i] = pType;

                propertyIndex = i;
                break;
            }
        }

        ShaderPropertyData data = null;
        for (int i = 0; i < shaderPropertyDatas.Count; ++i)
        {
            var temp = shaderPropertyDatas[i];
            if (temp.name == shaderName)
            {
                data = temp;
                break;
            }
        }

        if (data == null)
        {
            data = new ShaderPropertyData();
            data.name = shaderName;
            data.shaderPropertys = 0;
            shaderPropertyDatas.Add(data);
        }

        ulong mark = 1;
        mark = mark << propertyIndex;

        data.shaderPropertys |= mark;
    }
    
    private void AnalyseShaderProperty()
    {
        var commonData = GetPropertyData(cCommonShader);
        if (commonData == null) return;

        for (int i = 0; i < shaderPropertyDatas.Count; ++ i)
        {
            var data = shaderPropertyDatas[i];
            data.shaderPropertys |= commonData.shaderPropertys;
        }
    }

    private ShaderPropertyData GetPropertyData(Shader shader)
    {
        ShaderPropertyData data = null;
        for (int i = 0; i < shaderPropertyDatas.Count; ++i)
        {
            var temp = shaderPropertyDatas[i];
            if (temp.shaders.Contains(shader))
            {
                data = temp;
                break;
            }
        }

        if (data == null)
        {
            var name = shader.name;
            data = GetPropertyData(name);

            if (data != null)
            {
                data.shaders.Add(shader);
            }
        }

        return data;
    }

    private ShaderPropertyData GetPropertyData(string shaderName)
    {
        ShaderPropertyData data = null;
        for (int i = 0; i < shaderPropertyDatas.Count; ++i)
        {
            var temp = shaderPropertyDatas[i];
            if (temp.name == shaderName)
            {
                data = temp;
                break;
            }
        }
        return data;
    }


    private void InitRendererPropertyBlock(Renderer renderer, MaterialPropertyBlock block)
    {
        var mainMat = renderer.sharedMaterial;
        if (mainMat == null) return;

        Shader shader = mainMat.shader;
        var data = GetPropertyData(shader);

        if (data == null)
        {
            // add new shader. apply common property to new shaderData
            data = new ShaderPropertyData();
            data.name = shader.name;
            data.shaders.Add(shader);
            var commonData = GetPropertyData(cCommonShader);
            if (commonData != null)
            {
                data.shaderPropertys = commonData.shaderPropertys;
                shaderPropertyDatas.Add(data);
            }
        }

        string propertyName = string.Empty;
        ShaderPropertyType propertyType = ShaderPropertyType._Unknow;
        int propertyId = 0;
        for (int i = 0; i < shaderPropertyStrs.Length; ++i)
        {
            if ((data.shaderPropertys & ((ulong)1 << i)) > 0)
            {
                propertyName = shaderPropertyStrs[i];
                propertyType = shaderPropertyTypes[i];
                propertyId = GetPropertyID(propertyName);

                if (!mainMat.HasProperty(propertyId)) // very slow?
                {
                    continue;
                }

                // begin initialize.
                switch (propertyType)
                {
                    case ShaderPropertyType._Color:
                        {
                            Color c = mainMat.GetColor(propertyId);
                            block.SetColor(propertyId, c);
                        }break;
                    case ShaderPropertyType._Float:
                        {
                            float f = mainMat.GetFloat(propertyId);
                            block.SetFloat(propertyId, f);
                        }break;
                    case ShaderPropertyType._Int:
                        {
                            int a = mainMat.GetInt(propertyId);
                            block.SetInt(propertyId, a);
                        }break;
                    case ShaderPropertyType._Texture:
                        {
                            Texture tex = mainMat.GetTexture(propertyId);
                            if (tex != null) block.SetTexture(propertyId, tex);
                        }break;
                    case ShaderPropertyType._Vector:
                        {
                            Vector4 vec = mainMat.GetVector(propertyId);
                            block.SetVector(propertyId, vec);
                        }break;
                    default:
                        {
                            Debug.LogErrorFormat("MaterialPropertyHelper:InitRendererPropertyBlock() 未初始化当前属性！Shader:{0}, property:{1}", data.name, propertyName);
                        }break;
                }
            }
        }

    }
}