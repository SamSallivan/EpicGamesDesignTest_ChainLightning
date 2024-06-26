using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

//Added Function Die(), Damage(),
//And postprocessing effect when taken damage.
public class PlayerController : MonoBehaviour, Damagable//, Slappable
{
	public static PlayerController instance;

	public WeaponManager weaponManager; 

	public Transform t;

	public Transform tHead;

	public Rigidbody rb;

	public CapsuleCollider playerCollider;

	public PlayerDecapitate playerDecapitate;

	public Grounder grounder;

	public PlayerSlide slide;
	public PlayerDash dash;

	public MouseLook mouseLook;

	public CameraBob bob;

	public HeadPosition headPosition;

	public float hTemp;

	public float vTemp;

	public float h;

	public float v;

	public float speed = 1f;

	public Vector3 inputDir;

	public Vector3 vel;

	public Vector3 gVel;

	public Vector3 gDir;

	public Vector3 gDirCross;

	public Vector3 gDirCrossProject;

	public RaycastHit hit;

	public float airControl = 1f;

	public float airControlBlockTimer;

	public Vector3 jumpForce = new Vector3(0f, 15f, 0f);

	public float gTimer;

	public float gravity = -40f;

	public int climbState;

	public float climbTimer;

	public Vector3 climbStartPos;

	public Vector3 climbStartDir;

	public Vector3 climbTargetPos;

	public AnimationCurve climbCurve;

	public GameObject poofVFX; 

	public GameObject slamVFX; 

	public bool extraUpForce;

	public float damageTimer;   
	public PostProcessVolume volume;
    public Bloom bloom;
    public ChromaticAberration ca;
    public ColorGrading cg;
    public Vignette vg;

	private void Awake()
	{
        Cursor.lockState = CursorLockMode.Locked;
		Cursor.visible = false;
		instance = this;
		t = base.transform;
		tHead = t.Find("Head Pivot").transform;
		rb = GetComponent<Rigidbody>();
		playerCollider = GetComponent<CapsuleCollider>();
		grounder = GetComponent<Grounder>();
		slide = GetComponent<PlayerSlide>();
		dash = GetComponent<PlayerDash>();
        weaponManager = GetComponentInChildren<WeaponManager>(true);
        playerDecapitate = GetComponentInChildren<PlayerDecapitate>(true);
		bob = tHead.GetComponentInChildren<CameraBob>();
		headPosition = tHead.GetComponentInChildren<HeadPosition>();
		mouseLook = tHead.GetComponentInChildren<MouseLook>();

		volume = FindObjectOfType<PostProcessVolume>();
		volume.profile.TryGetSettings(out bloom);
		volume.profile.TryGetSettings(out ca);
		volume.profile.TryGetSettings(out cg);
		volume.profile.TryGetSettings(out vg);

		poofVFX = Instantiate(poofVFX, Vector3.zero, Quaternion.identity);
		slamVFX = Instantiate(slamVFX, Vector3.zero, Quaternion.identity);
    }

	//Executes when taken damage from a source.
	public void Damage(Damage damage)
	{
		slamVFX.transform.position = transform.position;
		slamVFX.transform.rotation = Quaternion.LookRotation(transform.forward);
		slamVFX.GetComponent<ParticleSystem>().Play();

		//When blocking, knocks off the current weapon.
		if (weaponManager.IsBlocking())
		{
			weaponManager.weaponControllerList[weaponManager.currentWeaponIndex].OnWeaponBlock();
			rb.AddForce(damage.dir * 20f, ForceMode.Impulse);
			bob.Sway(new Vector4(-20f, 20f, 0f, 5f));
		}
		//if player hasnt taken damage in 3 seconds, knocks player back and upwwards.
		//and next attck in 3 seconds will kill player.
		else if (damageTimer <= 0f && damage.amount < 100f)
		{
			if (grounder.grounded)
			{
				grounder.Unground();
				airControlBlockTimer = 0.2f;
				rb.velocity = Vector3.zero;
				rb.AddForce((Vector3.up + (Vector3)damage.dir).normalized * 10f, ForceMode.Impulse);
			}
			bob.Sway(new Vector4(5f, 0f, 30f, 3f));
			damageTimer = 3f;
			//QuickEffectsPool.Get("Damage", tHead.position, Quaternion.LookRotation(tHead.forward)).Play();
		}
		//else kill player.
		else
		{
			Die(damage.dir);
			TimeManager.instance.SlowMotion(0.1f, 1f, 0.2f);
		}
	}

