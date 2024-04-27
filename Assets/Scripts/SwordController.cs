using MyBox;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Extension of weapon controller.
//Currently taking the form of a Baseball Bat Weapon in game.
public class SwordController : WeaponController
{
    [Foldout("Slash Settings", true)]
    //The damage information that will be passed down to its target when attack landed.
    protected Damage damage = new Damage();

	//The weapon object in player's hand.
	public GameObject objWeapon;

	//layers that receives player damage.
	public LayerMask layerMask;

	//Curves that returns exact damage amount, according to charge time.
	public AnimationCurve slashDamageCurve;
	public AnimationCurve slamSlashDamageCurve;

	//Switches on off, so that player slashes 2 ways.
	public bool rightSlash;

	public float slashCooldown;

	private void OnEnable()
	{
		slashCooldown = 0f;
		attackState = 0;
		if (!objWeapon.activeInHierarchy)
		{
			objWeapon.SetActive(true);
		}
		rightSlash = false;
		playerController.bob.Sway(new Vector4(0f, 0f, -5f, 2f));
	}

	protected override void Awake()
	{
		base.Awake();
		Grounder grounder = playerController.grounder;
		grounder.OnGround += Ground;
	}

	private void OnDestroy()
	{
		Grounder grounder = playerController.grounder;
		grounder.OnGround -= Ground;
	}

	//sways player camera when started charging an attack.
	public void Charge()
	{
		switch (attackIndex)
		{
			case 0:
			case 1:
				playerController.bob.Sway(new Vector4(0f, 0f, rightSlash ? 5 : (-5), 2f));
				break;
			case 2:
				playerController.bob.Sway(new Vector4(-6f, 0f, 0f, 2f));
				break;
		}
	}

	//sways player camera depending on attack types.
	public void Sway()
	{
		switch (attackIndex)
		{
			//left right strike
			case 0:
			case 1:
				playerController.bob.Sway(new Vector4(0f, Mathf.Lerp(10f, 30f, chargeTimer) * (float)((attackIndex == 0) ? 1 : (-1)), 0f, 5f));
				break;
			//slam
			case 2:
				playerController.bob.Sway(new Vector4(Mathf.Lerp(10f, 30f, chargeTimer), 0f, 0f, 5f));
				break;
			//throw
			case 3:
				playerController.bob.Sway(new Vector4(10f, 0f, 0f, 5f));
				break;
			//block
			case 4:
				playerController.bob.Sway(new Vector4(0f, 0f, 5f, 4f));
				break;
		}
	}

	//Checks if an attack lands on a Damagable layer.
	//damages colliders entered.
	public void SlashCheck(Vector3 slashBoxSize)
	{
		Physics.OverlapBoxNonAlloc(playerController.tHead.position + playerController.tHead.forward * slashBoxSize.z / 2f, slashBoxSize, colliders, playerController.tHead.rotation, layerMask);
		for (int i = 0; i < colliders.Length; i++)
		{
			if (colliders[i] != null)
			{
				colliders[i].GetComponent<Damagable>().Damage(damage);
				colliders[i] = null;
			}
		}
	}

	//Passes Damage information down to targets, depending on attack types.
	public void Strike()
	{
		switch (attackIndex)
		{
			//left right slash
			case 0:
			case 1:
				damage.dir = ((playerController.tHead.forward + playerController.tHead.right * ((attackIndex == 0) ? 1 : (-1))) / 2f).normalized;
				damage.amount = slashDamageCurve.Evaluate(chargeTimer);
				Debug.Log(damage.amount);
				SlashCheck(new Vector3(2f, 0.5f, 2.5f));
				rightSlash = !rightSlash;
				break;
			//downward
			case 2:
			{
				damage.dir = ((playerController.tHead.forward + playerController.tHead.up / 2f) / 2f).normalized;
				damage.amount = slamSlashDamageCurve.Evaluate(chargeTimer);
				SlashCheck(new Vector3(0.5f, 2f, 3f));
				break;
			}
			//throw
			case 3:
				//WeaponManager
				//Weapon drop = GameObject.Instantiate(manager.weaponDrops[manager.currentWeaponIndex], player.tHead.position - player.tHead.forward*1f, Quaternion.LookRotation(player.tHead.right)).GetComponent<Weapon>();
				float dropDistance = Mathf.Lerp(2.5f, 7.5f, chargeTimer);
				weaponManager.LaunchCurrentWeapon(playerController.tHead.forward * dropDistance, 90f, playerController.tHead.forward * -0.5f);
				objWeapon.SetActive(false);
				break;
		}

		chargeTimer = 0f;
		attackState = 0;
		attackIndex = -1;
		animator.SetInteger("Attack Index", attackIndex);
	}

/*
	public void Drop()
	{
		weaponManager.EquipWeapon(-1);
	}
*/

