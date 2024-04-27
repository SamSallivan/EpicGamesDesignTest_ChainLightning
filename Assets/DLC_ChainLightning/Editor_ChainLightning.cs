using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class Editor_ChainLightning : MonoBehaviour
{
    public Projectile_ChainLightning projectile;
    public GameObject enemyParent;

    public Slider maxTarget;
    public Slider searchRange;
    public Dropdown searchLogic;
    public Slider initialInterval;
    public Toggle accelerateChaining;
    public Slider minInterval;
    public Slider vfxSpeed;

    public TMP_Text maxTargetText;
    public TMP_Text searchRangeText;
    public TMP_Text initialIntervalText;
    public TMP_Text minIntervalText;
    public TMP_Text vfxSpeedText;

    public Toggle enemyAI;
    public Dropdown enemyOnHitBehavior;

    private List<Enemy> enemyList = new List<Enemy>();

    // Start is called before the first frame update
    void Start()
    {
        maxTarget.value = projectile.chainLightningSettings.maxChainTargetCount;
        searchRange.value = projectile.chainLightningSettings.chainRadius;
        searchLogic.value = projectile.chainLightningSettings.searchLogic == Settings_ChainLightning.SearchLogic.ClosestInRange ? 0 : 1;
        initialInterval.value = projectile.chainLightningSettings.chainInterval;
        accelerateChaining.isOn = projectile.chainLightningSettings.accelerateChainInterval;
        minInterval.value = projectile.chainLightningSettings.minChainInterval;
        vfxSpeed.value = projectile.chainLightningSettings.vfxSpeed;

        maxTargetText.text = "" + maxTarget.value;
        searchRangeText.text = "" + Mathf.Round(searchRange.value * 100f) / 100f;
        initialIntervalText.text = "" + Mathf.Round(initialInterval.value * 100f) / 100f + "s";
        minIntervalText.text = "" + Mathf.Round(minInterval.value * 100f) / 100f + "s";
        vfxSpeedText.text = "" + Mathf.Round(vfxSpeed.value * 100f) / 100f;

        enemyParent.transform.GetComponentsInChildren<Enemy>(true, enemyList);

    }

    // Update is called once per frame
    void Update()
    {
        projectile.chainLightningSettings.maxChainTargetCount = (int)maxTarget.value;
        projectile.chainLightningSettings.chainRadius = searchRange.value;
        switch (searchLogic.value)
        {
            case 0:
                projectile.chainLightningSettings.searchLogic = Settings_ChainLightning.SearchLogic.ClosestInRange;
                break;
            case 1:
                projectile.chainLightningSettings.searchLogic = Settings_ChainLightning.SearchLogic.RandomInRange;
                break;
            case 2:
                projectile.chainLightningSettings.searchLogic = Settings_ChainLightning.SearchLogic.FurthestInRange;
                break;
        }
        //projectile.chainLightningSettings.searchType = searchLogic.value == 0 ? Settings_ChainLightning.SearchType.ClosestInRange : Settings_ChainLightning.SearchType.RandomInRange;
        projectile.chainLightningSettings.chainInterval = initialInterval.value;
        projectile.chainLightningSettings.accelerateChainInterval = accelerateChaining.isOn;
        projectile.chainLightningSettings.minChainInterval = minInterval.value;
        projectile.chainLightningSettings.vfxSpeed = vfxSpeed.value;

        minInterval.maxValue = initialInterval.value;
        minInterval.gameObject.SetActive(accelerateChaining.isOn);
        if (initialInterval.value < 0.005f)
        {
            accelerateChaining.isOn = false;
            accelerateChaining.gameObject.SetActive(false);
        }
        else
        {
            accelerateChaining.gameObject.SetActive(true);
        }


        maxTargetText.text = "" + maxTarget.value;
        searchRangeText.text = "" + Mathf.Round(searchRange.value * 100f) / 100f;
        initialIntervalText.text = "" + Mathf.Round(initialInterval.value * 100f) / 100f + "s";
        minIntervalText.text = "" + Mathf.Round(minInterval.value * 100f) / 100f + "s";
        vfxSpeedText.text = "" + Mathf.Round(vfxSpeed.value * 100f) / 100f;


        foreach (Enemy enemy in enemyList)
        {
            enemy.sightRange = enemyAI.isOn ? 10 : 0;
            enemy.wanderRange = enemyAI.isOn ? 10 : 0;

            switch (enemyOnHitBehavior.value)
            {
                case 0:
                    enemy.minDollDamage = 26f;
                    projectile.hitDamage = 1;
                    break;
                case 1:
                    enemy.minDollDamage = 1;
                    projectile.hitDamage = 10;
                    break;
                case 2:
                    enemy.minDollDamage = 26f;
                    break;

            }
        }
    }
}
