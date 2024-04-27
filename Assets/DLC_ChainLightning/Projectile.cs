using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
[RequireComponent(typeof(Collider))]
public class Projectile : MonoBehaviour
{
    public float speed = 10;
    //layers that receives player damage.
    public LayerMask collidableLayers;
    public float hitDamage;
    private bool collidedOnce = false;

    public float igonoreCollisionTimeOnSpawn = 0;
    private float curLifeTime;
    public float maxLifeTime = 5f;
    private int curCollisionCount;
    public int maxCollisionCount = 1;

    private Vector3 spawnPos;
    public float maxDistance = 15f;
    public float destroyDelay = 1;

    void Start()
    {
        spawnPos = transform.position;
        GetComponent<Rigidbody>().AddForce(transform.forward * speed, ForceMode.Impulse);
        GetComponent<Collider>().enabled = false;

    }

    void Update()
    {
        //deactivates the bullet when time is up.
        curLifeTime = Mathf.Clamp(curLifeTime + Time.deltaTime, 0f, maxLifeTime);
        if (curLifeTime >= maxLifeTime || Vector3.Distance(spawnPos, transform.position) >= maxDistance)
        {
            StartCoroutine(DelayedDDestroy());
        }
        if (curLifeTime >= igonoreCollisionTimeOnSpawn)
        {
            GetComponent<Collider>().enabled = true;
        }

    }

    public void OnCollisionEnter(Collision c)
    {

        if (collidableLayers == (collidableLayers | (1 << c.gameObject.layer)))
        {
            HitBehavior(c.gameObject);
        }
        CollisionBehavior(c);
        curCollisionCount++;

        if (curCollisionCount >= maxCollisionCount)
        {
            StartCoroutine(DelayedDDestroy());
        }
    }

    public virtual void HitBehavior(GameObject hitObject) { }
    public virtual void CollisionBehavior(Collision collision) { }

    IEnumerator DelayedDDestroy()
    {
        yield return new WaitForSeconds(destroyDelay);
        Destroy(gameObject);
    }
}
