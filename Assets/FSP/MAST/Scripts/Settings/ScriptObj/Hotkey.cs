using UnityEngine;

#if (UNITY_EDITOR)

namespace MAST
{
    namespace Settings
    {
        namespace ScriptObj
        {
            [System.Serializable]
            public class Hotkey : ScriptableObject
            {
                [SerializeField] public KeyCode drawSingleKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier drawSingleMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode drawContinuousKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier drawContinuousMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode paintSquareKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier paintSquareMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode randomizerKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier randomizerMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode eraseKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier eraseMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode newRandomSeedKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier newRandomSeedMod = HotkeyModifier.NONE;
                
                [SerializeField] public KeyCode toggleGridKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier toggleGridMod = HotkeyModifier.NONE;
                
                [SerializeField] public KeyCode moveGridUpKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier moveGridUpMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode moveGridDownKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier moveGridDownMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode deselectPrefabKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier deselectPrefabMod = HotkeyModifier.NONE;
                
                [SerializeField] public KeyCode rotatePrefabKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier rotatePrefabMod = HotkeyModifier.NONE;
                
                [SerializeField] public KeyCode flipPrefabKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier flipPrefabMod = HotkeyModifier.NONE;
                
                [SerializeField] public KeyCode paintMaterialKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier paintMaterialMod = HotkeyModifier.SHIFT;
                
                [SerializeField] public KeyCode restoreMaterialKey = KeyCode.Escape;
                [SerializeField] public HotkeyModifier restoreMaterialMod = HotkeyModifier.SHIFT;
            }
        }
    }
}
#endif