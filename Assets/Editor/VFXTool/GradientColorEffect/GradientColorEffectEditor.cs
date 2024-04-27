using System;
using UnityEditor;
using UnityEngine;
using System.Text;

[CustomEditor(typeof(GradientColorEffect))]
public class GradientColorEffectEditor : Editor
{
    protected GradientColorEffect effect;
    private Texture2D tempTex = null;

    private void OnEnable()
    {
        effect = target as GradientColorEffect;
        effect.InitAffectComponent();
        saved = true;
    }

    private void OnDisable()
    {
        if (!saved && tempTex != null)
        {
            if (EditorUtility.DisplayDialog("警告！", "你调的渐变没有保存噢，要不要保存？", "保存", "不要"))
            {
                SaveGradientConfig();
                saved = true;
            }
            else
            {
                effect.EnableGradientEffect(effect.autoGradientTex);
                DestroyImmediate(tempTex);
                saved = true;
            }
        }
    }

    private bool ValidateSaveState()
    {
        string md5 = ConvertGradientConfigToMd5(effect);
        if (effect.affectMat == null) effect.InitAffectComponent();
        Texture targetTex = effect.affectMat.GetTexture("_GradientTex");
        if (targetTex == null && string.IsNullOrEmpty(md5)) return true;
        if (targetTex != null && targetTex.name.Contains(md5)) return true;
        if (targetTex == effect.autoGradientTex) return true;
        return false;
    }

    private bool saved = false;
    public override void OnInspectorGUI()
    {
        //DoInspector();
        serializedObject.Update();
        if (saved)
        {
            saved = ValidateSaveState();
        }
        DrawPropertiesExcluding(serializedObject, "gradientModel", "gradientConfig");
        EditorGUI.BeginChangeCheck();
        int model = EditorGUILayout.Popup(new GUIContent("Gradient Model"), (int)effect.gradientModel,
            System.Enum.GetNames(typeof(GradientColorEffect.GradientModel)));
        Gradient gradient =
            EditorGUILayout.GradientField("Gradient Config", effect.gradientConfig ?? new Gradient());
        if (EditorGUI.EndChangeCheck())
        {
            effect.gradientModel = (GradientColorEffect.GradientModel)model;
            effect.gradientConfig = gradient;
            ApplyTempEffect(effect);
            saved = false;
        }

        if (!saved)
        {
            Rect line = EditorGUILayout.GetControlRect();
            Rect leftR = new Rect(line);
            Rect rightR = new Rect(line);
            leftR.width = leftR.height;
            leftR.x = EditorGUIUtility.labelWidth;
            rightR.width = rightR.height;
            rightR.x = line.width / 2 + EditorGUIUtility.labelWidth;
            if (effect.autoGradientTex != null)
            {
                EditorGUI.DrawTextureTransparent(leftR, effect.autoGradientTex);
            }
            else
            {
                EditorGUI.DrawRect(leftR, Color.magenta);
                EditorGUI.LabelField(leftR, "空", EditorStyles.boldLabel);
            }

            Rect textRect = new Rect(0, leftR.y, EditorGUIUtility.labelWidth, leftR.height);
            EditorGUI.LabelField(textRect, "保存的贴图：");
            textRect.x = line.width / 2;
            EditorGUI.LabelField(textRect, "即将更新为：");
            if (tempTex != null)
            {
                EditorGUI.DrawTextureTransparent(rightR, tempTex);
            }
            else
            {
                EditorGUI.DrawRect(rightR, Color.magenta);
                EditorGUI.LabelField(rightR, "空", EditorStyles.boldLabel);
            }
        }

        EditorGUILayout.BeginHorizontal();

        if (!saved)
        {
            EditorGUILayout.LabelField("状态：未保存", EditorStyles.boldLabel);
        }
        else
        {
            EditorGUILayout.LabelField("状态：正常");
        }
        
        if (GUILayout.Button("保存"))
        {
            effect.InitAffectComponent();
            SaveGradientConfig();
            saved = true;
        }
        
        EditorGUILayout.EndHorizontal();
        
        if (GUILayout.Button("-删除脚本-"))
        {
            effect.DisableGradientEffect();
            DestroyImmediate(effect);
        }
    }