	//Turns on Postprocessing. 
	//Enables the camera that simulates the decapitated head.
	//Disables Player.
	public void Die(Vector3 dir)
	{
		bloom.intensity.value = 10;
		ca.intensity.value = 10;
		cg.mixerGreenOutRedIn.value = -100;
		vg.intensity.value = 0.3f;

		playerDecapitate.gameObject.SetActive(true);
		playerDecapitate.Decapitate(tHead, dir);
		base.gameObject.SetActive(false);
	}

	private void JumpOrClimb()
	{
		//if is climbing, return
		if (rb.isKinematic)
		{
			return;
		}

		//if grounded, or just ungrouned, or just finished climbing
		//jump
		if (grounder.grounded
			|| gTimer > 0f 
			|| (climbState == 2 && climbTimer > 0.8f))
		{
			if (climbState == 2)
			{
				rb.isKinematic = false;
				climbState = 0;
			}
			Jump();
			return;
		}
		
		//if not grounded, but there is prop or enemy below
		//super jump
		Collider[] array = new Collider[1];
		Physics.OverlapCapsuleNonAlloc(t.position, t.position + Vector3.down * 1.25f, 1f, array, 25600);
		if (array[0] != null)
		{
			switch (array[0].gameObject.layer)
			{
			case 10:
			if (array[0].attachedRigidbody.isKinematic)
				{
					Damage damage = new Damage();
					damage.amount = 10f;
					damage.dir = t.forward;
					array[0].GetComponent<Damagable>().Damage(damage);
				}
				else
				{
					array[0].GetComponent<Slappable>().Slap(Vector3.down);
				}
				Jump(1.6f);
				bob.Sway(new Vector4(Mathf.Clamp(vel.magnitude, 5f, 10f), 0f, 0f, 4f));
				
				slamVFX.transform.position = t.position;
				slamVFX.transform.rotation = Quaternion.LookRotation(Vector3.up);
				slamVFX.GetComponent<ParticleSystem>().Play();

				break;
			case 13:
				weaponManager.DropCurrentWeapon(Vector3.up + tHead.forward);
                Weapon targetWeapon = array[0].GetComponent<Weapon>();
                weaponManager.EquipWeapon(targetWeapon);
				//QuickEffectsPool.Get("Enemy Jump", t.position, Quaternion.LookRotation(Vector3.up)).Play();
				//CameraController.shake.Shake(2);
				bob.Sway(new Vector4(Mathf.Clamp(vel.magnitude, 5f, 10f), 0f, 0f, 4f));
				Jump((rb.velocity.y > 1f) ? 1.75f : 1.5f);
				//midairActionPossible = true;
				break;
			case 14:
				if (!array[0].attachedRigidbody.isKinematic)
				{
					array[0].GetComponent<Slappable>().Slap(tHead.forward);
				}
				Jump((rb.velocity.y > 1f) ? 1.75f : 1.5f);
				bob.Sway(new Vector4(Mathf.Clamp(vel.magnitude, 5f, 10f), 0f, 0f, 4f));
				
				slamVFX.transform.position = t.position;
				slamVFX.transform.rotation = Quaternion.LookRotation(Vector3.up);
				slamVFX.GetComponent<ParticleSystem>().Play(); 	
				
				break;
			}
			array[0] = null;
		} 

		//if none, check if player can climb
		else
		{
			Climb();
		}
	}

