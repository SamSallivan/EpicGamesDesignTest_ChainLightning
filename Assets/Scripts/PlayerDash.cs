using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//enables player to dash and grab targeted weapon
public class PlayerDash : MonoBehaviour
{
    public GameObject target;

	public float maxDist = 20f;

	public float timer;

	public float speed = 30f;

	public Vector3 dir;

	public Vector3 startPos;

	public Vector3 targetPos;

	public Vector4 startSway = new Vector4(5f, 0f, 0f, 3f);

	public RaycastHit hit;

	public Weapon targetWeapon;

	public PlayerController player { get; private set; }

	public bool isDashing;

	public int state;

	private void Awake()
	{
		player = GetComponent<PlayerController>();
	}

	public void Reset()
	{
		player.rb.isKinematic = false;
		player.headPosition.Slide(0.75f);
		isDashing = false;
		state = 0;
	}

    public void Update(){
		
		maxDist = 9f;
		float leastAngle = 30f;
		float weaponAngle = 0f;
		int index = -1;

        Weapon[] allWeapons = FindObjectsOfType<Weapon>();

		//gets weapon most within range and angle
		for (int i = 0; i < allWeapons.Length; i++)
		{
			if (!allWeapons[i].isActiveAndEnabled)
			{
				continue;
			}
			float dist = Vector3.Distance(PlayerController.instance.t.position, allWeapons[i].t.position);
			if (!(dist < maxDist))
			{
				continue;
			}
			bool grounded = PlayerController.instance.grounder.grounded;
            Vector3 playerPos =  PlayerController.instance.tHead.position;
			Vector3 weaponDir = (allWeapons[i].t.position - playerPos).normalized;
			weaponAngle = Vector3.Angle(PlayerController.instance.tHead.forward, weaponDir);
			if (weaponAngle < leastAngle)
			{
				leastAngle = weaponAngle;
				if (index != i)
				{
					index = i;
				}
			}
		}
		//enables weapon indicator arrow if targeted
		if (index > -1)
		{
            targetWeapon = allWeapons[index];

			if((bool)targetWeapon.GetComponent<FloatingWeapon>()){
				target.transform.GetChild(0).GetComponent<MeshRenderer>().enabled = true;
				target.transform.position = allWeapons[index].transform.position + Vector3.up * 1.25f;
			}
			else if((bool)targetWeapon.GetComponent<DroppedWeapon>()){
				target.transform.GetChild(0).GetComponent<MeshRenderer>().enabled = true;
				target.transform.position = allWeapons[index].transform.position + Vector3.up * 0.5f;
			}

            MenuManager.instance.eTip.gameObject.SetActive(true);
        }
        else{
            if(!isDashing)
                targetWeapon = null;
			target.transform.GetChild(0).GetComponent<MeshRenderer>().enabled = false;
            MenuManager.instance.eTip.gameObject.SetActive(false);
        }
    }

	public bool Dash()
	{
		if (targetWeapon == null)
		{
			return false;
		}

		//checks if weapon is far from ground
		//allows player to get to exact weapon position if player is in air
		//or dashes player to beneath the weapon
		if (!isDashing && state == 0)
		{
			Physics.Raycast(targetWeapon.t.position, Vector3.down, out hit, (player.grounder.grounded) ? 10 : 1, 1);
			if (hit.distance != 0f) //got ground beneath
			{
				targetPos = hit.point + Vector3.up; //dashes to the ground point
			}
			else//not close to ground
			{
				targetPos = targetWeapon.t.position; //dashes to weapon in air
			}
			state = 3;
			isDashing = true;
			targetWeapon.rb.isKinematic = true;
			return true;
		}
		return false;
	}

	//dashes player to targeted weapon
	public void DashingUpdate()
	{
		switch (state)
		{
			//throw current weapon
			//locks target, calculates speed, dir
			case 3:
				if (player.grounder.grounded)
				{
					player.grounder.Unground();
				}
				player.weaponManager.DropCurrentWeapon(Vector3.up + player.tHead.forward);
				player.rb.isKinematic = true;
				startPos = player.rb.position;
				dir = (targetPos - startPos).normalized;
				speed = Mathf.Abs((8f - Vector3.Distance(player.t.position, targetPos) / 2f));
				speed = Mathf.Clamp(speed, 2f, 8f);
				player.headPosition.Slide(0f);
				player.bob.Sway(startSway);
				timer = 0f;
				state--;
				break;
			//move towards weapon
			case 2:
				timer = Mathf.MoveTowards(timer, 1f, Time.deltaTime * speed);
				player.t.position = Vector3.Lerp(startPos, targetPos, timer - 0.2f);
				player.bob.Angle(0f);
				if (timer == 1f)
				{
					state--;
				}
				break;
			//equips targeted weapon
			case 1:
				player.rb.isKinematic = false;
				player.rb.AddForce(dir * 20f, ForceMode.Impulse);
				player.airControl = 1;
				player.airControlBlockTimer = 0.2f;
				player.headPosition.Slide(0.75f);

				//targetWeapon.Interact(player.weapons);
				player.weaponManager.EquipWeapon(targetWeapon);

                isDashing = false;
				state--;
				break;
		}
	}
}
