using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SlapController : MonoBehaviour
{
	public Damage damage = new Damage();

	public Animator animator;

	public PlayerController player;

	public WeaponManager manager;
	
	public LayerMask slapMask;

	public float minDistance;

	public float distance;

	public RaycastHit hit;

	public Collider targetCollider;

	public Collider[] colliders = new Collider[3];

	public bool isCharging;

	public float slapCooldown;

	public GameObject slapVFX; 

	private void Awake()
	{
		animator = GetComponent<Animator>();
		player = GetComponentInParent<PlayerController>();
		manager = GetComponentInParent<WeaponManager>();
	}

	private void OnEnable()
	{
		if (isCharging)
		{
			isCharging = false;
		}
	}

	public void ChargeSway()
	{
		player.bob.Sway(new Vector4(-2.5f, 0f, 0f, 2f));
	}
	public void StrikeSway()
	{
		player.bob.Sway(new Vector4(0f, -10f, 0f, 3f));
	}
	

	public void Strike()
	{
		targetCollider = null;
		minDistance = 100;

		//gives a larger hitbox when in air, for easier control
		if (player.grounder.grounded && player.slide.slideState == 0)
		{
			Physics.OverlapBoxNonAlloc(player.tHead.position + player.tHead.forward * 1.25f, new Vector3(0.7f, 1.25f, 1.25f), colliders, player.tHead.rotation, slapMask);
		}
		else
		{
			Physics.OverlapCapsuleNonAlloc(player.tHead.position, player.tHead.position + player.tHead.forward * 3.5f, 1f, colliders, slapMask);
		}

		//gets the closest one target only
		for (int i = 0; i < colliders.Length; i++)
		{
			if (colliders[i] != null)
			{
				distance = Vector3.Distance(player.tHead.position, colliders[i].ClosestPoint(player.tHead.position));
				if (distance < minDistance)
				{
					minDistance = distance;
					targetCollider = colliders[i];
				}
				colliders[i] = null;
			}
		}

		//if no obstacles between
		if ((bool)targetCollider && !Physics.Linecast(player.tHead.position, targetCollider.ClosestPoint(player.tHead.position), 1))
		{
			Vector3 vector = targetCollider.ClosestPoint(player.tHead.position);

			//boost player up if player in air
			if (!player.grounder.grounded)
			{
				player.rb.position = Vector3.Lerp(player.rb.position, vector, 0.75f);
				player.rb.velocity = Vector3.zero;
				player.rb.AddForce((Vector3.up - player.tHead.forward / 4f).normalized * 5, ForceMode.Impulse);
				player.airControlBlockTimer = 0.25f;
				if (targetCollider.gameObject.layer == 10 && targetCollider.attachedRigidbody.isKinematic)
				{
					damage.dir = player.tHead.forward/2;
				}
				else
				{
					damage.dir = player.tHead.forward;
				}
				player.airControl = 1;

				if (targetCollider.gameObject.layer != 13)
				{
					damage.amount = 25;
					damage.dir = Vector3.zero;
					targetCollider.GetComponent<Damagable>().Damage(damage);
				}
				else
				{
					slapCooldown = 0f;
					targetCollider.GetComponent<Slappable>().Slap(player.tHead.forward);
				}
				if (targetCollider.gameObject.layer == 10)
				{
					//StylePointsCounter.instance.AddStylePoint(StylePointTypes.AirKick);
				}
				player.grounder.Unground();
				//Game.soundsManager.PlayClip(sfxMidAirHit);
			}
			else
			{
				Slappable targetSlappable = targetCollider.GetComponent<Slappable>();
                Damagable targetDamagable = targetCollider.GetComponent<Damagable>();
				if(targetSlappable != null)
                    targetSlappable.Slap(player.tHead.forward);
                if (targetDamagable != null)
                    targetDamagable.Damage(damage);
                damage.amount = 25;
				damage.dir = Vector3.zero;
				if (player.slide.slideState != 0)
				{
					player.rb.position = Vector3.Lerp(player.rb.position, vector, 0.75f);
					player.rb.velocity = Vector3.zero;
				}
								
			}
			player.bob.Sway(new Vector4(10f, 0f, 0f, 5f));
		}
		//or there is no target of given layer
		else
		{
			if (!Physics.Raycast(player.tHead.position, player.tHead.forward, out hit, 2.5f, 1))
			{
				return;
			}
			//if there is wall or ground
			//if player is sliding, boost
			if (player.slide.slideState > 0 && hit.normal.y > 0.5f)
			{
				player.Jump(1.6f);
			}
			//or pushes player back
			else
			{
				player.rb.AddForce(-player.tHead.forward * Mathf.Lerp(8f, 4f, Mathf.Abs(player.tHead.forward.y)), ForceMode.Impulse);
				player.bob.Sway(new Vector4(5f, 0f, 0f, 5f));
				//QuickEffectsPool.Get("Poof", player.tHead.position + player.tHead.forward).Play();
			}
		}
	}

	//receives input on slap
	//if no weapon equipped
	public void SlapInputUpdate()
    {
        if (Time.timeScale == 0)
        {
            return;
        }

        if (manager.currentWeaponIndex != -1)
        {
            isCharging = false;
            animator.ResetTrigger("Release");
            animator.SetTrigger("Cancel");
            return;
        }
		else
        {
            animator.ResetTrigger("Cancel");

            if (slapCooldown != 0f)
			{
				slapCooldown = Mathf.MoveTowards(slapCooldown, 0f, Time.deltaTime * 2f);
				return;
			}

            switch (isCharging)
            {
                case true:
                    if (!Input.GetKey(KeyCode.Mouse0))
                    {
                        animator.SetTrigger("Release");
                        isCharging = false;
                        slapCooldown = 0.5f;
                        slapVFX.GetComponent<ParticleSystem>().Play();
                        TimeManager.instance.StopSlowmo();
                    }
                    break;

                case false:
                    if (Input.GetKey(KeyCode.Mouse0))
                    {
                        animator.SetTrigger("Charge");
                        isCharging = true;
                        if (player.slide.slideState > 0)
                        {
                            player.slide.Extend(1f);
                            TimeManager.instance.SlowMotion(0.1f, 1.5f, 0.25f);
                        }
                    }
                    break;
            }
		}
	}
}