	public void Jump(float multiplier = 1f)
	{
		//if jumping on top of props, push props away
		if ((bool)grounder.groundCollider && grounder.groundCollider.gameObject.layer == 14)
		{
			Rigidbody attachedRigidbody = grounder.groundCollider.attachedRigidbody;
			if ((bool)attachedRigidbody)
			{
				attachedRigidbody.AddForce(Vector3.up * (7f * attachedRigidbody.mass), ForceMode.Impulse);
				attachedRigidbody.AddTorque(tHead.forward * 90f, ForceMode.Impulse);
			}
		}

		//ungrounds and jumps
		grounder.Unground();
		gTimer = 0f;
		rb.velocity = new Vector3(0, 0, 0);
		rb.AddForce(jumpForce * multiplier, ForceMode.Impulse);
	}

	private void Climb()
	{	//if climbing, or no surface to climb up to, or surface too low, or obsticle on top of landing spot, too close to ground
		//no climbing
		if (climbState > 0
			|| !Physics.Raycast(t.position + Vector3.up * 1.5f + tHead.forward * 2f, Vector3.down, out hit, 4f, 1)
			|| !(hit.point.y + 1f > t.position.y)
			|| Physics.Raycast(new Vector3(t.position.x, hit.point.y + 1f, t.position.z), tHead.forward.normalized, 2f, 1) 
			|| Physics.Raycast(t.position, Vector3.down, 1.5f, 1)
			|| Physics.Raycast(t.position, Vector3.up, 2.5f, 1))
		{
			return;
		}
		
		//else sets target position and start climbing
		climbTargetPos = hit.point + hit.normal;
		climbState = 3;
	}

	private void ClimbingUpdate()
	{
		switch (climbState)
		{
			//sets player rb to kinematic to directly modify position
			case 3:
				rb.isKinematic = true;
				rb.velocity = Vector3.zero;
				climbTimer = 0f;
				climbStartPos = rb.position;
				climbStartDir = climbStartPos;
				climbStartDir.y += 2f;
				bob.Sway(new Vector4(10f, 0f, -5f, 2f));
				
				poofVFX.transform.position = climbTargetPos;
				ParticleSystem particle = poofVFX.GetComponent<ParticleSystem>();
				particle.Play();

				climbState--;
				break;

			//lerps from start position to target position based on curve value at current time
			//finishes climbing when timer ends
			case 2:
				bob.Angle(Mathf.Sin(climbTimer * (float)Mathf.PI * 5f));
				climbTimer = Mathf.MoveTowards(climbTimer, 1f, Time.deltaTime * 3f);
				t.position = Vector3.LerpUnclamped(climbStartPos, climbTargetPos, climbCurve.Evaluate(climbTimer));
				if (climbTimer == 1f)
				{
					climbState--;
				}
				break;
			
			//sets player rb back to not kinematic
			case 1:
				rb.isKinematic = false;
				climbState--;
				break;
		}
	}


	private void InputUpdate()
    {
        if(Time.timeScale == 0)
		{
			return;
		}

        vTemp = 0f;
		vTemp += (Input.GetKey(KeyCode.W) ? 1 : 0);
		vTemp += (Input.GetKey(KeyCode.S) ? (-1) : 0);
		hTemp = 0f;
		hTemp += (Input.GetKey(KeyCode.A) ? (-1) : 0);
		hTemp += (Input.GetKey(KeyCode.D) ? 1 : 0);
		v = vTemp;
		h = hTemp;

		inputDir.x = h;
		inputDir.y = 0f;
		inputDir.z = v;
		inputDir = inputDir.normalized;

		if (Input.GetKeyDown(KeyCode.Space))
		{
			JumpOrClimb();
		}

		if (Input.GetKeyDown(KeyCode.LeftShift))
		{
			slide.Slide();
		}
		if (Input.GetKeyDown(KeyCode.E))
		{
			dash.Dash();
		}

	}

