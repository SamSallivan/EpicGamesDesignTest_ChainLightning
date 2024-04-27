using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public enum SubEmitterErrorType
{
    NotFindSubEmitterRef, //引用了一个不存在的子发射器
    RefSameSubEmitter, //多个主发射器引用同一个子发射器
    SubEmitterNotBeChildren, //子发射器不作为主发射器的子节点存在
    ShapeTextureDisableReadWrite, //ShapeModule的texture没有enable read/write.
}

public struct ErrorSubEmitterPrefab
{
    public string prefabName;
    public List<string> errorSubEmitterList;
}

public class FindErrorSubEmitterSystemWindow : EditorWindow
{
    [MenuItem("Tools/找出错误的粒子特效")]
    public static void Open()
    {
        GetWindow<FindErrorSubEmitterSystemWindow>();
    }
    
    Shader shader;
    Dictionary<SubEmitterErrorType, List<ErrorSubEmitterPrefab>> prefabs = new Dictionary<SubEmitterErrorType, List<ErrorSubEmitterPrefab>>();
    Dictionary<SubEmitterErrorType, Vector2> scrollDic = new Dictionary<SubEmitterErrorType, Vector2>();
    List<string> prefabPaths = new List<string>();
    string inputText = "Assets/ABPack";
    private int printCount;

    FindErrorSubEmitterSystemWindow()
    {
        prefabs.Add(SubEmitterErrorType.NotFindSubEmitterRef, new List<ErrorSubEmitterPrefab>());
        prefabs.Add(SubEmitterErrorType.RefSameSubEmitter, new List<ErrorSubEmitterPrefab>());
        prefabs.Add(SubEmitterErrorType.SubEmitterNotBeChildren, new List<ErrorSubEmitterPrefab>());
        prefabs.Add(SubEmitterErrorType.ShapeTextureDisableReadWrite, new List<ErrorSubEmitterPrefab>());
        
        scrollDic.Add(SubEmitterErrorType.NotFindSubEmitterRef, new Vector2());
        scrollDic.Add(SubEmitterErrorType.RefSameSubEmitter, new Vector2());
        scrollDic.Add(SubEmitterErrorType.SubEmitterNotBeChildren, new Vector2());
        scrollDic.Add(SubEmitterErrorType.ShapeTextureDisableReadWrite, new Vector2());
    }

    void ClearPrefabs()
    {
        prefabs[SubEmitterErrorType.NotFindSubEmitterRef].Clear();
        prefabs[SubEmitterErrorType.RefSameSubEmitter].Clear();
        prefabs[SubEmitterErrorType.SubEmitterNotBeChildren].Clear();
        prefabs[SubEmitterErrorType.ShapeTextureDisableReadWrite].Clear();
    }
    