	//Drops current weapon on ground is block succeeds.
	public override void OnWeaponBlock()
	{
		if (attackIndex == 4)
		{
			animator.SetTrigger("Damage");
			if (chargeTimer >= 0.5f)
			{	
				TimeManager.instance.SlowMotion(0.1f, 0.3f, 0.2f);
                //Weapon drop = Instantiate(weaponManager.weaponDrops[weaponManager.currentWeaponIndex], player.tHead.position + player.tHead.forward*5, Quaternion.LookRotation(player.tHead.right)).GetComponent<Weapon>();
                weaponManager.DropCurrentWeapon(playerController.tHead.forward * 5, -90f, playerController.tHead.forward*5);
				//weaponManager.EquipWeapon(-1);		
			}
			//CameraController.shake.Shake(2);
			isBlocking = false;
			attackIndex = -1;
			attackState = 0;
			animator.SetInteger("Attack Index", attackIndex);
			chargeTimer = 0f;
		}
	}

	//Releases players charge attack when lands on ground.
	private void Ground()
	{
		if (animator.GetInteger("Attack Index") == 2)
		{
			animator.SetTrigger("Release");
			slashCooldown = 0.1f;
		}
	}

	//Sets up an attack of given type.
	private void ChargeAttackWithIndex(int i, float time = 0f)
	{
		attackIndex = i;
		animator.SetInteger("Attack Index", attackIndex);
		animator.SetTrigger("Charge");
		chargeTimer = time;
	}

	//receives attack inputs, and triggers corresponding attacks, depending on the attack state.
	public override void WeaponInputeUpdate()
	{
		base.WeaponInputeUpdate();

        if (slashCooldown > 0f)
		{
			slashCooldown -= Time.deltaTime;
			return;
		}
		isBlocking = attackIndex == 4 && attackState != 0;

		switch (attackState)
		{
			//if not attacking.
			case 0:
				if (!objWeapon.activeInHierarchy)
				{
					break;
				}
				
				if (Input.GetKey(KeyCode.Mouse0) && Input.GetKey(KeyCode.Mouse1))
				{
					playerController.bob.Sway(new Vector4(0f, 0f, 5f, 3f));
					ChargeAttackWithIndex(4);
					attackState = 1;
				}
				else if (Input.GetKey(KeyCode.Mouse0))
				{
					if (playerController.grounder.grounded)
					{
						ChargeAttackWithIndex(rightSlash ? 1 : 0);
					}
					else
					{
						ChargeAttackWithIndex(2);
					}
					attackState = 1;
				}
				else if (Input.GetKey(KeyCode.Mouse1))
				{
					ChargeAttackWithIndex(3);
					attackState = 1;
				}
				break;

			//if is charging or attacking. 
			case 1:
				switch (attackIndex)
				{

				//slashing
				case 0:
				case 1:
					if (Input.GetKeyDown(KeyCode.Mouse1))
					{
						ChargeAttackWithIndex(4);
						playerController.bob.Sway(new Vector4(0f, 0f, 5f, 3f));
					}
					if (Input.GetKeyDown(KeyCode.Space))
					{
						ChargeAttackWithIndex(2);
					}
					if (!Input.GetKey(KeyCode.Mouse0) && chargeTimer > 0.25f)
					{
						animator.SetTrigger("Release");
						attackState++;
					}
					chargeTimer = Mathf.MoveTowards(chargeTimer, 1f, Time.deltaTime * 1.5f);
					break;

				//downward slash
				case 2:
					if (Input.GetKey(KeyCode.Mouse0))
					{
						playerController.extraUpForce = true;
					}
					if (Input.GetKeyDown(KeyCode.Mouse1))
					{
						ChargeAttackWithIndex(3, chargeTimer);
						if (attackIndex == 3)
						{
							playerController.bob.Sway(new Vector4(0f, 0f, 5f, 3f));
						}
					}
					if (Input.GetKeyUp(KeyCode.Mouse0))
					{
						playerController.rb.AddForce(Vector3.down * 10f, ForceMode.Impulse);
						animator.SetTrigger("Cancel");
					}
					chargeTimer = Mathf.MoveTowards(chargeTimer, 1f, Time.deltaTime);
					break;

				//aiming
				case 3:

					if (Input.GetKeyUp(KeyCode.Mouse1))
					{
						attackState = 0;
						attackIndex = -1;
						animator.SetInteger("Attack Index", attackIndex);
						animator.SetTrigger("Cancel");
					}

					if (Input.GetKeyDown(KeyCode.Mouse0))
					{
						animator.SetTrigger("Release");
						attackState++;
					}
					chargeTimer = Mathf.MoveTowards(chargeTimer, 1f, Time.deltaTime * 2.5f);
					break;
				//blocking
				case 4:
					chargeTimer = Mathf.MoveTowards(chargeTimer, 1f, Time.deltaTime * 2.5f);
                    if (!Input.GetKey(KeyCode.Mouse0) || !Input.GetKey(KeyCode.Mouse1))// && chargeTimer > 0.5f)
                    {
						animator.SetTrigger("Cancel");
						attackIndex = -1;
						animator.SetInteger("Attack Index", attackIndex);
						chargeTimer = 0f;
						attackState = 0;
                        slashCooldown = 0.1f;
                        }
					break;
				}
				break;
			//finishes an attack
			case 2:
				break;
		}
	}
}
