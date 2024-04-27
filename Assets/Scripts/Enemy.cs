using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

//added attack, reaction to slap and damage.
//entering ragdoll state, and getting up and leaving it

public class Enemy : MonoBehaviour, Slappable, Damagable
{
    public NavMeshAgent agent;

    public GameObject player;

    public Transform playerTransform;

    public LayerMask groundMask, playerMask, attackMask;

    public Vector3 targetPos;
    public GameObject targetObj;
	public float health;
	public float minDollDamage = 60f;
    public bool dead; 
    public bool targeted; //Whether it has targeted a proper location.
    public bool doll; //whether enemy is in ragdoll state

    public float coolDown = 10; 
    public float dollTimer = 5f; 

    public float wanderRange, sightRange, attackRange;

    public bool playerInSight, onCoolDown, playerInRange;

    public float angleToPlayer;
    public float attackDamage;

    public Animator animator;

    public List<Collider> ragdollColliders = new List<Collider>();

	private Collider[] colliders = new Collider[2];

    public float materialTimer;

    private void Awake()
    {
        SetRigdoll();
        player = GameObject.Find("Player");
        playerTransform = player.transform;
        agent = GetComponent<NavMeshAgent>();
        animator = GetComponent<Animator>();
        coolDown = 2f;
    }

    //turns red when attacked
    public void MaterialUpdate(){
        if (materialTimer > 0){
            materialTimer = Mathf.MoveTowards(materialTimer, 0, Time.deltaTime*2);
        }
        Color color = Color.Lerp(Color.white, Color.red, materialTimer);
        GetComponentInChildren<Renderer>().material.SetColor("_Color", color);
    }

    //adds all ragdoll rigidbodies into list for future controll.
    //turns them off
    public void SetRigdoll()
    {
        Collider[] colliders = this .gameObject.GetComponentsInChildren<Collider>();
        foreach(Collider c in colliders){
            if(c.gameObject != this.gameObject)
            {
                c.isTrigger = true;
                c.attachedRigidbody.isKinematic = true;
                ragdollColliders.Add(c);
                c.enabled = false;
            }
        }
    }

    //turns own collider, rigidbody off
    //ragdoll rigidbodies, colliders on
    public void EnableRagdoll()
    {
        coolDown = 10;
        doll = true;
        dollTimer = 0f;
        foreach(Collider c in ragdollColliders){
            if(c.gameObject != this.gameObject)
            {
                c.isTrigger = false;
                c.enabled = true;
                c.attachedRigidbody.isKinematic = false;
                GetComponent<CapsuleCollider>().enabled = false;
                GetComponent<Rigidbody>().isKinematic = false;
                GetComponent<Animator>().enabled = false;
                GetComponent<NavMeshAgent>().enabled = false;
            }
        }
    }

    //turns own collider, rigidbody on
    //ragdoll rigidbodies, colliders off
    //restarts animator in order to play get up animation
    public void DisableRagdoll()
    {

        foreach(Collider c in ragdollColliders){
            if(c.gameObject != this.gameObject)
            {
                c.isTrigger = true;
                c.attachedRigidbody.isKinematic = true;
                c.enabled = false;
            }
        }

        GetComponent<CapsuleCollider>().enabled = true;
        GetComponent<Rigidbody>().isKinematic = true;
        animator.enabled = true; 
        animator.Rebind();
        animator.Update(0f);
        
        coolDown = 10f;
        doll = false;

    }

    //keeps setting the angles to the desired direction,
    //in order to override any undesired collision during the getting up animation
    public void GetUpUpdate(){
        transform.eulerAngles = new Vector3(0, transform.eulerAngles.y, 0);
    }

    public void GetUp(){
        GetComponent<NavMeshAgent>().enabled = true;
        coolDown = 0.5f;
    }

    //checks if the ground beneath around has navMesh baked.
    //if so return the nearest position in range
	public Vector3 GetNavMeshPosition(Vector3 pos, float radius = 1f)
	{
        NavMeshHit navHit; 
		if (NavMesh.SamplePosition(pos, out navHit, radius, -1))
		{
			return navHit.position;
		}
		return Vector3.zero;
	}

