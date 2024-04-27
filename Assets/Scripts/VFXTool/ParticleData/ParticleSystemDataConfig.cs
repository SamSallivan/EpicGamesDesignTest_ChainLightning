// generate by unity2018.4.2f0
// modify by alkaidfang.

using System;
using UnityEngine;

public partial class ParticlePoolComponentBase : MonoBehaviour
{
    public RenderModel renderModle = default;

    public ParticlePoolComponentBase[] subEmits = default;

    public ushort modelDataGUID = 0;
    public ParticleModelScriptableObject modelDataCollection = null;

    protected ParticleModelObjectData particleModelSo;
    
    [Serializable]
    public class ParticleModel
    {
        public string modelName;
    }

    [Serializable]
    public class RenderModel : ParticleModel
    {
        public Mesh[] mesh;
        public Material material;
        public Material trailMaterial;
        public int sortingOrder;
        public int sortingLayerID;
        public SpriteMaskInteraction maskInteraction;
        public Vector3 flip;
        public Vector3 pivot;
        public float maxParticleSize;
        public float minParticleSize;
        public float sortingFudge;
        public float shadowBias;
        public float normalDirection;
        public float cameraVelocityScale;
        public float velocityScale;
        public float lengthScale;
        public ParticleSystemSortMode sortMode;
        public ParticleSystemRenderMode renderMode;
        public ParticleSystemRenderSpace alignment;
        public bool enableGPUInstancing;
        public bool allowRoll;

        public static RenderModel Get(ParticleSystemRenderer module)
        {
            RenderModel temp = new RenderModel();
            module.GetMeshes(temp.mesh);
            temp.material = module.sharedMaterial;
            temp.trailMaterial = module.trailMaterial;
            temp.sortingOrder = module.sortingOrder;
            temp.sortingLayerID = module.sortingLayerID;
            temp.maskInteraction = module.maskInteraction;
            temp.flip = module.flip;
            temp.pivot = module.pivot;
            temp.maxParticleSize = module.maxParticleSize;
            temp.minParticleSize = module.minParticleSize;
            temp.sortingFudge = module.sortingFudge;
            temp.shadowBias = module.shadowBias;
            temp.normalDirection = module.normalDirection;
            temp.cameraVelocityScale = module.cameraVelocityScale;
            temp.velocityScale = module.velocityScale;
            temp.lengthScale = module.lengthScale;
            temp.sortMode = module.sortMode;
            temp.renderMode = module.renderMode;
            temp.alignment = module.alignment;
            temp.enableGPUInstancing = module.enableGPUInstancing;
            temp.allowRoll = module.allowRoll;

            return temp;
        }
    }

    [Serializable]
    public class SubEmittersModule : ParticleModel
    {
        public bool enabled;
        public int subEmittersCount;
        public ParticleSystemSubEmitterType[] types;
        public ParticleSystemSubEmitterProperties[] properties;
        public static SubEmittersModule Get(ParticleSystem.SubEmittersModule module)
        {
            SubEmittersModule temp = new SubEmittersModule();
            //temp.modelName = "SubEmittersModule";
            temp.enabled = module.enabled;
            temp.subEmittersCount = module.subEmittersCount;
            temp.types = new ParticleSystemSubEmitterType[temp.subEmittersCount];
            temp.properties = new ParticleSystemSubEmitterProperties[temp.subEmittersCount];

            for(int i=0; i < temp.subEmittersCount; i++)
            {
                temp.types[i] = module.GetSubEmitterType(i);
                temp.properties[i] = module.GetSubEmitterProperties(i);
            }

            return temp;
        }
    }

    [Serializable]
    public class TrailModule : ParticleModel
    {
        public bool enabled;
        public UnityEngine.ParticleSystemTrailMode mode;
        public float ratio;
        public MinMaxCurve lifetime;
        public float lifetimeMultiplier;
        public float minVertexDistance;
        public UnityEngine.ParticleSystemTrailTextureMode textureMode;
        public bool worldSpace;
        public bool dieWithParticles;
        public bool sizeAffectsWidth;
        public bool sizeAffectsLifetime;
        public bool inheritParticleColor;
        public MinMaxGradient colorOverLifetime;
        public MinMaxCurve widthOverTrail;
        public float widthOverTrailMultiplier;
        public MinMaxGradient colorOverTrail;
        public bool generateLightingData;
        public int ribbonCount;
        public float shadowBias;
        public bool splitSubEmitterRibbons;
        public bool attachRibbonsToTransform;

        public static TrailModule Get(ParticleSystem.TrailModule module)
        {
            TrailModule temp = new TrailModule();
            //temp.modelName = "TrailModule";

            temp.enabled = module.enabled;
            temp.mode = module.mode;
            temp.ratio = module.ratio;
            temp.lifetime = MinMaxCurve.Get(module.lifetime);
            temp.lifetimeMultiplier = module.lifetimeMultiplier;
            temp.minVertexDistance = module.minVertexDistance;
            temp.textureMode = module.textureMode;
            temp.worldSpace = module.worldSpace;
            temp.dieWithParticles = module.dieWithParticles;
            temp.sizeAffectsWidth = module.sizeAffectsWidth;
            temp.sizeAffectsLifetime = module.sizeAffectsLifetime;
            temp.inheritParticleColor = module.inheritParticleColor;
            temp.colorOverLifetime = MinMaxGradient.Get(module.colorOverLifetime);
            temp.widthOverTrail = MinMaxCurve.Get(module.widthOverTrail);
            temp.widthOverTrailMultiplier = module.widthOverTrailMultiplier;
            temp.colorOverTrail = MinMaxGradient.Get(module.colorOverTrail);
            temp.generateLightingData = module.generateLightingData;
            temp.ribbonCount = module.ribbonCount;
            temp.shadowBias = module.shadowBias;
            temp.splitSubEmitterRibbons = module.splitSubEmitterRibbons;
            temp.attachRibbonsToTransform = module.attachRibbonsToTransform;

            return temp;
        }
    }


