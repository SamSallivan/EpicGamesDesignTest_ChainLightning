using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using TMPro;


//Manages UI in Pause Screen.
public class MenuManager : MonoBehaviour
{
    //Makes it class static so it's easy to access.
    public static MenuManager instance;

    //Stores where the inverse kinematic target is, relative to screen space.
    public Vector3 screenPoint;

    //Pause screen canvas.
    public GameObject canvas;

    //UI Arm's target.
    public GameObject IKTarget;

    //cam that only captures the UI arm.
    public Camera cam;

    //Records game lapse.
    public float timer;
    public TMP_Text time;

    public GameObject abilityCooldownParent;
    public Image abilityCooldownBg;
    public Image abilityCooldownPie;
    public TMP_Text abilityCooldownText;
    public float abilityCooldownMaterialTimer;

    public TMP_Text lmbTip;
    public TMP_Text rmbTip;
    public TMP_Text eTip;
    public TMP_Text gTip;


    void Awake(){
        instance = this;

    }

    public void MaterialUpdate()
    {
        if (abilityCooldownMaterialTimer > 0)
        {
            abilityCooldownMaterialTimer = Mathf.MoveTowards(abilityCooldownMaterialTimer, 0, Time.deltaTime * 2);
            abilityCooldownBg.color = Color.Lerp(Color.white, Color.red, abilityCooldownMaterialTimer);
        }
        //Color color = Color.Lerp(Color.white, Color.red, materialTimer);
    }

    void Update()
    {
        MaterialUpdate();

        if (Input.GetKeyDown(KeyCode.Escape)){
            if(!canvas.activeInHierarchy){
                Pause();
            }
            else{
                Resume();
                Cursor.lockState = CursorLockMode.Locked;
            }
        }

        //Converts time in second into time as in Min : Sec : Millisec.
        timer = Time.timeSinceLevelLoad;

        float minutes = Mathf.Floor(timer / 60); 
        float seconds = Mathf.Floor(timer%60);
        float milliseconds = Mathf.Floor((timer*1000)%1000);

        string min = minutes.ToString();
        string sec = seconds.ToString();
        string milli = milliseconds.ToString();
        
        //Adds 0 digits before the string if its small enough.
        if(minutes < 10) {
            min = "0" + minutes.ToString();
        }
        if(seconds < 10) {
            sec = "0" + Mathf.RoundToInt(seconds).ToString();
        }
        if(milliseconds < 10) {
            milli = "00" + Mathf.RoundToInt(milliseconds).ToString();
        }
        else if(milliseconds < 100) {
            milli = "0" + Mathf.RoundToInt(milliseconds).ToString();
        }

        //Changes Timer text when pause and unpause.
        if(!canvas.activeInHierarchy){
            time.text = min + ":" + sec + ":" + milli;
        }
        else if(canvas.activeInHierarchy){
            time.text = "Level Cleared In:  " + min + ":" + sec + ":" + milli;
        }

        if(IKTarget.activeInHierarchy){
            OnMouseDrag();
        }

    }

    public void Pause(){
        canvas.SetActive(true);
        Cursor.lockState = CursorLockMode.Confined;
        Cursor.visible = true;
        TimeManager.instance.Stop();
    }
    
    public void Resume(){
        canvas.SetActive(false);
        TimeManager.instance.Play();
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    public void Restart(){
        SceneManager.LoadScene(SceneManager.GetActiveScene().name,LoadSceneMode.Single);

        Resume();
    }

    public void Title(){
        TimeManager.instance.Play();
        SceneManager.LoadScene("Title", LoadSceneMode.Single);
    }

    //Gets IKTarget's position in screen, 
    //Gets Mouse position in world,
    //Sets IKTarget's position to mouse position in world,
    //So it only moves on the plane parallel to screen.
    void OnMouseDrag()
    {
        screenPoint = cam.WorldToScreenPoint(IKTarget.transform.position);

        Vector3 curScreenPoint = new Vector3(Input.mousePosition.x, Input.mousePosition.y, screenPoint.z);

        Vector3 curPosition = cam.ScreenToWorldPoint(curScreenPoint);
        IKTarget.transform.position = curPosition;

    }
}