    private void Update()
    {
        if(health <= 0){
            dead = true;
        }
        playerInSight = Physics.CheckSphere(transform.position, sightRange, playerMask);
        playerInRange = Physics.CheckSphere(transform.position, attackRange, playerMask);

        MaterialUpdate();

        var lookPos = (player.transform.position - transform.position).normalized;
        lookPos.y = 0;
        angleToPlayer = Vector3.Angle(transform.forward, lookPos);

        if(!doll){
            if (coolDown > 0) CoolDown();
            else if (playerInRange && angleToPlayer < 30) Attacking();
            else if (playerInSight) Chasing();
            else if (!playerInSight) Wandering();
        }
        
        //recovers from doll state in 1 second
		if (dollTimer < 1)
		{
			dollTimer += Time.deltaTime;
		}
		else if (doll && !dead)
		{   
            //gets the nearest point underneath that is walkable for AI.
            //if none, moves the doll forward and try again
            RaycastHit hit;
            Physics.Raycast(transform.position, Vector3.down, out hit, 2f, 1);
            if (hit.distance != 0f)
            {
                Vector3 navMeshPosition = GetNavMeshPosition(hit.point, 1f);
                if (navMeshPosition.sqrMagnitude != 0f)
                {   
                    agent.Warp(navMeshPosition);
                    if (transform.eulerAngles.x <180){ //back

                        transform.rotation = Quaternion.LookRotation(-ragdollColliders[0].attachedRigidbody.transform.right);
                        transform.eulerAngles = new Vector3(0, transform.eulerAngles.y, 0);
                    }
                    else{ //front
                        transform.rotation = Quaternion.LookRotation(ragdollColliders[0].attachedRigidbody.transform.right);
                        transform.eulerAngles = new Vector3(0, transform.eulerAngles.y, 0);
                    }

                    DisableRagdoll();
                    
                }
                else
                {
                    ragdollColliders[0].attachedRigidbody.AddForce(ragdollColliders[0].attachedRigidbody.transform.forward * 5f, ForceMode.Impulse);
                    dollTimer = Mathf.Clamp(dollTimer - 0.5f, 0.1f, float.PositiveInfinity);
                }
            }
            else
            {
                ragdollColliders[0].attachedRigidbody.AddForce(ragdollColliders[0].attachedRigidbody.transform.forward * 5f, ForceMode.Impulse);
                dollTimer = Mathf.Clamp(dollTimer - 0.5f, 0.1f, float.PositiveInfinity);
            }

        }
    }

	public void Slap(Vector3 dir)
	{
        
        Vector3 tempDir;
        RaycastHit hit;

		float num = 12f;
        EnableRagdoll();

        //sets different reaction if in or not in doll state
		if (!doll)
		{
			tempDir = Vector3.ProjectOnPlane(dir, PlayerController.instance.grounder.groundNormal);
		}
		else
		{
			tempDir = Quaternion.AngleAxis(5f, PlayerController.instance.tHead.right) * dir;
		}
        //abort if obstacles below 
		for (int i = 0; i < 3; i++)
		{
			Physics.Raycast(ragdollColliders[0].attachedRigidbody.position, tempDir, out hit, num, 148481);
			if (hit.distance != 0f)
			{
				if (hit.collider.gameObject.layer != 0)
				{
					break;
				}
			}
			tempDir = Quaternion.AngleAxis(-10f, PlayerController.instance.tHead.right) * tempDir;
			num -= 2f;
		}

        for (int j = 0; j < ragdollColliders.Count; j++)
        {
            ragdollColliders[j].attachedRigidbody.velocity = tempDir.normalized * ((j == 0) ? 2 : 4);
        }
        ragdollColliders[0].attachedRigidbody.AddForce(Vector3.up * (0), ForceMode.Impulse);
	}

	public virtual void Damage(Damage damage)
	{
        //turns red
        materialTimer = 1;
        Vector3 dir = damage.dir;
        dir.Normalize();

        //if dead, still reacts
		if (dead)
		{
            if(doll){

				for (int j = 0; j < ragdollColliders.Count; j++)
				{
					ragdollColliders[j].GetComponent<Rigidbody>().velocity += dir * 5;
				}
				ragdollColliders[0].GetComponent<Rigidbody>().AddForce(Vector3.up * 10f, ForceMode.Impulse);
				
		        ragdollColliders[0].GetComponent<Rigidbody>().MoveRotation(ragdollColliders[0].GetComponent<Rigidbody>().rotation * Quaternion.Euler(90f, 0f, 0f));

            }
			return;
		}

        //if damage smaller than minial required to enter doll, only deducts health
        if (damage.amount < minDollDamage)
		{

        }
        else{
        //or enters doll state
        //physically react

            if (doll){
            
                EnableRagdoll();

				for (int j = 0; j < ragdollColliders.Count; j++)
				{
					ragdollColliders[j].GetComponent<Rigidbody>().velocity += dir * 5;
				}
				ragdollColliders[0].GetComponent<Rigidbody>().AddForce(Vector3.up * 10f, ForceMode.Impulse);
				
		        ragdollColliders[0].GetComponent<Rigidbody>().MoveRotation(ragdollColliders[0].GetComponent<Rigidbody>().rotation * Quaternion.Euler(90f, 0f, 0f));

            }
            else{
            
                EnableRagdoll();

                for (int j = 0; j < ragdollColliders.Count; j++)
                {
                    ragdollColliders[j].GetComponent<Rigidbody>().velocity = dir * 5;
                }
				ragdollColliders[0].GetComponent<Rigidbody>().AddForce(Vector3.up * 5f, ForceMode.Impulse);
            }
        }

        if (health - damage.amount > 0f)
        {
            health -= damage.amount;
        }
        else
        {
            //dies if health goes below 0, bounces up
            health -= damage.amount;
            Die();
            ragdollColliders[0].GetComponent<Rigidbody>().AddForce(Vector3.up * 5f, ForceMode.Impulse);
        }
    }