    void DoInspector()
    {
        serializedObject.Update();
        effect = target as GradientColorEffect;

        base.DrawDefaultInspector();

        Rect line = EditorGUILayout.GetControlRect();
        if (tempTex != null)
        {
            EditorGUI.DrawPreviewTexture(line, tempTex);
        }
        else
        {
            EditorGUI.LabelField(line, "tempTex is null");
        }

        EditorGUILayout.BeginHorizontal();

        if (effect.autoGradientTex == null || effect.affectMat == null)
        {
            if (effect.gradientConfig == null)
            {
                EditorGUILayout.LabelField("状态：颜色配置为空!!!");
            }
            else
            {
                EditorGUILayout.LabelField("状态：未保存");
                ApplyTempEffect(effect);
            }
        }
        else
        {
            var configMd5 = ConvertGradientConfigToMd5(effect);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(configMd5);
            EditorGUILayout.Space();
            if (string.IsNullOrEmpty(configMd5))
            {
                EditorGUILayout.LabelField("状态：颜色配置为空!!!");
            }
            else if (effect.autoGradientTex.name.Contains(configMd5))
            {
                EditorGUILayout.LabelField("状态：正常");
            }
            else
            {
                ApplyTempEffect(effect);
                EditorGUILayout.LabelField("状态：未保存");
            }
        }

        if (GUILayout.Button("保存"))
        {
            effect.InitAffectComponent();
            SaveGradientConfig();
        }
        EditorGUILayout.EndHorizontal();
        
        if (GUILayout.Button("-删除脚本-"))
        {
            effect.DisableGradientEffect();
            DestroyImmediate(effect);
        }
    }

    private void ApplyTempEffect(GradientColorEffect effect)
    {
        if (tempTex != null)
        {
            GameObject.DestroyImmediate(tempTex);
        }

        effect.InitAffectComponent();
        tempTex = CreateGradientTex(effect);
        effect.EnableGradientEffect(tempTex);
    }

    /// <summary>
    /// 使用渐变色贴图配置
    /// </summary>
    public void SaveGradientConfig()
    {
        string configMD5 = ConvertGradientConfigToMd5(effect);
        if (string.IsNullOrEmpty(configMD5))
        {
            return;
        }
        
        string filePath = string.Format("Assets/AssetsRaw/DLDEffect/FXTexture/Gradient/autoCreate_{0}.png", configMD5);
        if (!System.IO.File.Exists(filePath))
        {
            var tex = CreateGradientTex(effect);
            var texBytes = tex.EncodeToPNG();
            System.IO.File.WriteAllBytes(filePath, texBytes);
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            GameObject.DestroyImmediate(tex);
        }

        effect.autoGradientTex = AssetDatabase.LoadAssetAtPath<Texture2D>(filePath);
        effect.EnableGradientEffect(effect.autoGradientTex);
        serializedObject.Update();
    }

    /// <summary>
    /// 根据渐变色创建贴图
    /// </summary>
    private static Texture2D CreateGradientTex(GradientColorEffect effect)
    {
        Texture2D outTex = new Texture2D(effect.gradientTexSize, effect.gradientTexSize, TextureFormat.ARGB32, false);
        outTex.wrapMode = TextureWrapMode.Clamp;

        Color[] colors = new Color[outTex.height * outTex.width];
        for (int u = 0; u < outTex.width; u++)
        {
            for (int v = 0; v < outTex.height; v++)
            {
                float destance = 0f;
                switch (effect.gradientModel)
                {
                    case GradientColorEffect.GradientModel.Linear_Horizontal:
                        destance = u / (float)outTex.width;
                        break;
                    case GradientColorEffect.GradientModel.Linear_Vertical:
                        destance = v / (float)outTex.height;
                        break;
                    case GradientColorEffect.GradientModel.Radial:
                        destance = Vector2.Distance(new Vector2(u / (float)outTex.height, v / (float)outTex.width), new Vector2(0.5f, 0.5f));
                        break;
                    case GradientColorEffect.GradientModel.Box:
                        destance = Mathf.Max(Mathf.Abs(2f * u / (float)outTex.height - 1), Mathf.Abs(2f * v / (float)outTex.width - 1));
                        break;
                }
                colors[outTex.width * v + u] = effect.gradientConfig.Evaluate(destance);
            }

        }
        outTex.SetPixels(colors);
        outTex.Apply();
        return outTex;
    }

    public static string ConvertGradientConfigToMd5(GradientColorEffect effect)
    {
        if (effect.gradientConfig == null)
        {
            Debug.LogError("需配置Gradient颜色！");
            return string.Empty;
        }

        StringBuilder sb = new StringBuilder();
        // add gradient model
        sb.Append((int)effect.gradientModel);
        sb.Append(";");

        // add gradient config
        foreach (var config in effect.gradientConfig.alphaKeys)
        {
            sb.Append(config.time);
            sb.Append(config.alpha);
        }
        sb.Append(";");
        foreach (var config in effect.gradientConfig.colorKeys)
        {
            sb.Append(config.time);
            sb.Append(config.color.ToString());
        }
        sb.Append(";");
        // add tex size
        sb.Append(effect.gradientTexSize);

        string str = sb.ToString();
        var bytes = System.Text.Encoding.UTF8.GetBytes(str);
        System.Security.Cryptography.MD5 md5Provider = System.Security.Cryptography.MD5.Create();
        var md5Bytes = md5Provider.ComputeHash(bytes);
        string md5Str = System.BitConverter.ToString(md5Bytes);
        md5Str = md5Str.Replace("-", "");
        return md5Str;
    }
    
}

