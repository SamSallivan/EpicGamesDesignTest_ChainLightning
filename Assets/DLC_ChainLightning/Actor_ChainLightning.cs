using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Attached to the invisible actor created upon lightning projectile hit
public class Actor_ChainLightning : MonoBehaviour
{
    //Chain lightning's settings
    public Settings_ChainLightning settings;
    
    //A list that keeps track of already struck enemies
    private List<Enemy> targetHistoryList = new List<Enemy>();

    //Initialize the chaining logic
    public void Initialize(Settings_ChainLightning settings, Enemy sourceEnemy)
    {
        //Copy settings from the projectile
        this.settings = settings;
        //Add the source enemy to the target history so it won't be struck again
        targetHistoryList.Add(sourceEnemy);
        //Begin chaining around the source enemy
        StartCoroutine(ChainLightning(sourceEnemy));
    }

    //Chaining Process
    IEnumerator ChainLightning(Enemy sourceEnemy)
    {
        //Calculate the delay before next chaining based on the settings
        float interval;
        if (settings.accelerateChainInterval) {
            interval = Mathf.Max(settings.chainInterval - targetHistoryList.Count * settings.chainInterval / settings.maxChainTargetCount, settings.minChainInterval);
        }
        else
        {
            interval = settings.chainInterval;
        }

        //Search for a valid target enemy
        Enemy targetEnemy = SearchChainTarget(sourceEnemy);

        //If a valid target enemy is found, and maximum chaining count hasn't been reached yet
        if (targetEnemy && targetHistoryList.Count < settings.maxChainTargetCount)
        {
            //Deal damage to the target enemy
            Damage damage = new Damage();
            damage.dir = Vector3.zero;
            damage.amount = settings.chainDamage;
            targetEnemy.GetComponent<Damagable>().Damage(damage);

            //Play chaining VFX between the source and target enemy
            float vfxSpeed = settings.accelerateChainInterval ? settings.vfxSpeed * settings.chainInterval / interval : settings.vfxSpeed;
            Vfx_Billboard billboard1 = Instantiate(settings.hitVfx, sourceEnemy.transform.position, Quaternion.identity).GetComponent<Vfx_Billboard>();
            billboard1.Initiate(sourceEnemy.gameObject, new Vector3(0, 0f, 0), vfxSpeed);
            Vfx_Billboard billboard2 = Instantiate(settings.hitVfx, targetEnemy.transform.position, Quaternion.identity).GetComponent<Vfx_Billboard>();
            billboard2.Initiate(targetEnemy.gameObject, new Vector3(0, 0f, 0), vfxSpeed);
            Vfx_Chain chain = Instantiate(settings.chainVfx).GetComponent<Vfx_Chain>();
            chain.Initiate(sourceEnemy.gameObject,targetEnemy.gameObject, new Vector3(0, 0f, 0), vfxSpeed);

            //Play chaining SFX
            AudioManager.instance.Play(AudioManager.instance.sfxChain, targetEnemy.transform, true, 0, null, 0.15f);

            //Add the target enemy to the target history so it won't be struck again
            targetHistoryList.Add(targetEnemy);

            //Wait for a period of time based on the settings
            yield return new WaitForSeconds(interval);
            //Then repeat the entire previous process, this time around the new target enemy
            StartCoroutine(ChainLightning(targetEnemy));
        }
        else
        {
            Destroy(gameObject);
        }
    }

    //Search for, and return a valid target enemy around a given enemy
    private Enemy SearchChainTarget(Enemy sourceEnemy)
    {
        //Searches for all enemies around the given enemy in the set layers
        Collider[] colliders = Physics.OverlapSphere(sourceEnemy.transform.position, settings.chainRadius, settings.chainTargetSearchLayers);

        //if the search returns at least one object
        if (colliders.Length > 0)
        {
            float distance;
            float minDistance = settings.chainRadius;
            float maxDistance = 0;
            Enemy targetEnemy = null;

            //From all enemies found, choose and return one enemy based on the settings
            switch (settings.searchLogic)
            {
                //returns the closest target
                case Settings_ChainLightning.SearchLogic.ClosestInRange:

                    for (int i = 0; i < colliders.Length; i++)
                    {
                        Enemy curEnemy = colliders[i].GetComponent<Enemy>();
                        //Checks if the enemy has already been struck
                        if (curEnemy && !targetHistoryList.Contains(curEnemy))
                        {
                            distance = Vector3.Distance(sourceEnemy.transform.position, colliders[i].ClosestPoint(sourceEnemy.transform.position));
                            if (distance <= minDistance)
                            {
                                minDistance = distance;
                                targetEnemy = curEnemy;
                            }
                        }
                    }

                    return targetEnemy;

                //returns the furthest target
                case Settings_ChainLightning.SearchLogic.FurthestInRange:

                    for (int i = 0; i < colliders.Length; i++)
                    {
                        Enemy curEnemy = colliders[i].GetComponent<Enemy>();
                        //Checks if the enemy has already been struck
                        if (curEnemy && !targetHistoryList.Contains(curEnemy))
                        {
                            distance = Vector3.Distance(sourceEnemy.transform.position, colliders[i].ClosestPoint(sourceEnemy.transform.position));
                            if (distance > maxDistance)
                            {
                                maxDistance = distance;
                                targetEnemy = curEnemy;
                            }
                        }
                    }

                    return targetEnemy;

                //returns a random target
                case Settings_ChainLightning.SearchLogic.RandomInRange:

                    List<Enemy> curTargetList = new List<Enemy>();
                    for (int i = 0; i < colliders.Length; i++)
                    {
                        Enemy curEnemy = colliders[i].GetComponent<Enemy>();
                        //Checks if the enemy has already been struck
                        if (curEnemy && !targetHistoryList.Contains(curEnemy))
                        {
                            curTargetList.Add(curEnemy);
                        }
                    }
                    if (curTargetList.Count > 0) {
                        targetEnemy = curTargetList[Random.Range(0, curTargetList.Count - 1)];
                    }
                    return targetEnemy;

            }
        }

        return null;
    }

}
