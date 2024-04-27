// generate by unity2018.4.2f0
// modify by alkaidfang.

using System;
using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

public static class GeneratePaiticleModuleUtils
{
    public static void SetData(this ParticleSystemRenderer module, ParticlePoolComponentBase.RenderModel data)
    {
        module.SetMeshes(data.mesh);
        module.material = data.material;
        module.trailMaterial = data.trailMaterial;
        module.sortingOrder = data.sortingOrder;
        module.sortingLayerID = data.sortingLayerID;
        module.maskInteraction = data.maskInteraction;
        module.flip = data.flip;
        module.pivot = data.pivot;
        module.maxParticleSize = data.maxParticleSize;
        module.minParticleSize = data.minParticleSize;
        module.sortingFudge = data.sortingFudge;
        module.shadowBias = data.shadowBias;
        module.normalDirection = data.normalDirection;
        module.cameraVelocityScale = data.cameraVelocityScale;
        module.velocityScale = data.velocityScale;
        module.lengthScale = data.lengthScale;
        module.sortMode = data.sortMode;
        module.renderMode = data.renderMode;
        module.alignment = data.alignment;
        module.alignment = data.alignment;
        module.enableGPUInstancing = data.enableGPUInstancing;
        module.allowRoll = data.allowRoll;

        module.enabled = true;
        //module.lightProbeUsage = LightProbeUsage.Off;
    }

    public static void SetData(this ParticleSystem.TrailModule module, ParticlePoolComponentBase.TrailModule data)
    {
        module.enabled = data.enabled;
        module.mode = data.mode;
        module.ratio = data.ratio;
        module.lifetime = NewMinMaxCurve(data.lifetime);
        module.lifetimeMultiplier = data.lifetimeMultiplier;
        module.minVertexDistance = data.minVertexDistance;
        module.textureMode = data.textureMode;
        module.worldSpace = data.worldSpace;
        module.dieWithParticles = data.dieWithParticles;
        module.sizeAffectsWidth = data.sizeAffectsWidth;
        module.sizeAffectsLifetime = data.sizeAffectsLifetime;
        module.inheritParticleColor = data.inheritParticleColor;
        module.colorOverLifetime = NewMinMaxGradient(data.colorOverLifetime);
        module.widthOverTrail = NewMinMaxCurve(data.widthOverTrail);
        module.widthOverTrailMultiplier = data.widthOverTrailMultiplier;
        module.colorOverTrail = NewMinMaxGradient(data.colorOverTrail);
        module.generateLightingData = data.generateLightingData;
        module.ribbonCount = data.ribbonCount;
        module.shadowBias = data.shadowBias;
        module.splitSubEmitterRibbons = data.splitSubEmitterRibbons;
        module.attachRibbonsToTransform = data.attachRibbonsToTransform;
    }

    public static void SetData(this ParticleSystem.LightsModule module, ParticlePoolComponentBase.LightsModule data)
    {
        module.enabled = data.enabled;
        module.ratio = data.ratio;
        module.useRandomDistribution = data.useRandomDistribution;
        module.light = data.light;
        module.useParticleColor = data.useParticleColor;
        module.sizeAffectsRange = data.sizeAffectsRange;
        module.alphaAffectsIntensity = data.alphaAffectsIntensity;
        module.range = NewMinMaxCurve(data.range);
        module.rangeMultiplier = data.rangeMultiplier;
        module.intensity = NewMinMaxCurve(data.intensity);
        module.intensityMultiplier = data.intensityMultiplier;
        module.maxLights = data.maxLights;
    }

    public static void SetData(this ParticleSystem.TextureSheetAnimationModule module, ParticlePoolComponentBase.TextureSheetAnimationModule data)
    {
        module.enabled = data.enabled;
        module.mode = data.mode;
        module.timeMode = data.timeMode;
        module.fps = data.fps;
        module.numTilesX = data.numTilesX;
        module.numTilesY = data.numTilesY;
        module.animation = data.animation;
#if UNITY_2021_1_OR_NEWER
        module.rowMode = data.rowMode;
#else
        module.useRandomRow = data.useRandomRow;
#endif
        module.frameOverTime = NewMinMaxCurve(data.frameOverTime);
        module.frameOverTimeMultiplier = data.frameOverTimeMultiplier;
        module.startFrame = NewMinMaxCurve(data.startFrame);
        module.startFrameMultiplier = data.startFrameMultiplier;
        module.cycleCount = data.cycleCount;
        module.rowIndex = data.rowIndex;
        module.uvChannelMask = data.uvChannelMask;
        module.speedRange = data.speedRange;
    }