    [Serializable]
    public class LightsModule : ParticleModel
    {
        public bool enabled;
        public float ratio;
        public bool useRandomDistribution;
        public UnityEngine.Light light;
        public bool useParticleColor;
        public bool sizeAffectsRange;
        public bool alphaAffectsIntensity;
        public MinMaxCurve range;
        public float rangeMultiplier;
        public MinMaxCurve intensity;
        public float intensityMultiplier;
        public int maxLights;

        public static LightsModule Get(ParticleSystem.LightsModule module)
        {
            LightsModule temp = new LightsModule();
            //temp.modelName = "LightsModule";

            temp.enabled = module.enabled;
            temp.ratio = module.ratio;
            temp.useRandomDistribution = module.useRandomDistribution;
            temp.light = module.light;
            temp.useParticleColor = module.useParticleColor;
            temp.sizeAffectsRange = module.sizeAffectsRange;
            temp.alphaAffectsIntensity = module.alphaAffectsIntensity;
            temp.range = MinMaxCurve.Get(module.range);
            temp.rangeMultiplier = module.rangeMultiplier;
            temp.intensity = MinMaxCurve.Get(module.intensity);
            temp.intensityMultiplier = module.intensityMultiplier;
            temp.maxLights = module.maxLights;

            return temp;
        }
    }


    [Serializable]
    public class TextureSheetAnimationModule : ParticleModel
    {
        public bool enabled;
        public UnityEngine.ParticleSystemAnimationMode mode;
        public UnityEngine.ParticleSystemAnimationTimeMode timeMode;
        public float fps;
        public int numTilesX;
        public int numTilesY;
        public UnityEngine.ParticleSystemAnimationType animation;
#if UNITY_2021_1_OR_NEWER
        public ParticleSystemAnimationRowMode rowMode;
#else
        public bool useRandomRow;
#endif
        public MinMaxCurve frameOverTime;
        public float frameOverTimeMultiplier;
        public MinMaxCurve startFrame;
        public float startFrameMultiplier;
        public int cycleCount;
        public int rowIndex;
        public UnityEngine.Rendering.UVChannelFlags uvChannelMask;
        public int spriteCount;
        public UnityEngine.Vector2 speedRange;

        public static TextureSheetAnimationModule Get(ParticleSystem.TextureSheetAnimationModule module)
        {
            TextureSheetAnimationModule temp = new TextureSheetAnimationModule();
            //temp.modelName = "TextureSheetAnimationModule";

            temp.enabled = module.enabled;
            temp.mode = module.mode;
            temp.timeMode = module.timeMode;
            temp.fps = module.fps;
            temp.numTilesX = module.numTilesX;
            temp.numTilesY = module.numTilesY;
            temp.animation = module.animation;
#if UNITY_2021_1_OR_NEWER
            temp.rowMode = module.rowMode;
#else
            temp.useRandomRow = module.useRandomRow;
#endif
            temp.frameOverTime = MinMaxCurve.Get(module.frameOverTime);
            temp.frameOverTimeMultiplier = module.frameOverTimeMultiplier;
            temp.startFrame = MinMaxCurve.Get(module.startFrame);
            temp.startFrameMultiplier = module.startFrameMultiplier;
            temp.cycleCount = module.cycleCount;
            temp.rowIndex = module.rowIndex;
            temp.uvChannelMask = module.uvChannelMask;
            temp.spriteCount = module.spriteCount;
            temp.speedRange = module.speedRange;

            return temp;
        }
    }


    [Serializable]
    public class NoiseModule : ParticleModel
    {
        public bool enabled;
        public bool separateAxes;
        public MinMaxCurve strength;
        public float strengthMultiplier;
        public MinMaxCurve strengthX;
        public float strengthXMultiplier;
        public MinMaxCurve strengthY;
        public float strengthYMultiplier;
        public MinMaxCurve strengthZ;
        public float strengthZMultiplier;
        public float frequency;
        public bool damping;
        public int octaveCount;
        public float octaveMultiplier;
        public float octaveScale;
        public UnityEngine.ParticleSystemNoiseQuality quality;
        public MinMaxCurve scrollSpeed;
        public float scrollSpeedMultiplier;
        public bool remapEnabled;
        public MinMaxCurve remap;
        public float remapMultiplier;
        public MinMaxCurve remapX;
        public float remapXMultiplier;
        public MinMaxCurve remapY;
        public float remapYMultiplier;
        public MinMaxCurve remapZ;
        public float remapZMultiplier;
        public MinMaxCurve positionAmount;
        public MinMaxCurve rotationAmount;
        public MinMaxCurve sizeAmount;

        public static NoiseModule Get(ParticleSystem.NoiseModule module)
        {
            NoiseModule temp = new NoiseModule();
            //temp.modelName = "NoiseModule";

            temp.enabled = module.enabled;
            temp.separateAxes = module.separateAxes;
            temp.strength = MinMaxCurve.Get(module.strength);
            temp.strengthMultiplier = module.strengthMultiplier;
            temp.strengthX = MinMaxCurve.Get(module.strengthX);
            temp.strengthXMultiplier = module.strengthXMultiplier;
            temp.strengthY = MinMaxCurve.Get(module.strengthY);
            temp.strengthYMultiplier = module.strengthYMultiplier;
            temp.strengthZ = MinMaxCurve.Get(module.strengthZ);
            temp.strengthZMultiplier = module.strengthZMultiplier;
            temp.frequency = module.frequency;
            temp.damping = module.damping;
            temp.octaveCount = module.octaveCount;
            temp.octaveMultiplier = module.octaveMultiplier;
            temp.octaveScale = module.octaveScale;
            temp.quality = module.quality;
            temp.scrollSpeed = MinMaxCurve.Get(module.scrollSpeed);
            temp.scrollSpeedMultiplier = module.scrollSpeedMultiplier;
            temp.remapEnabled = module.remapEnabled;
            temp.remap = MinMaxCurve.Get(module.remap);
            temp.remapMultiplier = module.remapMultiplier;
            temp.remapX = MinMaxCurve.Get(module.remapX);
            temp.remapXMultiplier = module.remapXMultiplier;
            temp.remapY = MinMaxCurve.Get(module.remapY);
            temp.remapYMultiplier = module.remapYMultiplier;
            temp.remapZ = MinMaxCurve.Get(module.remapZ);
            temp.remapZMultiplier = module.remapZMultiplier;
            temp.positionAmount = MinMaxCurve.Get(module.positionAmount);
            temp.rotationAmount = MinMaxCurve.Get(module.rotationAmount);
            temp.sizeAmount = MinMaxCurve.Get(module.sizeAmount);

            return temp;
        }
    }


