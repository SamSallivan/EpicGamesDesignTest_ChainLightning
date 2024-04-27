using MyBox;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Attached to the initial lightning projectile that player fired
public class Projectile_ChainLightning : Projectile
{
    //Chain lightning's settings
    public Settings_ChainLightning chainLightningSettings;

    //When projectile hits a damagable object
    public override void HitBehavior(GameObject hitObject)
    {
        //Deal damage to the damagable object
        Damage damage = new Damage();
        damage.amount = hitDamage;
        damage.dir = gameObject.GetComponent<Rigidbody>().velocity;
        hitObject.GetComponent<Damagable>().Damage(damage);

        //If the hit object is an Enemy type
        //Create an invisible actor that manages the chaining logic
        //And begin chaining around the hit object
        Enemy hitEnemy = hitObject.GetComponent<Enemy>();
        if (hitEnemy)
        {
            Actor_ChainLightning onHitSpawnedActor = new GameObject("Actor_ChainLightning").AddComponent<Actor_ChainLightning>();
            onHitSpawnedActor.Initialize(chainLightningSettings, hitEnemy);
        }
    }

    //When projectile collides with any physical object
    public override void CollisionBehavior(Collision collision)
    {
        Instantiate(chainLightningSettings.hitVfx, collision.contacts[0].point, Quaternion.identity);
        AudioManager.instance.Play(AudioManager.instance.sfxHit, transform, false, 0, null, 0.25f);
    }

}

//A collection of variables that alternates the chaining logic
[System.Serializable]
public class Settings_ChainLightning
{
    public float chainDamage;
    public float chainRadius;

    //The delay between chainings
    public float chainInterval;

    //Whether this delay decreases after each chaining
    public bool accelerateChainInterval; 

    //If delay decreases, the lowest it could go
    [ConditionalField(nameof(accelerateChainInterval))]
    public float minChainInterval;
    
    public int maxChainTargetCount;
    public LayerMask chainTargetSearchLayers;

    //When searching for the next chaining target
    //If there are multiple valid results
    //Choose one base on this setting
    public SearchLogic searchLogic;
    
    public GameObject chainVfx;
    public GameObject hitVfx;
    public float vfxSpeed;

    public enum SearchLogic
    {
        ClosestInRange,
        RandomInRange,
        FurthestInRange
    }
}
