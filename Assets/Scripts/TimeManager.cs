using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeManager : MonoBehaviour
{
    public static TimeManager instance;
	private bool timeIsStopped;

	private float slowmoScale;

	private float slowmoDuration;

	private float slowmoDelay;

	private float cachedTimeScale;

	public float sinTime { get; private set; }

	private void Awake()
	{
		instance = this;
    }
    
	public void SlowMotion(float scale = 0.1f, float duration = 0.1f, float delay = 0f)
	{
		slowmoScale = scale;
		slowmoDuration = duration;
		slowmoDelay = delay;
	}

	public void StopSlowmo()
	{
		slowmoDuration = 0f;
	}

	public void Stop()
	{
		timeIsStopped = true;
		cachedTimeScale = Time.timeScale;
		Time.timeScale = 0f;
	}

	public void Play()
	{
		timeIsStopped = false;
		Time.timeScale = cachedTimeScale;
	}

	private void Update()
	{
		Shader.SetGlobalFloat("_UnscaledTime", Time.unscaledTime);
		sinTime = Mathf.MoveTowards(sinTime, (float)Mathf.PI * 2f, Time.deltaTime);
		if (sinTime == (float)Mathf.PI * 2f)
		{
			sinTime = 0f;
		}

		if (timeIsStopped)
		{
			return;
		}
		if (slowmoDelay > 0f)
		{
			slowmoDelay -= Time.unscaledDeltaTime;
		}
		else if (slowmoDuration > 0f)
		{
			if (Time.timeScale != slowmoScale)
			{
				Time.timeScale = slowmoScale;
			}
			slowmoDuration -= Time.unscaledDeltaTime;
		}
		else if (Time.timeScale != 1f)
		{
			Time.timeScale = 1f;
		}
	}
}