    [Serializable]
    public class ExternalForcesModule : ParticleModel
    {
        public bool enabled;
        public float multiplier;
        public UnityEngine.ParticleSystemGameObjectFilter influenceFilter;
        public int influenceCount;

        public static ExternalForcesModule Get(ParticleSystem.ExternalForcesModule module)
        {
            ExternalForcesModule temp = new ExternalForcesModule();
            //temp.modelName = "ExternalForcesModule";

            temp.enabled = module.enabled;
            temp.multiplier = module.multiplier;
            temp.influenceFilter = module.influenceFilter;
            temp.influenceCount = module.influenceCount;

            return temp;
        }
    }


    [Serializable]
    public class RotationBySpeedModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve x;
        public float xMultiplier;
        public MinMaxCurve y;
        public float yMultiplier;
        public MinMaxCurve z;
        public float zMultiplier;
        public bool separateAxes;
        public UnityEngine.Vector2 range;

        public static RotationBySpeedModule Get(ParticleSystem.RotationBySpeedModule module)
        {
            RotationBySpeedModule temp = new RotationBySpeedModule();
            //temp.modelName = "RotationBySpeedModule";

            temp.enabled = module.enabled;
            temp.x = MinMaxCurve.Get(module.x);
            temp.xMultiplier = module.xMultiplier;
            temp.y = MinMaxCurve.Get(module.y);
            temp.yMultiplier = module.yMultiplier;
            temp.z = MinMaxCurve.Get(module.z);
            temp.zMultiplier = module.zMultiplier;
            temp.separateAxes = module.separateAxes;
            temp.range = module.range;

            return temp;
        }
    }


    [Serializable]
    public class RotationOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve x;
        public float xMultiplier;
        public MinMaxCurve y;
        public float yMultiplier;
        public MinMaxCurve z;
        public float zMultiplier;
        public bool separateAxes;

        public static RotationOverLifetimeModule Get(ParticleSystem.RotationOverLifetimeModule module)
        {
            RotationOverLifetimeModule temp = new RotationOverLifetimeModule();
            //temp.modelName = "RotationOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.x = MinMaxCurve.Get(module.x);
            temp.xMultiplier = module.xMultiplier;
            temp.y = MinMaxCurve.Get(module.y);
            temp.yMultiplier = module.yMultiplier;
            temp.z = MinMaxCurve.Get(module.z);
            temp.zMultiplier = module.zMultiplier;
            temp.separateAxes = module.separateAxes;

            return temp;
        }
    }


    [Serializable]
    public class SizeBySpeedModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve size;
        public float sizeMultiplier;
        public MinMaxCurve x;
        public float xMultiplier;
        public MinMaxCurve y;
        public float yMultiplier;
        public MinMaxCurve z;
        public float zMultiplier;
        public bool separateAxes;
        public UnityEngine.Vector2 range;

        public static SizeBySpeedModule Get(ParticleSystem.SizeBySpeedModule module)
        {
            SizeBySpeedModule temp = new SizeBySpeedModule();
            //temp.modelName = "SizeBySpeedModule";

            temp.enabled = module.enabled;
            temp.size = MinMaxCurve.Get(module.size);
            temp.sizeMultiplier = module.sizeMultiplier;
            temp.x = MinMaxCurve.Get(module.x);
            temp.xMultiplier = module.xMultiplier;
            temp.y = MinMaxCurve.Get(module.y);
            temp.yMultiplier = module.yMultiplier;
            temp.z = MinMaxCurve.Get(module.z);
            temp.zMultiplier = module.zMultiplier;
            temp.separateAxes = module.separateAxes;
            temp.range = module.range;

            return temp;
        }
    }


    [Serializable]
    public class SizeOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve size;
        public float sizeMultiplier;
        public MinMaxCurve x;
        public float xMultiplier;
        public MinMaxCurve y;
        public float yMultiplier;
        public MinMaxCurve z;
        public float zMultiplier;
        public bool separateAxes;

        public static SizeOverLifetimeModule Get(ParticleSystem.SizeOverLifetimeModule module)
        {
            SizeOverLifetimeModule temp = new SizeOverLifetimeModule();
            //temp.modelName = "SizeOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.size = MinMaxCurve.Get(module.size);
            temp.sizeMultiplier = module.sizeMultiplier;
            temp.x = MinMaxCurve.Get(module.x);
            temp.xMultiplier = module.xMultiplier;
            temp.y = MinMaxCurve.Get(module.y);
            temp.yMultiplier = module.yMultiplier;
            temp.z = MinMaxCurve.Get(module.z);
            temp.zMultiplier = module.zMultiplier;
            temp.separateAxes = module.separateAxes;

            return temp;
        }
    }


    [Serializable]
    public class ColorBySpeedModule : ParticleModel
    {
        public bool enabled;
        public MinMaxGradient color;
        public UnityEngine.Vector2 range;

        public static ColorBySpeedModule Get(ParticleSystem.ColorBySpeedModule module)
        {
            ColorBySpeedModule temp = new ColorBySpeedModule();
            //temp.modelName = "ColorBySpeedModule";

            temp.enabled = module.enabled;
            temp.color = MinMaxGradient.Get(module.color);
            temp.range = module.range;

            return temp;
        }
    }


    [Serializable]
    public class ColorOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxGradient color;

        public static ColorOverLifetimeModule Get(ParticleSystem.ColorOverLifetimeModule module)
        {
            ColorOverLifetimeModule temp = new ColorOverLifetimeModule();
            //temp.modelName = "ColorOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.color = MinMaxGradient.Get(module.color);

            return temp;
        }
    }


    [Serializable]
    public class ForceOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve x;
        public MinMaxCurve y;
        public MinMaxCurve z;
        public float xMultiplier;
        public float yMultiplier;
        public float zMultiplier;
        public UnityEngine.ParticleSystemSimulationSpace space;
        public bool randomized;

        public static ForceOverLifetimeModule Get(ParticleSystem.ForceOverLifetimeModule module)
        {
            ForceOverLifetimeModule temp = new ForceOverLifetimeModule();
            //temp.modelName = "ForceOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.x = MinMaxCurve.Get(module.x);
            temp.y = MinMaxCurve.Get(module.y);
            temp.z = MinMaxCurve.Get(module.z);
            temp.xMultiplier = module.xMultiplier;
            temp.yMultiplier = module.yMultiplier;
            temp.zMultiplier = module.zMultiplier;
            temp.space = module.space;
            temp.randomized = module.randomized;

            return temp;
        }
    }


    [Serializable]
    public class InheritVelocityModule : ParticleModel
    {
        public bool enabled;
        public UnityEngine.ParticleSystemInheritVelocityMode mode;
        public MinMaxCurve curve;
        public float curveMultiplier;

        public static InheritVelocityModule Get(ParticleSystem.InheritVelocityModule module)
        {
            InheritVelocityModule temp = new InheritVelocityModule();
            //temp.modelName = "InheritVelocityModule";

            temp.enabled = module.enabled;
            temp.mode = module.mode;
            temp.curve = MinMaxCurve.Get(module.curve);
            temp.curveMultiplier = module.curveMultiplier;

            return temp;
        }
    }


    [Serializable]
    public class LimitVelocityOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve limitX;
        public float limitXMultiplier;
        public MinMaxCurve limitY;
        public float limitYMultiplier;
        public MinMaxCurve limitZ;
        public float limitZMultiplier;
        public MinMaxCurve limit;
        public float limitMultiplier;
        public float dampen;
        public bool separateAxes;
        public UnityEngine.ParticleSystemSimulationSpace space;
        public MinMaxCurve drag;
        public float dragMultiplier;
        public bool multiplyDragByParticleSize;
        public bool multiplyDragByParticleVelocity;

        public static LimitVelocityOverLifetimeModule Get(ParticleSystem.LimitVelocityOverLifetimeModule module)
        {
            LimitVelocityOverLifetimeModule temp = new LimitVelocityOverLifetimeModule();
            //temp.modelName = "LimitVelocityOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.limitX = MinMaxCurve.Get(module.limitX);
            temp.limitXMultiplier = module.limitXMultiplier;
            temp.limitY = MinMaxCurve.Get(module.limitY);
            temp.limitYMultiplier = module.limitYMultiplier;
            temp.limitZ = MinMaxCurve.Get(module.limitZ);
            temp.limitZMultiplier = module.limitZMultiplier;
            temp.limit = MinMaxCurve.Get(module.limit);
            temp.limitMultiplier = module.limitMultiplier;
            temp.dampen = module.dampen;
            temp.separateAxes = module.separateAxes;
            temp.space = module.space;
            temp.drag = MinMaxCurve.Get(module.drag);
            temp.dragMultiplier = module.dragMultiplier;
            temp.multiplyDragByParticleSize = module.multiplyDragByParticleSize;
            temp.multiplyDragByParticleVelocity = module.multiplyDragByParticleVelocity;

            return temp;
        }
    }


    [Serializable]
    public class VelocityOverLifetimeModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve x;
        public MinMaxCurve y;
        public MinMaxCurve z;
        public float xMultiplier;
        public float yMultiplier;
        public float zMultiplier;
        public MinMaxCurve orbitalX;
        public MinMaxCurve orbitalY;
        public MinMaxCurve orbitalZ;
        public float orbitalXMultiplier;
        public float orbitalYMultiplier;
        public float orbitalZMultiplier;
        public MinMaxCurve orbitalOffsetX;
        public MinMaxCurve orbitalOffsetY;
        public MinMaxCurve orbitalOffsetZ;
        public float orbitalOffsetXMultiplier;
        public float orbitalOffsetYMultiplier;
        public float orbitalOffsetZMultiplier;
        public MinMaxCurve radial;
        public float radialMultiplier;
        public MinMaxCurve speedModifier;
        public float speedModifierMultiplier;
        public UnityEngine.ParticleSystemSimulationSpace space;

        public static VelocityOverLifetimeModule Get(ParticleSystem.VelocityOverLifetimeModule module)
        {
            VelocityOverLifetimeModule temp = new VelocityOverLifetimeModule();
            //temp.modelName = "VelocityOverLifetimeModule";

            temp.enabled = module.enabled;
            temp.x = MinMaxCurve.Get(module.x);
            temp.y = MinMaxCurve.Get(module.y);
            temp.z = MinMaxCurve.Get(module.z);
            temp.xMultiplier = module.xMultiplier;
            temp.yMultiplier = module.yMultiplier;
            temp.zMultiplier = module.zMultiplier;
            temp.orbitalX = MinMaxCurve.Get(module.orbitalX);
            temp.orbitalY = MinMaxCurve.Get(module.orbitalY);
            temp.orbitalZ = MinMaxCurve.Get(module.orbitalZ);
            temp.orbitalXMultiplier = module.orbitalXMultiplier;
            temp.orbitalYMultiplier = module.orbitalYMultiplier;
            temp.orbitalZMultiplier = module.orbitalZMultiplier;
            temp.orbitalOffsetX = MinMaxCurve.Get(module.orbitalOffsetX);
            temp.orbitalOffsetY = MinMaxCurve.Get(module.orbitalOffsetY);
            temp.orbitalOffsetZ = MinMaxCurve.Get(module.orbitalOffsetZ);
            temp.orbitalOffsetXMultiplier = module.orbitalOffsetXMultiplier;
            temp.orbitalOffsetYMultiplier = module.orbitalOffsetYMultiplier;
            temp.orbitalOffsetZMultiplier = module.orbitalOffsetZMultiplier;
            temp.radial = MinMaxCurve.Get(module.radial);
            temp.radialMultiplier = module.radialMultiplier;
            temp.speedModifier = MinMaxCurve.Get(module.speedModifier);
            temp.speedModifierMultiplier = module.speedModifierMultiplier;
            temp.space = module.space;

            return temp;
        }
    }


    [Serializable]
    public class ShapeModule : ParticleModel
    {
        public bool enabled;
        public UnityEngine.ParticleSystemShapeType shapeType;
        public float randomDirectionAmount;
        public float sphericalDirectionAmount;
        public float randomPositionAmount;
        public bool alignToDirection;
        public float radius;
        public UnityEngine.ParticleSystemShapeMultiModeValue radiusMode;
        public float radiusSpread;
        public MinMaxCurve radiusSpeed;
        public float radiusSpeedMultiplier;
        public float radiusThickness;
        public float angle;
        public float length;
        public UnityEngine.Vector3 boxThickness;
        public UnityEngine.ParticleSystemMeshShapeType meshShapeType;
        public UnityEngine.Mesh mesh;
        public UnityEngine.MeshRenderer meshRenderer;
        public UnityEngine.SkinnedMeshRenderer skinnedMeshRenderer;
        public UnityEngine.Sprite sprite;
        public UnityEngine.SpriteRenderer spriteRenderer;
        public bool useMeshMaterialIndex;
        public int meshMaterialIndex;
        public bool useMeshColors;
        public float normalOffset;
        public UnityEngine.ParticleSystemShapeMultiModeValue meshSpawnMode;
        public float meshSpawnSpread;
        public MinMaxCurve meshSpawnSpeed;
        public float meshSpawnSpeedMultiplier;
        public float arc;
        public UnityEngine.ParticleSystemShapeMultiModeValue arcMode;
        public float arcSpread;
        public MinMaxCurve arcSpeed;
        public float arcSpeedMultiplier;
        public float donutRadius;
        public UnityEngine.Vector3 position;
        public UnityEngine.Vector3 rotation;
        public UnityEngine.Vector3 scale;
        public UnityEngine.Texture2D texture;
        public UnityEngine.ParticleSystemShapeTextureChannel textureClipChannel;
        public float textureClipThreshold;
        public bool textureColorAffectsParticles;
        public bool textureAlphaAffectsParticles;
        public bool textureBilinearFiltering;
        public int textureUVChannel;

        public static ShapeModule Get(ParticleSystem.ShapeModule module)
        {
            ShapeModule temp = new ShapeModule();
            //temp.modelName = "ShapeModule";

            temp.enabled = module.enabled;
            temp.shapeType = module.shapeType;
            temp.randomDirectionAmount = module.randomDirectionAmount;
            temp.sphericalDirectionAmount = module.sphericalDirectionAmount;
            temp.randomPositionAmount = module.randomPositionAmount;
            temp.alignToDirection = module.alignToDirection;
            temp.radius = module.radius;
            temp.radiusMode = module.radiusMode;
            temp.radiusSpread = module.radiusSpread;
            temp.radiusSpeed = MinMaxCurve.Get(module.radiusSpeed);
            temp.radiusSpeedMultiplier = module.radiusSpeedMultiplier;
            temp.radiusThickness = module.radiusThickness;
            temp.angle = module.angle;
            temp.length = module.length;
            temp.boxThickness = module.boxThickness;
            temp.meshShapeType = module.meshShapeType;
            temp.mesh = module.mesh;
            temp.meshRenderer = module.meshRenderer;
            temp.skinnedMeshRenderer = module.skinnedMeshRenderer;
            temp.sprite = module.sprite;
            temp.spriteRenderer = module.spriteRenderer;
            temp.useMeshMaterialIndex = module.useMeshMaterialIndex;
            temp.meshMaterialIndex = module.meshMaterialIndex;
            temp.useMeshColors = module.useMeshColors;
            temp.normalOffset = module.normalOffset;
            temp.meshSpawnMode = module.meshSpawnMode;
            temp.meshSpawnSpread = module.meshSpawnSpread;
            temp.meshSpawnSpeed = MinMaxCurve.Get(module.meshSpawnSpeed);
            temp.meshSpawnSpeedMultiplier = module.meshSpawnSpeedMultiplier;
            temp.arc = module.arc;
            temp.arcMode = module.arcMode;
            temp.arcSpread = module.arcSpread;
            temp.arcSpeed = MinMaxCurve.Get(module.arcSpeed);
            temp.arcSpeedMultiplier = module.arcSpeedMultiplier;
            temp.donutRadius = module.donutRadius;
            temp.position = module.position;
            temp.rotation = module.rotation;
            temp.scale = module.scale;
            temp.texture = module.texture;
            temp.textureClipChannel = module.textureClipChannel;
            temp.textureClipThreshold = module.textureClipThreshold;
            temp.textureColorAffectsParticles = module.textureColorAffectsParticles;
            temp.textureAlphaAffectsParticles = module.textureAlphaAffectsParticles;
            temp.textureBilinearFiltering = module.textureBilinearFiltering;
            temp.textureUVChannel = module.textureUVChannel;

            return temp;
        }
    }


    [Serializable]
    public class EmissionModule : ParticleModel
    {
        public bool enabled;
        public MinMaxCurve rateOverTime;
        public float rateOverTimeMultiplier;
        public MinMaxCurve rateOverDistance;
        public float rateOverDistanceMultiplier;
        public int burstCount;

        public static EmissionModule Get(ParticleSystem.EmissionModule module)
        {
            EmissionModule temp = new EmissionModule();
            //temp.modelName = "EmissionModule";

            temp.enabled = module.enabled;
            temp.rateOverTime = MinMaxCurve.Get(module.rateOverTime);
            temp.rateOverTimeMultiplier = module.rateOverTimeMultiplier;
            temp.rateOverDistance = MinMaxCurve.Get(module.rateOverDistance);
            temp.rateOverDistanceMultiplier = module.rateOverDistanceMultiplier;
            temp.burstCount = module.burstCount;

            return temp;
        }
    }


    [Serializable]
    public class MainModule : ParticleModel
    {
        public float duration;
        public bool loop;
        public bool prewarm;
        public MinMaxCurve startDelay;
        public float startDelayMultiplier;
        public MinMaxCurve startLifetime;
        public float startLifetimeMultiplier;
        public MinMaxCurve startSpeed;
        public float startSpeedMultiplier;
        public bool startSize3D;
        public MinMaxCurve startSize;
        public float startSizeMultiplier;
        public MinMaxCurve startSizeX;
        public float startSizeXMultiplier;
        public MinMaxCurve startSizeY;
        public float startSizeYMultiplier;
        public MinMaxCurve startSizeZ;
        public float startSizeZMultiplier;
        public bool startRotation3D;
        public MinMaxCurve startRotation;
        public float startRotationMultiplier;
        public MinMaxCurve startRotationX;
        public float startRotationXMultiplier;
        public MinMaxCurve startRotationY;
        public float startRotationYMultiplier;
        public MinMaxCurve startRotationZ;
        public float startRotationZMultiplier;
        public float flipRotation;
        public MinMaxGradient startColor;
        public MinMaxCurve gravityModifier;
        public float gravityModifierMultiplier;
        public UnityEngine.ParticleSystemSimulationSpace simulationSpace;
        public UnityEngine.Transform customSimulationSpace;
        public float simulationSpeed;
        public bool useUnscaledTime;
        public UnityEngine.ParticleSystemScalingMode scalingMode;
        public bool playOnAwake;
        public int maxParticles;
        public UnityEngine.ParticleSystemEmitterVelocityMode emitterVelocityMode;
        public UnityEngine.ParticleSystemStopAction stopAction;
        public UnityEngine.ParticleSystemCullingMode cullingMode;
        public UnityEngine.ParticleSystemRingBufferMode ringBufferMode;
        public UnityEngine.Vector2 ringBufferLoopRange;

        public static MainModule Get(ParticleSystem.MainModule module)
        {
            MainModule temp = new MainModule();
            //temp.modelName = "MainModule";

            temp.duration = module.duration;
            temp.loop = module.loop;
            temp.prewarm = module.prewarm;
            temp.startDelay = MinMaxCurve.Get(module.startDelay);
            temp.startDelayMultiplier = module.startDelayMultiplier;
            temp.startLifetime = MinMaxCurve.Get(module.startLifetime);
            temp.startLifetimeMultiplier = module.startLifetimeMultiplier;
            temp.startSpeed = MinMaxCurve.Get(module.startSpeed);
            temp.startSpeedMultiplier = module.startSpeedMultiplier;
            temp.startSize3D = module.startSize3D;
            temp.startSize = MinMaxCurve.Get(module.startSize);
            temp.startSizeMultiplier = module.startSizeMultiplier;
            temp.startSizeX = MinMaxCurve.Get(module.startSizeX);
            temp.startSizeXMultiplier = module.startSizeXMultiplier;
            temp.startSizeY = MinMaxCurve.Get(module.startSizeY);
            temp.startSizeYMultiplier = module.startSizeYMultiplier;
            temp.startSizeZ = MinMaxCurve.Get(module.startSizeZ);
            temp.startSizeZMultiplier = module.startSizeZMultiplier;
            temp.startRotation3D = module.startRotation3D;
            temp.startRotation = MinMaxCurve.Get(module.startRotation);
            temp.startRotationMultiplier = module.startRotationMultiplier;
            temp.startRotationX = MinMaxCurve.Get(module.startRotationX);
            temp.startRotationXMultiplier = module.startRotationXMultiplier;
            temp.startRotationY = MinMaxCurve.Get(module.startRotationY);
            temp.startRotationYMultiplier = module.startRotationYMultiplier;
            temp.startRotationZ = MinMaxCurve.Get(module.startRotationZ);
            temp.startRotationZMultiplier = module.startRotationZMultiplier;
            temp.flipRotation = module.flipRotation;
            temp.startColor = MinMaxGradient.Get(module.startColor);
            temp.gravityModifier = MinMaxCurve.Get(module.gravityModifier);
            temp.gravityModifierMultiplier = module.gravityModifierMultiplier;
            temp.simulationSpace = module.simulationSpace;
            temp.customSimulationSpace = module.customSimulationSpace;
            temp.simulationSpeed = module.simulationSpeed;
            temp.useUnscaledTime = module.useUnscaledTime;
            temp.scalingMode = module.scalingMode;
            temp.playOnAwake = module.playOnAwake;
            temp.maxParticles = module.maxParticles;
            temp.emitterVelocityMode = module.emitterVelocityMode;
            temp.stopAction = module.stopAction;
            temp.cullingMode = module.cullingMode;
            temp.ringBufferMode = module.ringBufferMode;
            temp.ringBufferLoopRange = module.ringBufferLoopRange;

            return temp;
        }
    }


    [Serializable]
    public class MinMaxGradient : ParticleModel
    {
        public UnityEngine.ParticleSystemGradientMode mode;
        public UnityEngine.Gradient gradientMax;
        public UnityEngine.Gradient gradientMin;
        public Color colorMax;
        public Color colorMin;
        public Color color;
        public UnityEngine.Gradient gradient;

        public static MinMaxGradient Get(ParticleSystem.MinMaxGradient module)
        {
            MinMaxGradient temp = new MinMaxGradient();
            //temp.modelName = "MinMaxGradient";

            temp.mode = module.mode;
            temp.gradientMax = module.gradientMax;
            temp.gradientMin = module.gradientMin;
            temp.colorMax = module.colorMax;
            temp.colorMin = module.colorMin;
            temp.color = module.color;
            temp.gradient = module.gradient;

            return temp;
        }
    }


    [Serializable]
    public class MinMaxCurve : ParticleModel
    {
        public UnityEngine.ParticleSystemCurveMode mode;
        public float curveMultiplier;
        public UnityEngine.AnimationCurve curveMax;
        public UnityEngine.AnimationCurve curveMin;
        public float constantMax;
        public float constantMin;
        public float constant;
        public UnityEngine.AnimationCurve curve;

        public static MinMaxCurve Get(ParticleSystem.MinMaxCurve module)
        {
            MinMaxCurve temp = new MinMaxCurve();
            //temp.modelName = "MinMaxCurve";

            temp.mode = module.mode;
            temp.curveMultiplier = module.curveMultiplier;
            temp.curveMax = module.curveMax;
            temp.curveMin = module.curveMin;
            temp.constantMax = module.constantMax;
            temp.constantMin = module.constantMin;
            temp.constant = module.constant;
            temp.curve = module.curve;

            return temp;
        }
    }

    public void ChangeParticleSubData(ParticleSystem.SubEmittersModule data)
    {
        if (data.enabled == false)
            return;

        SubEmittersModule module = SubEmittersModule.Get(data);
        particleModelSo.subemittersmodule = new SubEmittersModule[1];
        particleModelSo.subemittersmodule[0] = module;
        return;
    }
    public void ChangeParticleData(Type type, object data)
    {
        if (type == typeof(ParticleSystem.TrailModule))
        {
            if (((ParticleSystem.TrailModule)data).enabled == false)
                return;
            TrailModule module = TrailModule.Get((ParticleSystem.TrailModule)data);
            particleModelSo.trailmodule = new TrailModule[1];
            particleModelSo.trailmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.LightsModule))
        {
            if (((ParticleSystem.LightsModule)data).enabled == false)
                return;
            LightsModule module = LightsModule.Get((ParticleSystem.LightsModule)data);
            particleModelSo.lightsmodule = new LightsModule[1];
            particleModelSo.lightsmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.TextureSheetAnimationModule))
        {
            if (((ParticleSystem.TextureSheetAnimationModule)data).enabled == false)
                return;
            TextureSheetAnimationModule module = TextureSheetAnimationModule.Get((ParticleSystem.TextureSheetAnimationModule)data);
            particleModelSo.texturesheetanimationmodule = new TextureSheetAnimationModule[1];
            particleModelSo.texturesheetanimationmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.SubEmittersModule))
        {
            if (((ParticleSystem.SubEmittersModule)data).enabled == false)
                return;
            SubEmittersModule module = SubEmittersModule.Get((ParticleSystem.SubEmittersModule)data);
            particleModelSo.subemittersmodule = new SubEmittersModule[1];
            particleModelSo.subemittersmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.NoiseModule))
        {
            if (((ParticleSystem.NoiseModule)data).enabled == false)
                return;
            NoiseModule module = NoiseModule.Get((ParticleSystem.NoiseModule)data);
            particleModelSo.noisemodule = new NoiseModule[1];
            particleModelSo.noisemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.ExternalForcesModule))
        {
            if (((ParticleSystem.ExternalForcesModule)data).enabled == false)
                return;
            ExternalForcesModule module = ExternalForcesModule.Get((ParticleSystem.ExternalForcesModule)data);
            particleModelSo.externalforcesmodule = new ExternalForcesModule[1];
            particleModelSo.externalforcesmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.RotationBySpeedModule))
        {
            if (((ParticleSystem.RotationBySpeedModule)data).enabled == false)
                return;
            RotationBySpeedModule module = RotationBySpeedModule.Get((ParticleSystem.RotationBySpeedModule)data);
            particleModelSo.rotationbyspeedmodule = new RotationBySpeedModule[1];
            particleModelSo.rotationbyspeedmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.RotationOverLifetimeModule))
        {
            if (((ParticleSystem.RotationOverLifetimeModule)data).enabled == false)
                return;
            RotationOverLifetimeModule module = RotationOverLifetimeModule.Get((ParticleSystem.RotationOverLifetimeModule)data);
            particleModelSo.rotationoverlifetimemodule = new RotationOverLifetimeModule[1];
            particleModelSo.rotationoverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.SizeBySpeedModule))
        {
            if (((ParticleSystem.SizeBySpeedModule)data).enabled == false)
                return;
            SizeBySpeedModule module = SizeBySpeedModule.Get((ParticleSystem.SizeBySpeedModule)data);
            particleModelSo.sizebyspeedmodule = new SizeBySpeedModule[1];
            particleModelSo.sizebyspeedmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.SizeOverLifetimeModule))
        {
            if (((ParticleSystem.SizeOverLifetimeModule)data).enabled == false)
                return;
            SizeOverLifetimeModule module = SizeOverLifetimeModule.Get((ParticleSystem.SizeOverLifetimeModule)data);
            particleModelSo.sizeoverlifetimemodule = new SizeOverLifetimeModule[1];
            particleModelSo.sizeoverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.ColorBySpeedModule))
        {
            if (((ParticleSystem.ColorBySpeedModule)data).enabled == false)
                return;
            ColorBySpeedModule module = ColorBySpeedModule.Get((ParticleSystem.ColorBySpeedModule)data);
            particleModelSo.colorbyspeedmodule = new ColorBySpeedModule[1];
            particleModelSo.colorbyspeedmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.ColorOverLifetimeModule))
        {
            if (((ParticleSystem.ColorOverLifetimeModule)data).enabled == false)
                return;
            ColorOverLifetimeModule module = ColorOverLifetimeModule.Get((ParticleSystem.ColorOverLifetimeModule)data);
            particleModelSo.coloroverlifetimemodule = new ColorOverLifetimeModule[1];
            particleModelSo.coloroverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.ForceOverLifetimeModule))
        {
            if (((ParticleSystem.ForceOverLifetimeModule)data).enabled == false)
                return;
            ForceOverLifetimeModule module = ForceOverLifetimeModule.Get((ParticleSystem.ForceOverLifetimeModule)data);
            particleModelSo.forceoverlifetimemodule = new ForceOverLifetimeModule[1];
            particleModelSo.forceoverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.InheritVelocityModule))
        {
            if (((ParticleSystem.InheritVelocityModule)data).enabled == false)
                return;
            InheritVelocityModule module = InheritVelocityModule.Get((ParticleSystem.InheritVelocityModule)data);
            particleModelSo.inheritvelocitymodule = new InheritVelocityModule[1];
            particleModelSo.inheritvelocitymodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.LimitVelocityOverLifetimeModule))
        {
            if (((ParticleSystem.LimitVelocityOverLifetimeModule)data).enabled == false)
                return;
            LimitVelocityOverLifetimeModule module = LimitVelocityOverLifetimeModule.Get((ParticleSystem.LimitVelocityOverLifetimeModule)data);
            particleModelSo.limitvelocityoverlifetimemodule = new LimitVelocityOverLifetimeModule[1];
            particleModelSo.limitvelocityoverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.VelocityOverLifetimeModule))
        {
            if (((ParticleSystem.VelocityOverLifetimeModule)data).enabled == false)
                return;
            VelocityOverLifetimeModule module = VelocityOverLifetimeModule.Get((ParticleSystem.VelocityOverLifetimeModule)data);
            particleModelSo.velocityoverlifetimemodule = new VelocityOverLifetimeModule[1];
            particleModelSo.velocityoverlifetimemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.ShapeModule))
        {
            if (((ParticleSystem.ShapeModule)data).enabled == false)
                return;
            ShapeModule module = ShapeModule.Get((ParticleSystem.ShapeModule)data);
            particleModelSo.shapemodule = new ShapeModule[1];
            particleModelSo.shapemodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.EmissionModule))
        {
            if (((ParticleSystem.EmissionModule)data).enabled == false)
                return;
            EmissionModule module = EmissionModule.Get((ParticleSystem.EmissionModule)data);
            particleModelSo.emissionmodule = new EmissionModule[1];
            particleModelSo.emissionmodule[0] = module;
            return;
        }
        if (type == typeof(ParticleSystem.MainModule))
        {
            MainModule module = MainModule.Get((ParticleSystem.MainModule)data);
            particleModelSo.mainmodule = new MainModule[1];
            particleModelSo.mainmodule[0] = module;
            return;
        }
    }


    public void SetParticleData(ParticleSystem particle)
    {
        if (particleModelSo.mainmodule.Length > 0)
        {
            particle.main.SetData(particleModelSo.mainmodule[0]);
        }
        if (particleModelSo.emissionmodule.Length > 0)
        {
            particle.emission.SetData(particleModelSo.emissionmodule[0]);
        }
        else
        {
            ParticleSystem.EmissionModule model = particle.emission;
            model.enabled = false;
        }
        if (particleModelSo.shapemodule.Length > 0)
        {
            particle.shape.SetData(particleModelSo.shapemodule[0]);
        }
        else
        {
            ParticleSystem.ShapeModule model = particle.shape;
            model.enabled = false;
        }
        if (particleModelSo.velocityoverlifetimemodule.Length > 0)
        {
            particle.velocityOverLifetime.SetData(particleModelSo.velocityoverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.VelocityOverLifetimeModule model = particle.velocityOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.limitvelocityoverlifetimemodule.Length > 0)
        {
            particle.limitVelocityOverLifetime.SetData(particleModelSo.limitvelocityoverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.LimitVelocityOverLifetimeModule model = particle.limitVelocityOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.inheritvelocitymodule.Length > 0)
        {
            particle.inheritVelocity.SetData(particleModelSo.inheritvelocitymodule[0]);
        }
        else
        {
            ParticleSystem.InheritVelocityModule model = particle.inheritVelocity;
            model.enabled = false;
        }
        if (particleModelSo.forceoverlifetimemodule.Length > 0)
        {
            particle.forceOverLifetime.SetData(particleModelSo.forceoverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.ForceOverLifetimeModule model = particle.forceOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.coloroverlifetimemodule.Length > 0)
        {
            particle.colorOverLifetime.SetData(particleModelSo.coloroverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.ColorOverLifetimeModule model = particle.colorOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.colorbyspeedmodule.Length > 0)
        {
            particle.colorBySpeed.SetData(particleModelSo.colorbyspeedmodule[0]);
        }
        else
        {
            ParticleSystem.ColorBySpeedModule model = particle.colorBySpeed;
            model.enabled = false;
        }
        if (particleModelSo.sizeoverlifetimemodule.Length > 0)
        {
            particle.sizeOverLifetime.SetData(particleModelSo.sizeoverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.SizeOverLifetimeModule model = particle.sizeOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.sizebyspeedmodule.Length > 0)
        {
            particle.sizeBySpeed.SetData(particleModelSo.sizebyspeedmodule[0]);
        }
        else
        {
            ParticleSystem.SizeBySpeedModule model = particle.sizeBySpeed;
            model.enabled = false;
        }
        if (particleModelSo.rotationoverlifetimemodule.Length > 0)
        {
            particle.rotationOverLifetime.SetData(particleModelSo.rotationoverlifetimemodule[0]);
        }
        else
        {
            ParticleSystem.RotationOverLifetimeModule model = particle.rotationOverLifetime;
            model.enabled = false;
        }
        if (particleModelSo.rotationbyspeedmodule.Length > 0)
        {
            particle.rotationBySpeed.SetData(particleModelSo.rotationbyspeedmodule[0]);
        }
        else
        {
            ParticleSystem.RotationBySpeedModule model = particle.rotationBySpeed;
            model.enabled = false;
        }
        if (particleModelSo.externalforcesmodule.Length > 0)
        {
            particle.externalForces.SetData(particleModelSo.externalforcesmodule[0]);
        }
        else
        {
            ParticleSystem.ExternalForcesModule model = particle.externalForces;
            model.enabled = false;
        }
        if (particleModelSo.noisemodule.Length > 0)
        {
            particle.noise.SetData(particleModelSo.noisemodule[0]);
        }
        else
        {
            ParticleSystem.NoiseModule model = particle.noise;
            model.enabled = false;
        }
        if (particleModelSo.subemittersmodule.Length > 0)
        {
            //particle.subEmitters.SetData(particleModelSo.subemittersmodule[0]);
        }
        else
        {
            ParticleSystem.SubEmittersModule model = particle.subEmitters;
            model.enabled = false;
        }
        if (particleModelSo.texturesheetanimationmodule.Length > 0)
        {
            particle.textureSheetAnimation.SetData(particleModelSo.texturesheetanimationmodule[0]);
        }
        else
        {
            ParticleSystem.TextureSheetAnimationModule model = particle.textureSheetAnimation;
            model.enabled = false;
        }
        if (particleModelSo.lightsmodule.Length > 0)
        {
            particle.lights.SetData(particleModelSo.lightsmodule[0]);
        }
        else
        {
            ParticleSystem.LightsModule model = particle.lights;
            model.enabled = false;
        }
        if (particleModelSo.trailmodule.Length > 0)
        {
            particle.trails.SetData(particleModelSo.trailmodule[0]);
        }
        else
        {
            ParticleSystem.TrailModule model = particle.trails;
            model.enabled = false;
        }
    }

    protected void InitModelData()
    {
        if (modelDataCollection != null)
        {
            var data = modelDataCollection.Get(modelDataGUID);
            SetModelData(data);
        }
    }
    public void SetModelData(ParticleModelObjectData modelData)
    {
        particleModelSo = modelData;
    }
}