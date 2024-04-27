using System;
using UnityEngine;
using System.Collections;
using UnityEngine.Playables;

public class BasePlayableBehaviour : PlayableBehaviour
{
    private float lastUpdateTime = 0;
    private bool isAwake = false;
    internal virtual void OnAwake(Playable playable)
    {

    }

    internal virtual void OnEnable()
    {

    }

    internal virtual void OnUpdate(float currentTime, float deltaTime, Playable playable, FrameData info, object playerData)
    {

    }

    public override void ProcessFrame(Playable playable, FrameData info, object playerData)
    {
        base.ProcessFrame(playable, info, playerData);

        var currentTime = (float)playable.GetTime();
        var deltaTime = info.deltaTime;
        if (info.effectiveSpeed!=1)
        {
            deltaTime *= info.effectiveSpeed;
        }
        if (lastUpdateTime == 0 || (lastUpdateTime - currentTime > float.Epsilon))
        {
            OnEnable();
        }
        lastUpdateTime = currentTime;
        OnUpdate(currentTime, deltaTime, playable, info, playerData);
    }

    public override void OnGraphStart(Playable playable)
    {
        base.OnGraphStart(playable);
        if (!isAwake)
        {
            isAwake = true;
            OnAwake(playable);
        }
    }
}
