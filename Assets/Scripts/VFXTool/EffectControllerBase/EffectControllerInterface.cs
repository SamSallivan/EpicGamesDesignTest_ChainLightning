

public enum EffectControlType
{
    FXMaker = 0,    // legacy fxmaker工具制作
    Timeline = 1,   // timeline工具制作
}

public interface EffectControllerInterface
{
    EffectControlType GetEffectType();

    void SetEffectType(EffectControlType effect);

    void CopyAttrTo(EffectControllerInterface ctrl);
}