    //public static void SetData(this ParticleSystem.SubEmittersModule module, ParticlePoolComponent.SubEmittersModule data)
    //{
    //    module.enabled = data.enabled;
    //    module.birth0 = data.birth0;
    //    module.birth1 = data.birth1;
    //    module.collision0 = data.collision0;
    //    module.collision1 = data.collision1;
    //    module.death0 = data.death0;
    //    module.death1 = data.death1;
    //}

    public static void SetData(this ParticleSystem.NoiseModule module, ParticlePoolComponentBase.NoiseModule data)
    {
        module.enabled = data.enabled;
        module.separateAxes = data.separateAxes;
        module.strength = NewMinMaxCurve(data.strength);
        module.strengthMultiplier = data.strengthMultiplier;
        module.strengthX = NewMinMaxCurve(data.strengthX);
        module.strengthXMultiplier = data.strengthXMultiplier;
        module.strengthY = NewMinMaxCurve(data.strengthY);
        module.strengthYMultiplier = data.strengthYMultiplier;
        module.strengthZ = NewMinMaxCurve(data.strengthZ);
        module.strengthZMultiplier = data.strengthZMultiplier;
        module.frequency = data.frequency;
        module.damping = data.damping;
        module.octaveCount = data.octaveCount;
        module.octaveMultiplier = data.octaveMultiplier;
        module.octaveScale = data.octaveScale;
        module.quality = data.quality;
        module.scrollSpeed = NewMinMaxCurve(data.scrollSpeed);
        module.scrollSpeedMultiplier = data.scrollSpeedMultiplier;
        module.remapEnabled = data.remapEnabled;
        module.remap = NewMinMaxCurve(data.remap);
        module.remapMultiplier = data.remapMultiplier;
        module.remapX = NewMinMaxCurve(data.remapX);
        module.remapXMultiplier = data.remapXMultiplier;
        module.remapY = NewMinMaxCurve(data.remapY);
        module.remapYMultiplier = data.remapYMultiplier;
        module.remapZ = NewMinMaxCurve(data.remapZ);
        module.remapZMultiplier = data.remapZMultiplier;
        module.positionAmount = NewMinMaxCurve(data.positionAmount);
        module.rotationAmount = NewMinMaxCurve(data.rotationAmount);
        module.sizeAmount = NewMinMaxCurve(data.sizeAmount);
    }

    public static void SetData(this ParticleSystem.ExternalForcesModule module, ParticlePoolComponentBase.ExternalForcesModule data)
    {
        module.enabled = data.enabled;
        module.multiplier = data.multiplier;
        module.influenceFilter = data.influenceFilter;
    }

    public static void SetData(this ParticleSystem.RotationBySpeedModule module, ParticlePoolComponentBase.RotationBySpeedModule data)
    {
        module.enabled = data.enabled;
        module.x = NewMinMaxCurve(data.x);
        module.xMultiplier = data.xMultiplier;
        module.y = NewMinMaxCurve(data.y);
        module.yMultiplier = data.yMultiplier;
        module.z = NewMinMaxCurve(data.z);
        module.zMultiplier = data.zMultiplier;
        module.separateAxes = data.separateAxes;
        module.range = data.range;
    }

    public static void SetData(this ParticleSystem.RotationOverLifetimeModule module, ParticlePoolComponentBase.RotationOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.x = NewMinMaxCurve(data.x);
        module.xMultiplier = data.xMultiplier;
        module.y = NewMinMaxCurve(data.y);
        module.yMultiplier = data.yMultiplier;
        module.z = NewMinMaxCurve(data.z);
        module.zMultiplier = data.zMultiplier;
        module.separateAxes = data.separateAxes;
    }

    public static void SetData(this ParticleSystem.SizeBySpeedModule module, ParticlePoolComponentBase.SizeBySpeedModule data)
    {
        module.enabled = data.enabled;
        module.size = NewMinMaxCurve(data.size);
        module.sizeMultiplier = data.sizeMultiplier;
        module.x = NewMinMaxCurve(data.x);
        module.xMultiplier = data.xMultiplier;
        module.y = NewMinMaxCurve(data.y);
        module.yMultiplier = data.yMultiplier;
        module.z = NewMinMaxCurve(data.z);
        module.zMultiplier = data.zMultiplier;
        module.separateAxes = data.separateAxes;
        module.range = data.range;
    }