    bool IsNotFindSubEmitterRef(string prefabName, out List<string> findErrorSubEmitterList)
    {
        findErrorSubEmitterList = new List<string>();
        GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabName);
        if (prefab == null) return false;
        // 获取 Prefab 中的粒子系统组件
        ParticleSystem[] particleSystems = prefab.GetComponentsInChildren<ParticleSystem>(true);
        for (int i = 0; i < particleSystems.Length; i++)
        {
            var particleSystem = particleSystems[i];
            if (particleSystem != null && particleSystem.subEmitters.enabled)
            {
                // 获取子发射器的属性
                ParticleSystem.SubEmittersModule subEmitters = particleSystem.subEmitters;
                var subCount = subEmitters.subEmittersCount;
                for (int j = 0; j < subCount; j++)
                {
                    var subEmitterSystem = subEmitters.GetSubEmitterSystem(j);
                    if (subEmitterSystem != null && !particleSystems.Contains(subEmitterSystem))
                    {
                        findErrorSubEmitterList.Add(particleSystem.name);
                    }
                }
            }
        }
        return findErrorSubEmitterList.Count > 0;
    }
    
    bool IsRefSameSubEmitter(string prefabName , out List<string> findErrorSubEmitterList)
    {
        findErrorSubEmitterList = new List<string>();
        Dictionary<ParticleSystem, string> subEmitterDic = new Dictionary<ParticleSystem, string>();
        GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabName);
        if (prefab == null) return false;
        // 获取 Prefab 中的粒子系统组件
        ParticleSystem[] particleSystems = prefab.GetComponentsInChildren<ParticleSystem>(true);
        for (int i = 0; i < particleSystems.Length; i++)
        {
            var particleSystem = particleSystems[i];
            if (particleSystem != null && particleSystem.subEmitters.enabled)
            {
                // 获取子发射器的属性
                ParticleSystem.SubEmittersModule subEmitters = particleSystem.subEmitters;
                var subCount = subEmitters.subEmittersCount;
                for (int j = 0; j < subCount; j++)
                {
                    var subEmitterSystem = subEmitters.GetSubEmitterSystem(j);
                    if (subEmitterSystem != null && subEmitterDic.ContainsKey(subEmitterSystem))
                    {
                        findErrorSubEmitterList.Add(subEmitterDic[subEmitterSystem]);
                        findErrorSubEmitterList.Add(particleSystem.name);
                    }
                    else if (subEmitterSystem != null)
                    {
                        subEmitterDic.Add(subEmitterSystem, particleSystem.name);
                    }
                }
            }
        }
        return findErrorSubEmitterList.Count > 0;
    }
    
    bool IsSubEmitterDisActive(string prefabName, out List<string> findErrorSubEmitterList)
    {
        findErrorSubEmitterList = new List<string>();
        GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabName);
        if (prefab == null) return false;
        prefab = Instantiate(prefab);
        // 获取 Prefab 中的粒子系统组件
        ParticleSystem[] particleSystems = prefab.GetComponentsInChildren<ParticleSystem>(true);
        for (int i = 0; i < particleSystems.Length; i++)
        {
            var particleSystem = particleSystems[i];
            if (particleSystem != null && particleSystem.subEmitters.enabled)
            {
                // 获取子发射器的属性
                ParticleSystem.SubEmittersModule subEmitters = particleSystem.subEmitters;
                var subCount = subEmitters.subEmittersCount;
                for (int j = 0; j < subCount; j++)
                {
                    var subEmitterSystem = subEmitters.GetSubEmitterSystem(j);
                    if (subEmitterSystem != null && !subEmitterSystem.gameObject.activeInHierarchy && subEmitterSystem.gameObject.activeSelf && !subEmitterSystem.transform.IsChildOf(particleSystem.transform))
                    {
                        findErrorSubEmitterList.Add(subEmitterSystem.name);
                        findErrorSubEmitterList.Add(particleSystem.name);
                    }
                }
            }
        }
        DestroyImmediate(prefab);
        return findErrorSubEmitterList.Count > 0;
    }
    
    bool IsShapeTexturedisableReadWrite(string prefabName, out List<string> findErrorSubEmitterList)
    {
        findErrorSubEmitterList = new List<string>();
        GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabName);
        if (prefab == null) return false;
        prefab = Instantiate(prefab);
        // 获取 Prefab 中的粒子系统组件
        ParticleSystem[] particleSystems = prefab.GetComponentsInChildren<ParticleSystem>(true);
        for (int i = 0; i < particleSystems.Length; i++)
        {
            var particleSystem = particleSystems[i];
            if (particleSystem != null && particleSystem.shape.enabled && particleSystem.shape.texture != null && !particleSystem.shape.texture.isReadable)
            {
                findErrorSubEmitterList.Add(particleSystem.name);
            }
        }
        DestroyImmediate(prefab);
        return findErrorSubEmitterList.Count > 0;
    }
    
    void OnGUI()
    {
        EditorGUILayout.LabelField(@"填入要搜索的目录，例如：Assets/ABPack");
        inputText = EditorGUILayout.TextField("", inputText);
        inputText = inputText.Replace(@"\",@"/");
        if (GUILayout.Button("开始搜索"))
        {
            string[] allPrefabs = AssetDatabase.FindAssets("t:Prefab", new string[] { inputText });
            ClearPrefabs();
            for (int i = 0; i < allPrefabs.Length; i++)
            {
                allPrefabs[i] = AssetDatabase.GUIDToAssetPath(allPrefabs[i]);
                if(IsNotFindSubEmitterRef(allPrefabs[i], out var errorSubEmitterList))
                {
                    AddErrorSubEmitterPrefab(SubEmitterErrorType.NotFindSubEmitterRef, allPrefabs[i], errorSubEmitterList);
                }
                else  if(IsRefSameSubEmitter(allPrefabs[i], out errorSubEmitterList))
                {
                    AddErrorSubEmitterPrefab(SubEmitterErrorType.RefSameSubEmitter, allPrefabs[i], errorSubEmitterList);
                }
                else  if(IsSubEmitterDisActive(allPrefabs[i], out errorSubEmitterList))
                {
                    AddErrorSubEmitterPrefab(SubEmitterErrorType.SubEmitterNotBeChildren, allPrefabs[i], errorSubEmitterList);
                }
                
                if (IsShapeTexturedisableReadWrite(allPrefabs[i], out errorSubEmitterList))
                {
                    AddErrorSubEmitterPrefab(SubEmitterErrorType.ShapeTextureDisableReadWrite, allPrefabs[i], errorSubEmitterList);
                }
            }
        }
        ShowErrorParticles("引用了一个不存在的子发射器，错误列表：", SubEmitterErrorType.NotFindSubEmitterRef);
        ShowErrorParticles("多个主发射器引用同一个子发射器，错误列表：", SubEmitterErrorType.RefSameSubEmitter);
        ShowErrorParticles("子发射器被设置disActive状态，错误列表：", SubEmitterErrorType.SubEmitterNotBeChildren);
        ShowErrorParticles("ShapeModule的texture需要开启可读写，错误列表：", SubEmitterErrorType.ShapeTextureDisableReadWrite);
    }

    private void AddErrorSubEmitterPrefab(SubEmitterErrorType errorType, string prefabName, List<string> errorSubEmitterList)
    {
        ErrorSubEmitterPrefab errorSubEmitterPrefab = new ErrorSubEmitterPrefab();
        errorSubEmitterPrefab.prefabName = prefabName;
        errorSubEmitterPrefab.errorSubEmitterList = errorSubEmitterList;
        prefabs[errorType].Add(errorSubEmitterPrefab);
    }

    private void ShowErrorParticles(string errorTitle, SubEmitterErrorType errorType)
    {
        prefabPaths.Clear();
        EditorGUILayout.LabelField(errorTitle);
        scrollDic[errorType] = GUILayout.BeginScrollView(scrollDic[errorType]);
        {
            for (int i = 0; i < prefabs[errorType].Count; i++)
            {
                GUILayout.BeginHorizontal();
                {
                    string errorSubEmitterListStr ;
                    string prefabPath;
                    if (prefabs[errorType][i].errorSubEmitterList.Count > 0)
                    {
                        errorSubEmitterListStr = string.Join(";", prefabs[errorType][i].errorSubEmitterList);
                        prefabPath = prefabs[errorType][i].prefabName + ";" + errorSubEmitterListStr;
                        prefabPaths.Add(prefabPath);
                    }
                    else
                    {
                        prefabPath = prefabs[errorType][i].prefabName;
                        prefabPaths.Add(prefabPath);
                    }
                    prefabPaths.Add(prefabPath);
                    GUILayout.Label(prefabPath);
                    GUILayout.FlexibleSpace();
                    if (GUILayout.Button("Show"))
                    {
                        EditorGUIUtility.PingObject(AssetDatabase.LoadAssetAtPath(prefabs[errorType][i].prefabName, typeof(GameObject)));
                    }
                }
                GUILayout.EndHorizontal();
            }

            if (prefabPaths.Count != 0 && printCount < prefabs.Count)
            {
                printCount++;
                string text = string.Join("\n", prefabPaths);
                Debug.Log(errorTitle);
                Debug.Log(text);
            }
        }
        GUILayout.EndScrollView();
    }


    [MenuItem("Tools/找出错误的粒子特效(流水线)")]
    public static void CheckErrorSubEmitterSystemByPipeline()
    {
        GetWindow<FindErrorSubEmitterSystemWindow>().CheckErrorSubEmitterSystem();
    }

    public void CheckErrorSubEmitterSystem()
    {
        string searchPath = "Assets/ABPack";
        //string searchPath = "Assets/ABPack/Resources/Actors/h_leona/Skin08/InGame/Effects/Default"; // local test
        string[] allPrefabs = AssetDatabase.FindAssets("t:Prefab", new string[] { searchPath });
        for (int i = 0; i < allPrefabs.Length; i++)
        {
            allPrefabs[i] = AssetDatabase.GUIDToAssetPath(allPrefabs[i]);
            if (IsNotFindSubEmitterRef(allPrefabs[i], out var errorSubEmitterList))
            {
                AddErrorSubEmitterPrefab(SubEmitterErrorType.NotFindSubEmitterRef, allPrefabs[i], errorSubEmitterList);
            }
            else if (IsRefSameSubEmitter(allPrefabs[i], out errorSubEmitterList))
            {
                AddErrorSubEmitterPrefab(SubEmitterErrorType.RefSameSubEmitter, allPrefabs[i], errorSubEmitterList);
            }
            else if (IsSubEmitterDisActive(allPrefabs[i], out errorSubEmitterList))
            {
                AddErrorSubEmitterPrefab(SubEmitterErrorType.SubEmitterNotBeChildren, allPrefabs[i], errorSubEmitterList);
            }

            if (IsShapeTexturedisableReadWrite(allPrefabs[i], out errorSubEmitterList))
            {
                AddErrorSubEmitterPrefab(SubEmitterErrorType.ShapeTextureDisableReadWrite, allPrefabs[i], errorSubEmitterList);
            }
        }

        // 保存文件供后续企业微信通知
        SaveErrorParticles("NotFindSubEmitterRef", SubEmitterErrorType.NotFindSubEmitterRef);
        SaveErrorParticles("RefSameSubEmitter", SubEmitterErrorType.RefSameSubEmitter);
        SaveErrorParticles("SubEmitterNotBeChildren", SubEmitterErrorType.SubEmitterNotBeChildren);
        SaveErrorParticles("ShapeTextureDisableReadWrite", SubEmitterErrorType.ShapeTextureDisableReadWrite);
    }

    private void SaveErrorParticles(string filename, SubEmitterErrorType errorType)
    {
        List<string> assets_path = new List<string>();
        for (int i = 0; i < prefabs[errorType].Count; i++)
        {
            string errorSubEmitterListStr = "";
            if (prefabs[errorType][i].errorSubEmitterList.Count > 0)
            {
                errorSubEmitterListStr = string.Join(";", prefabs[errorType][i].errorSubEmitterList);
            }
            string prefabPath = prefabs[errorType][i].prefabName + ":" + errorSubEmitterListStr;
            assets_path.Add(prefabPath);
        }

        save_file(assets_path, filename + ".txt");
    }

    private void save_file(List<string> assets_path, string filename)
    {
        string save_path = Application.dataPath + "/../log/" + filename;
        if (!Directory.Exists(Application.dataPath + "/../log/"))
            Directory.CreateDirectory(Application.dataPath + "/../log");
        if (File.Exists(save_path)) File.Delete(save_path);
        File.AppendAllLines(save_path, assets_path);
    }

}