    //disables main collider on death
    //leaving ragdoll colliders
	private void Die()
    {
        EnableRagdoll();
        GetComponent<CapsuleCollider>().enabled = false;
        TimeManager.instance.SlowMotion(0.4f, 0.4f, 0.0f);
        dead = true;
    }

    //resets animation and agent destination on cooldown
    public void CoolDown()
    {
        if(GetComponent<Animator>().enabled)
            GetComponent<Animator>().SetBool("Running", false);
        if(agent.isActiveAndEnabled)
            agent.SetDestination(transform.position); //stops moving when on cool down.
        coolDown -= Time.deltaTime; 
    }

    public void Wandering()
    {
        //Randomizes a position within navmesh.
        if (!targeted) 
        {   
            float randomZ = Random.Range(-wanderRange, wanderRange);
            float randomX = Random.Range(-wanderRange, wanderRange);
            targetPos = new Vector3(transform.position.x + randomX, transform.position.y, transform.position.z + randomZ);

            //Checks if the position is inside of the navmesh.
            if (Physics.Raycast(targetPos, -transform.up, 2f, groundMask)){
                NavMeshHit hit;
                NavMeshPath path = new NavMeshPath();
                if(agent.enabled)
                    agent.CalculatePath(targetPos, path);
                if(NavMesh.SamplePosition(targetPos, out hit, 1f, NavMesh.AllAreas) && path.status == NavMeshPathStatus.PathComplete){
                    targeted = true;
                    //targetObj.transform.position = targetPos;
                }
            }
        }
        
        //Moves towards the position.
        if (targeted)
        {   
            if(agent.isActiveAndEnabled){
                agent.SetDestination(targetPos);
                animator.SetBool("Running", true);
            }

            //Goes on cooldown when reaches the position.
            Vector3 distanceToWalkPoint = transform.position - targetPos;
            if (distanceToWalkPoint.magnitude < 2.5f)
            {
                targeted = false;
                coolDown = Random.Range(0f, 1f);
                animator.SetBool("Running", false);
            }
        }

    }
    
    public void Chasing()
    {
        //Moves towards the player.
        var lookPos = player.transform.position - transform.position;
        lookPos.y = 0;
        var rotation = Quaternion.LookRotation(lookPos);
        transform.rotation = Quaternion.Slerp(transform.rotation, rotation, Time.deltaTime * 5f); 

        if(agent.isActiveAndEnabled){
            agent.SetDestination(playerTransform.position);
            animator.SetBool("Running", true);
        }
    }
    
    //plays attack animation
    public void Attacking()
    {        
        if(agent.isActiveAndEnabled)
            agent.SetDestination(transform.position);
        animator.SetBool("Running", false);
        animator.SetTrigger("Attack");
        coolDown = 10;
    }

    //finds player or props and apply damage 
    void Srike()
    {		
        var targetDir = (player.transform.position - transform.position).normalized;
        targetDir.y = 0;
        if (Vector3.Angle(transform.forward, targetDir) < 60)
		{
			transform.rotation = Quaternion.LookRotation(targetDir);
            Physics.OverlapBoxNonAlloc(transform.position + transform.forward * 1.25f, new Vector3(0.7f, 1.25f, 1.25f), colliders, transform.rotation, attackMask);
            for (int i = 0; i < colliders.Length; i++)
            {
                if (colliders[i] == null)
                {
                    continue;
                }
                if (colliders[i].gameObject.layer == LayerMask.NameToLayer("Player"))
                {
                    Damagable attackTarget = colliders[i].GetComponent<Damagable>();
                    if (attackTarget != null)
                    {
                        Damage damage = new Damage(attackDamage);
                        damage.dir = targetDir;
                        damage.dir.y = 0f;
                        damage.amount = attackDamage;
                        attackTarget.Damage(damage);
                    }
                }
                colliders[i] = null;
            }
		}

        //goes on cooldown, 
        coolDown = Random.Range(0.5f, 1f);
        }
    
}
