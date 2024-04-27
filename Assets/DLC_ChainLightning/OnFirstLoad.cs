using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OnFirstLoad : MonoBehaviour
{
    public static OnFirstLoad instance;
    // Start is called before the first frame update
    void Awake()
    {
        if (!OnFirstLoad.instance)
        {
            instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }
    void Start()
    {
        DontDestroyOnLoad(this.gameObject);
        MenuManager.instance.Pause();
    }
}
