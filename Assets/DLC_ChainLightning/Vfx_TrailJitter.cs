using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Vfx_TrailJitter : MonoBehaviour
{
    public float jitterMultiplier = 1;
    // Update is called once per frame
    void Update()
    {
        Vector3 offset = new Vector3(Random.RandomRange(-jitterMultiplier, jitterMultiplier), Random.RandomRange(-jitterMultiplier, jitterMultiplier), Random.RandomRange(-jitterMultiplier, jitterMultiplier));
        transform.localPosition = offset;
    }
}