    public static void SetData(this ParticleSystem.SizeOverLifetimeModule module, ParticlePoolComponentBase.SizeOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.size = NewMinMaxCurve(data.size);
        module.sizeMultiplier = data.sizeMultiplier;
        module.x = NewMinMaxCurve(data.x);
        module.xMultiplier = data.xMultiplier;
        module.y = NewMinMaxCurve(data.y);
        module.yMultiplier = data.yMultiplier;
        module.z = NewMinMaxCurve(data.z);
        module.zMultiplier = data.zMultiplier;
        module.separateAxes = data.separateAxes;
    }

    public static void SetData(this ParticleSystem.ColorBySpeedModule module, ParticlePoolComponentBase.ColorBySpeedModule data)
    {
        module.enabled = data.enabled;
        module.color = NewMinMaxGradient(data.color);
        module.range = data.range;
    }

    public static void SetData(this ParticleSystem.ColorOverLifetimeModule module, ParticlePoolComponentBase.ColorOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.color = NewMinMaxGradient(data.color);
    }

    public static void SetData(this ParticleSystem.ForceOverLifetimeModule module, ParticlePoolComponentBase.ForceOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.x = NewMinMaxCurve(data.x);
        module.y = NewMinMaxCurve(data.y);
        module.z = NewMinMaxCurve(data.z);
        module.xMultiplier = data.xMultiplier;
        module.yMultiplier = data.yMultiplier;
        module.zMultiplier = data.zMultiplier;
        module.space = data.space;
        module.randomized = data.randomized;
    }

    public static void SetData(this ParticleSystem.InheritVelocityModule module, ParticlePoolComponentBase.InheritVelocityModule data)
    {
        module.enabled = data.enabled;
        module.mode = data.mode;
        module.curve = NewMinMaxCurve(data.curve);
        module.curveMultiplier = data.curveMultiplier;
    }

    public static void SetData(this ParticleSystem.LimitVelocityOverLifetimeModule module, ParticlePoolComponentBase.LimitVelocityOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.limitX = NewMinMaxCurve(data.limitX);
        module.limitXMultiplier = data.limitXMultiplier;
        module.limitY = NewMinMaxCurve(data.limitY);
        module.limitYMultiplier = data.limitYMultiplier;
        module.limitZ = NewMinMaxCurve(data.limitZ);
        module.limitZMultiplier = data.limitZMultiplier;
        module.limit = NewMinMaxCurve(data.limit);
        module.limitMultiplier = data.limitMultiplier;
        module.dampen = data.dampen;
        module.separateAxes = data.separateAxes;
        module.space = data.space;
        module.drag = NewMinMaxCurve(data.drag);
        module.dragMultiplier = data.dragMultiplier;
        module.multiplyDragByParticleSize = data.multiplyDragByParticleSize;
        module.multiplyDragByParticleVelocity = data.multiplyDragByParticleVelocity;
    }

    public static void SetData(this ParticleSystem.VelocityOverLifetimeModule module, ParticlePoolComponentBase.VelocityOverLifetimeModule data)
    {
        module.enabled = data.enabled;
        module.x = NewMinMaxCurve(data.x);
        module.y = NewMinMaxCurve(data.y);
        module.z = NewMinMaxCurve(data.z);
        module.xMultiplier = data.xMultiplier;
        module.yMultiplier = data.yMultiplier;
        module.zMultiplier = data.zMultiplier;
        module.orbitalX = NewMinMaxCurve(data.orbitalX);
        module.orbitalY = NewMinMaxCurve(data.orbitalY);
        module.orbitalZ = NewMinMaxCurve(data.orbitalZ);
        module.orbitalXMultiplier = data.orbitalXMultiplier;
        module.orbitalYMultiplier = data.orbitalYMultiplier;
        module.orbitalZMultiplier = data.orbitalZMultiplier;
        module.orbitalOffsetX = NewMinMaxCurve(data.orbitalOffsetX);
        module.orbitalOffsetY = NewMinMaxCurve(data.orbitalOffsetY);
        module.orbitalOffsetZ = NewMinMaxCurve(data.orbitalOffsetZ);
        module.orbitalOffsetXMultiplier = data.orbitalOffsetXMultiplier;
        module.orbitalOffsetYMultiplier = data.orbitalOffsetYMultiplier;
        module.orbitalOffsetZMultiplier = data.orbitalOffsetZMultiplier;
        module.radial = NewMinMaxCurve(data.radial);
        module.radialMultiplier = data.radialMultiplier;
        module.speedModifier = NewMinMaxCurve(data.speedModifier);
        module.speedModifierMultiplier = data.speedModifierMultiplier;
        module.space = data.space;
    }

