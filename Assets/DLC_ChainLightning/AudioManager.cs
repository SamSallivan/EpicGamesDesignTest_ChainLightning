using MyBox;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioManager : MonoBehaviour
{
    public static AudioManager instance;

    [Foldout("AudioClips", true)]
    public List<AudioClip> sfxFire = new List<AudioClip>();
    public List<AudioClip> sfxFireFailed = new List<AudioClip>();
    public List<AudioClip> sfxHit = new List<AudioClip>();
    public List<AudioClip> sfxChain = new List<AudioClip>();

    void Awake()
    {
        instance = this;
    }

    public void Play(List<AudioClip> clips, Transform transform, bool attatch = true, float length = 0, GameObject follow = null, float volume = 0.5f)
    {
        AudioClip clip = clips.GetRandom<AudioClip>();
        //clip.length
        Sfx sfxInstance = new GameObject("sfxInstance").AddComponent<Sfx>();
        if (attatch)
        {
            sfxInstance.transform.parent = transform;
            sfxInstance.transform.localPosition = Vector3.zero;
        }
        else
        {
            sfxInstance.transform.position = transform.position;
        }
        sfxInstance.Initialize(clip, length, follow, volume);
    }

}