	private void BobUpdate()
	{

		//tilts camera based on horizontal input
		if (slide.slideState == 0 && !rb.isKinematic)
		{
			
			bob.Angle(h * -4f - damageTimer * 3f);
		}

		//applies camera bob when grounded, walking, and not sliding
		//or sets camera position back to 0
		if (grounder.grounded && inputDir.sqrMagnitude > 0.25f && slide.slideState == 0)
		{
			if (gVel.sqrMagnitude > 1f)
			{
				bob.Bob(speed);
			}
			else
			{
				bob.Reset();
			}
		}
		else
		{
			bob.Reset();
		}

	}
    
	private void Update()
	{
		InputUpdate();

		BobUpdate();

		headPosition.PositionUpdate();

		if (climbState > 0)
		{
			ClimbingUpdate();
		}
		
		if (slide.slideState > 0)
		{
			slide.SlidingUpdate();
		}

		if (dash.state > 0)
		{
			dash.DashingUpdate();
		}

		//counts down the timer that restricts air control 
		if (airControlBlockTimer > 0f)
		{
			airControlBlockTimer -= Time.deltaTime;
			airControl = 0f;
		}

		//sets air control back to 1 over time
		else if (airControl != 1f)
		{
			airControl = Mathf.MoveTowards(airControl, 1f, Time.deltaTime);
		}

		if (gTimer > 0f)
		{
			gTimer -= Time.deltaTime;
		}

		if (damageTimer != 0f)
		{
			damageTimer = Mathf.MoveTowards(damageTimer, 0f, Time.deltaTime);
			bloom.intensity.value = Mathf.Lerp(0, 10, damageTimer/3);
			ca.intensity.value = Mathf.Lerp(0, 1, damageTimer/3);
			cg.mixerGreenOutRedIn.value = Mathf.Lerp(0, -100, damageTimer/3);
			vg.intensity.value = Mathf.Lerp(0, 0.3f, damageTimer/3);
		}
	}

	private void FixedUpdate()
	{
		//recalculates the previous velocity based on new ground normals
		vel = rb.velocity;
		gVel = Vector3.ProjectOnPlane(vel, grounder.groundNormal);

		//recalculates direction based on new ground normals
		gDir = tHead.TransformDirection(inputDir);
		gDirCross = Vector3.Cross(Vector3.up, gDir).normalized;
		gDirCrossProject = Vector3.ProjectOnPlane(grounder.groundNormal, gDirCross);
		gDir = Vector3.Cross(gDirCross, gDirCrossProject);

		
		if (slide.slideState == 0)
		{
			//if moving fast, apply the calculated movement.
			//based on new input subtracted by previous velocity
			//so that player accelerates faster when start moving.
			if (inputDir.sqrMagnitude > 0.25f)
			{
				if (grounder.grounded)
				{
					rb.AddForce(gDir * 100f - gVel * 10f * speed);
				}
				else if (airControl > 0f)
				{
					rb.AddForce((gDir * 100f - gVel * 10f * speed) * airControl);
				}
			}
			//if not fast, accelerates the slowing down process
			else if (grounder.grounded && gVel.sqrMagnitude != 0f)
			{
				rb.AddForce(-gVel * 10f);
			}
		}
		else if (slide.slideState == 2)
		{
			//if sliding, modifies the direction according to horizontal inputs
			if (Mathf.Abs(h) > 0.1f)
			{
				rb.AddForce(Vector3.Cross(slide.slideDir, grounder.groundNormal) * (15f * (0f - h)));
			}
			//slows down if player holds back
			if (v < -0.5f)
			{
				rb.AddForce(-vel.normalized * 20f);
			}
		}

		//applies gravity in the direction of ground normal
		//so player does not slide off within the tolerable angle
		rb.AddForce(grounder.groundNormal * gravity);

		if (extraUpForce)
		{
			rb.AddForce(Vector3.up * 12f);
			extraUpForce = false;
		}
	}

}