    public static void SetData(this ParticleSystem.ShapeModule module, ParticlePoolComponentBase.ShapeModule data)
    {
        //UnityEngine.Profiling.Profiler.BeginSample("ShapeModule set");
        module.enabled = data.enabled;
        module.shapeType = data.shapeType;
        module.randomDirectionAmount = data.randomDirectionAmount;
        module.sphericalDirectionAmount = data.sphericalDirectionAmount;
        module.randomPositionAmount = data.randomPositionAmount;
        module.alignToDirection = data.alignToDirection;
        module.radius = data.radius;
        module.radiusMode = data.radiusMode;
        module.radiusSpread = data.radiusSpread;
        module.radiusSpeed = NewMinMaxCurve(data.radiusSpeed);
        module.radiusSpeedMultiplier = data.radiusSpeedMultiplier;
        module.radiusThickness = data.radiusThickness;
        module.angle = data.angle;
        module.length = data.length;
        module.boxThickness = data.boxThickness;
        module.meshShapeType = data.meshShapeType;
        module.mesh = data.mesh;
        module.meshRenderer = data.meshRenderer;
        module.skinnedMeshRenderer = data.skinnedMeshRenderer;
        module.sprite = data.sprite;
        module.spriteRenderer = data.spriteRenderer;
        module.useMeshMaterialIndex = data.useMeshMaterialIndex;
        module.meshMaterialIndex = data.meshMaterialIndex;
        module.useMeshColors = data.useMeshColors;
        module.normalOffset = data.normalOffset;
        module.meshSpawnMode = data.meshSpawnMode;
        module.meshSpawnSpread = data.meshSpawnSpread;
        module.meshSpawnSpeed = NewMinMaxCurve(data.meshSpawnSpeed);
        module.meshSpawnSpeedMultiplier = data.meshSpawnSpeedMultiplier;
        module.arc = data.arc;
        module.arcMode = data.arcMode;
        module.arcSpread = data.arcSpread;
        module.arcSpeed = NewMinMaxCurve(data.arcSpeed);
        module.arcSpeedMultiplier = data.arcSpeedMultiplier;
        module.donutRadius = data.donutRadius;
        module.position = data.position;
        module.rotation = data.rotation;
        module.scale = data.scale;
        module.texture = data.texture;
        module.textureClipChannel = data.textureClipChannel;
        module.textureClipThreshold = data.textureClipThreshold;
        module.textureColorAffectsParticles = data.textureColorAffectsParticles;
        module.textureAlphaAffectsParticles = data.textureAlphaAffectsParticles;
        module.textureBilinearFiltering = data.textureBilinearFiltering;
        module.textureUVChannel = data.textureUVChannel;
        //UnityEngine.Profiling.Profiler.EndSample();
    }

    public static void SetData(this ParticleSystem.EmissionModule module, ParticlePoolComponentBase.EmissionModule data)
    {
        module.enabled = data.enabled;
        module.rateOverTime = NewMinMaxCurve(data.rateOverTime);
        module.rateOverTimeMultiplier = data.rateOverTimeMultiplier;
        module.rateOverDistance = NewMinMaxCurve(data.rateOverDistance);
        module.rateOverDistanceMultiplier = data.rateOverDistanceMultiplier;
        module.burstCount = data.burstCount;
    }


