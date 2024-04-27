using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[RequireComponent(typeof(AudioSource))]
public class Sfx : MonoBehaviour
{
    public AudioSource audioSource;
    //AudioClip audioClip;
    private float curLifeTime;
    public float maxLifeTime;
    private GameObject followOnDestory;

    public void Initialize(AudioClip clip, float length = 0, GameObject follow = null, float volume = 0.5f)
    {
        audioSource = gameObject.AddComponent<AudioSource>();
        //audioClip = clip;
        if (length == 0)
        {
            maxLifeTime = clip.length;
        }
        else
        {
            maxLifeTime = length;

        }
        if (follow)
        {
            followOnDestory = follow;
        }
        else
        {
            followOnDestory = gameObject;
        }
        audioSource.clip = clip;
        audioSource.volume = volume;
        audioSource.maxDistance = 50;
        audioSource.Play();
    }

    // Update is called once per frame
    void Update()
    {
        curLifeTime = Mathf.Clamp(curLifeTime + Time.deltaTime, 0f, maxLifeTime);
        if (curLifeTime >= maxLifeTime || !followOnDestory)
        {
            Destroy(gameObject);
        }
    }
}
