using System;
using UnityEngine;
using System.Collections.Generic;

public class ParticleModelScriptableObject : ScriptableObject
{
    public ushort guid = 0; // auto add guid for mutiple file sync.
    public ushort[] guids;
    public ParticleModelObjectData[] datas;

    public ParticleModelObjectData Get(ushort guid)
    {
        if (guid < 0) return null;
        if (guids.Length != datas.Length) return null;

        for (int i = 0, max = guids.Length; i < max; ++i)
        {
            if (guids[i] == guid)
            {
                return datas[i];
            }
        }


        return null;
    }

    public ushort GenGUID()
    {
        return ++guid;
    }

    public void SaveData(Dictionary<ushort, ParticleModelObjectData> collection)
    {
        int length = 0;
        foreach (var item in collection)
        {
            if (item.Key > 0 && item.Value != null)
            {
                ++length;
            }
        }

        guids = new ushort[length];
        datas = new ParticleModelObjectData[length];

        int index = 0;
        foreach (var item in collection)
        {
            if (item.Key > 0 && item.Value != null)
            {
                guids[index] = item.Key;
                datas[index] = item.Value;
                ++index;
            }
        }
    }

    public Dictionary<ushort, ParticleModelObjectData> LoadData()
    {
        var collection = new Dictionary<ushort, ParticleModelObjectData>();
        if (guids == null || datas == null) return collection;

        if (guids.Length == datas.Length)
        {
            for (int index = 0, max = guids.Length; index < max; ++index)
            {
                collection.Add(guids[index], datas[index]);
            }
        }

        return collection;
    }
}

[Serializable]
public class ParticleModelObjectData
{
    public ParticlePoolComponentBase.TrailModule[] trailmodule;
    public ParticlePoolComponentBase.LightsModule[] lightsmodule;
    public ParticlePoolComponentBase.TextureSheetAnimationModule[] texturesheetanimationmodule;
    public ParticlePoolComponentBase.SubEmittersModule[] subemittersmodule;
    public ParticlePoolComponentBase.NoiseModule[] noisemodule;
    public ParticlePoolComponentBase.ExternalForcesModule[] externalforcesmodule;
    public ParticlePoolComponentBase.RotationBySpeedModule[] rotationbyspeedmodule;
    public ParticlePoolComponentBase.RotationOverLifetimeModule[] rotationoverlifetimemodule;
    public ParticlePoolComponentBase.SizeBySpeedModule[] sizebyspeedmodule;
    public ParticlePoolComponentBase.SizeOverLifetimeModule[] sizeoverlifetimemodule;
    public ParticlePoolComponentBase.ColorBySpeedModule[] colorbyspeedmodule;
    public ParticlePoolComponentBase.ColorOverLifetimeModule[] coloroverlifetimemodule;
    public ParticlePoolComponentBase.ForceOverLifetimeModule[] forceoverlifetimemodule;
    public ParticlePoolComponentBase.InheritVelocityModule[] inheritvelocitymodule;
    public ParticlePoolComponentBase.LimitVelocityOverLifetimeModule[] limitvelocityoverlifetimemodule;
    public ParticlePoolComponentBase.VelocityOverLifetimeModule[] velocityoverlifetimemodule;
    public ParticlePoolComponentBase.ShapeModule[] shapemodule;
    public ParticlePoolComponentBase.EmissionModule[] emissionmodule;
    public ParticlePoolComponentBase.MainModule[] mainmodule;
    // public List<ParticleSystemVertexStream> vertexStreams;

#if UNITY_EDITOR
    public string assetName;

    public ParticleModelObjectData(string _assetName)
    {
        assetName = _assetName;
    }
#endif

}