    public static void SetData(this ParticleSystem.MainModule module, ParticlePoolComponentBase.MainModule data)
    {
        //UnityEngine.Profiling.Profiler.BeginSample("MainModule set");

        module.duration = data.duration;
        module.loop = data.loop;
        module.prewarm = data.prewarm;
        module.startDelay = NewMinMaxCurve(data.startDelay);
        module.startDelayMultiplier = data.startDelayMultiplier;
        module.startLifetime = NewMinMaxCurve(data.startLifetime);
        module.startLifetimeMultiplier = data.startLifetimeMultiplier;
        module.startSpeed = NewMinMaxCurve(data.startSpeed);
        module.startSpeedMultiplier = data.startSpeedMultiplier;
        module.startSize3D = data.startSize3D;
        module.startSize = NewMinMaxCurve(data.startSize);
        module.startSizeMultiplier = data.startSizeMultiplier;
        module.startSizeX = NewMinMaxCurve(data.startSizeX);
        module.startSizeXMultiplier = data.startSizeXMultiplier;
        module.startSizeY = NewMinMaxCurve(data.startSizeY);
        module.startSizeYMultiplier = data.startSizeYMultiplier;
        module.startSizeZ = NewMinMaxCurve(data.startSizeZ);
        module.startSizeZMultiplier = data.startSizeZMultiplier;
        module.startRotation3D = data.startRotation3D;
        module.startRotation = NewMinMaxCurve(data.startRotation);
        module.startRotationMultiplier = data.startRotationMultiplier;
        module.startRotationX = NewMinMaxCurve(data.startRotationX);
        module.startRotationXMultiplier = data.startRotationXMultiplier;
        module.startRotationY = NewMinMaxCurve(data.startRotationY);
        module.startRotationYMultiplier = data.startRotationYMultiplier;
        module.startRotationZ = NewMinMaxCurve(data.startRotationZ);
        module.startRotationZMultiplier = data.startRotationZMultiplier;
        module.flipRotation = data.flipRotation;
        module.startColor = NewMinMaxGradient(data.startColor);
        module.gravityModifier = NewMinMaxCurve(data.gravityModifier);
        module.gravityModifierMultiplier = data.gravityModifierMultiplier;
        module.simulationSpace = data.simulationSpace;
        module.customSimulationSpace = data.customSimulationSpace;
        module.simulationSpeed = data.simulationSpeed;
        module.useUnscaledTime = data.useUnscaledTime;
        module.scalingMode = data.scalingMode;
        module.playOnAwake = data.playOnAwake;
        module.maxParticles = data.maxParticles;
        module.emitterVelocityMode = data.emitterVelocityMode;
        module.stopAction = data.stopAction;
        module.cullingMode = data.cullingMode;
        module.ringBufferMode = data.ringBufferMode;
        module.ringBufferLoopRange = data.ringBufferLoopRange;

        //UnityEngine.Profiling.Profiler.EndSample();

    }

    /// <summary>
    /// 此方法请不要使用，类型为struct型时c#扩张方法失效
    /// </summary>
    /// <param name="module"></param>
    /// <param name="data"></param>
    public static void SetData(this ParticleSystem.MinMaxGradient module, ParticlePoolComponentBase.MinMaxGradient data)
    {
        //UnityEngine.Profiling.Profiler.BeginSample("MinMaxGradient set");

        //module.mode = data.mode;
        //module.gradientMax = data.gradientMax;
        //module.gradientMin = data.gradientMin;
        //module.colorMax = data.colorMax;
        //module.colorMin = data.colorMin;
        //module.color = data.color;
        //module.gradient = data.gradient;

        //UnityEngine.Profiling.Profiler.EndSample();
    }

    public static ParticleSystem.MinMaxGradient NewMinMaxGradient(ParticlePoolComponentBase.MinMaxGradient data)
    {
        switch(data.mode)
        {
                case ParticleSystemGradientMode.Color:
                        return new ParticleSystem.MinMaxGradient(data.color);
                case ParticleSystemGradientMode.Gradient:
                        return new ParticleSystem.MinMaxGradient(data.gradient);
                case ParticleSystemGradientMode.TwoColors:
                        return new ParticleSystem.MinMaxGradient(data.colorMin,data.colorMax);
                case ParticleSystemGradientMode.TwoGradients:
                        return new ParticleSystem.MinMaxGradient(data.gradientMin,data.gradientMax);
                default :
                        return new ParticleSystem.MinMaxGradient();
        }
    }

    public static ParticleSystem.MinMaxCurve NewMinMaxCurve(ParticlePoolComponentBase.MinMaxCurve data)
    {
        switch(data.mode)
        {
                case ParticleSystemCurveMode.Constant:
                        return new ParticleSystem.MinMaxCurve(data.constant);
                case ParticleSystemCurveMode.Curve:
                        return new ParticleSystem.MinMaxCurve(data.curveMultiplier ,data.curve);
                case ParticleSystemCurveMode.TwoConstants:
                        return new ParticleSystem.MinMaxCurve(data.constantMin,data.constantMax);
                case ParticleSystemCurveMode.TwoCurves:
                        return new ParticleSystem.MinMaxCurve(data.curveMultiplier ,data.curveMin,data.curveMax);
                default :
                        return new ParticleSystem.MinMaxCurve();
        }
    }

    public static void SetData(this ParticleSystem.MinMaxCurve module, ParticlePoolComponentBase.MinMaxCurve data)
    {
        //UnityEngine.Profiling.Profiler.BeginSample("MinMaxCurve set");

        //module.mode = data.mode;
        //module.curveMultiplier = data.curveMultiplier;
        //module.curveMax = data.curveMax;
        //module.curveMin = data.curveMin;
        //module.constantMax = data.constantMax;
        //module.constantMin = data.constantMin;
        //module.constant = data.constant;
        //module.curve = data.curve;

        //UnityEngine.Profiling.Profiler.EndSample();
    }


}