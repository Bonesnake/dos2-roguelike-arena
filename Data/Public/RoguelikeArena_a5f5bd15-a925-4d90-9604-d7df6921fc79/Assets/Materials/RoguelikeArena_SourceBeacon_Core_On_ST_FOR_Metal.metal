//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	float3 Position SV_POSITION0;
	float4 LocalQTangent NORMAL0;
	float2 TexCoords0 TEXCOORD0;
} VertexInput;

typedef struct
{
	float4 ProjectedPosition [[position]];
	float4 WorldPosition;
	float3 WorldNormal;
	float3 ObjectWorldPosition;
	float2 TexCoords0;
	float3 WorldBinormal;
	float3 WorldTangent;
	float3 WorldView;
	float HeightFog;
	float DistanceFog;
	float3 LocalNormal;
	float DepthNormalized;
} VertexOutput;

struct LocalUniformsVS
{
	float4x4 WorldMatrix;
};

vertex VertexOutput Materials_RoguelikeArena_SourceBeacon_Core_On_ST_FOR_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	constant PerFrame& perFrame [[buffer(7)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	//World space position
	float4 worldPosition = (uniforms.WorldMatrix * float4(In.Position, 1.0f));

	//Projected position
	float4 projectedPosition = (perView.global_ViewProjection * worldPosition);

	//Pass projected position to pixel shader
	Out.ProjectedPosition = projectedPosition;

	//Pass world position to pixel shader
	Out.WorldPosition = worldPosition;

	//Compute local tangent frame
	float3x3 LocalTangentFrame = GetTangentFrame(In.LocalQTangent);

	float3 LocalNormal = LocalTangentFrame[2];

	//Normalize Local Normal
	float3 localNormalNormalized = normalize(LocalNormal);

	//World space Normal
	float3 worldNormal = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localNormalNormalized);

	//Normalize World Normal
	float3 worldNormalNormalized = normalize(worldNormal);

	Out.WorldNormal = worldNormalNormalized;

	//Object World Position
	float3 objectWorldPosition = float3(uniforms.WorldMatrix[3].x, uniforms.WorldMatrix[3].y, uniforms.WorldMatrix[3].z);

	//Pass object world position to pixel shader
	Out.ObjectWorldPosition = objectWorldPosition;

	Out.TexCoords0 = In.TexCoords0;
	float3 LocalBinormal = LocalTangentFrame[1];

	//Normalize Local Binormal
	float3 localBinormalNormalized = normalize(LocalBinormal);

	//World space Binormal
	float3 worldBinormal = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localBinormalNormalized);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = (float3x3(uniforms.WorldMatrix[0].xyz, uniforms.WorldMatrix[1].xyz, uniforms.WorldMatrix[2].xyz) * localTangentNormalized);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;

	//World space view vector
	float3 worldView = (perView.global_ViewPos.xyz - worldPosition.xyz);

	Out.WorldView = worldView;

	//Calculate Height Fog
	float depthValue = saturate(((perFrame.global_FogPropertyMatrix[3].y - length(worldView)) / (perFrame.global_FogPropertyMatrix[3].y - perFrame.global_FogPropertyMatrix[3].x)));
	float heightDensity = ((worldPosition.y - perFrame.global_FogPropertyMatrix[2].z) / perFrame.global_FogPropertyMatrix[3].z);
	float heightFog = saturate(max(depthValue, heightDensity));

	Out.HeightFog = heightFog;

	//Calculate Distance Fog
	float distanceFog = saturate(((perFrame.global_FogPropertyMatrix[2].y - length(worldView)) / (perFrame.global_FogPropertyMatrix[2].y - perFrame.global_FogPropertyMatrix[2].x)));

	Out.DistanceFog = distanceFog;

	//Pass Local Normal to PS
	Out.LocalNormal = localNormalNormalized;

	//View space position
	float4 viewPosition = (perView.global_View * worldPosition);

	//Depth
	float depth = viewPosition.z;

	//Normalized Depth
	float depthNormalized = (depth / perView.global_ViewInfo.x);

	//Pass normalized depth to pixel shader
	Out.DepthNormalized = depthNormalized;


	return Out;
}


//[Fragment shader]


#include "Shaders/Metal/PBR.shdh"
#include "Shaders/Metal/Exposure.shdh"
#include "Shaders/Metal/ImageBasedLightingHelpers.shdh"

typedef struct
{
	float4 Color0 [[color(0)]];
} PixelOutput;

struct LocalUniformsPS
{
	float FloatParameter_GlowRadius;
	float3 Vector3Parameter_DistanceGlowColor;
	float FloatParameter_DistanceGlowStrength;
	float _OpacityFade;
	float3 Vector3Parameter_ShadowColor;
	float3 Vector3Parameter_BaseColor;
	float3 Vector3Parameter_HighlightColor;
	float FloatParameter_CrystalBrightness;
	float FloatParameter_GlowStrength;
	EXPOSURE_UNIFORMS
	IBL_UNIFORMS
};

static void CalculateMatOpacity(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	constant EoCGlobalConstantData& eocGlobal,
	float4 in_0,
	float3 in_1,
	float3 in_2,
	float3 in_3,
	float2 in_4,
	float3 in_5,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler)
{
	//Custom Material Lighting
	float Local0 = (1.0f / uniforms.FloatParameter_GlowRadius);
	float3 Local2 = (eocGlobal.global_PlayerPosition0.xyz - in_0.xyz);
	float Local3 = length(Local2);
	float Local1 = ((saturate((1.0f - (Local3 * Local0))) * abs(dot(in_1, (Local2 * (1.0f / (Local3 + 1E-23f)))))) * eocGlobal.global_PlayerPosition0.w);
	float3 Local5 = (eocGlobal.global_PlayerPosition1.xyz - in_0.xyz);
	float Local6 = length(Local5);
	float Local4 = ((saturate((1.0f - (Local6 * Local0))) * abs(dot(in_1, (Local5 * (1.0f / (Local6 + 1E-23f)))))) * eocGlobal.global_PlayerPosition1.w);
	float3 Local8 = (eocGlobal.global_PlayerPosition2.xyz - in_0.xyz);
	float Local9 = length(Local8);
	float Local7 = ((saturate((1.0f - (Local9 * Local0))) * abs(dot(in_1, (Local8 * (1.0f / (Local9 + 1E-23f)))))) * eocGlobal.global_PlayerPosition2.w);
	float3 Local11 = (eocGlobal.global_PlayerPosition3.xyz - in_0.xyz);
	float Local12 = length(Local11);
	float Local10 = ((saturate((1.0f - (Local12 * Local0))) * abs(dot(in_1, (Local11 * (1.0f / (Local12 + 1E-23f)))))) * eocGlobal.global_PlayerPosition3.w);
	float Local13 = max(max(max(Local1, Local4), Local7), Local10);
	float3 Local14 = (in_2 - in_3);
	float2 Local15 = Local14.xy;
	float2 Local16 = Local14.zy;
	float Local17 = in_1.z;
	float Local18 = abs(Local17);
	float Local19 = in_1.x;
	float Local20 = abs(Local19);
	float Local21 = step(Local18, Local20);
	float2 Local22 = mix(Local15, Local16, float2(Local21, Local21));
	float2 Local23 = Local14.xz;
	float Local24 = mix(Local18, Local20, Local21);
	float Local25 = in_1.y;
	float Local26 = abs(Local25);
	float Local27 = step(Local24, Local26);
	float2 Local28 = mix(Local22, Local23, float2(Local27, Local27));
	float2 Local29 = (2.0f * Local28);
	float Local30 = (perFrame.global_Data.x * 4.0f);
	float4 Local31 = Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler.sample(_DefaultWrapSampler, (Local28 + (float2(0.1f, 0.1f) * perFrame.global_Data.x)));
	//[Local31] Get needed components
	float3 Local32 = Local31.xyz;
	float3 Local33 = (Local32 * 2.0f);
	float Local34 = Local33.x;
	float2 Local35 = ((Local29 + (float2(0.0f, 0.175f) * Local30)) + Local34);
	float4 Local36 = Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler.sample(_DefaultWrapSampler, Local35);
	//[Local36] Get needed components
	float Local37 = Local36.x;
	float Local38 = Local33.z;
	float2 Local39 = ((Local29 + (float2(0.0f, -0.15f) * Local30)) + Local38);
	float4 Local40 = Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler.sample(_DefaultWrapSampler, Local39);
	//[Local40] Get needed components
	float Local41 = Local40.x;
	float Local42 = (Local37 + Local41);
	float Local43 = pow(Local42, 3.0f);
	float3 Local44 = (uniforms.Vector3Parameter_DistanceGlowColor * Local43);
	float3 Local45 = (Local13 * Local44);
	float3 Local46 = (Local45 * uniforms.FloatParameter_DistanceGlowStrength);
	float4 Local47 = Texture2DParameter_NM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_4);
	//[Local47] Convert normalmaps to tangent space vectors
	Local47.xyzw = Local47.wzyx;
	Local47.xyz = ((Local47.xyz * 2.0f) - 1.0f);
	Local47.z = -(Local47.z);
	Local47.xyz = normalize(Local47.xyz);
	//[Local47] Get needed components
	float3 Local48 = Local47.xyz;
	float Local49 = pow((1.0f - saturate(dot(Local48, in_5))), 1.0f);
	float3 Local50 = (Local46 + Local49);
	float3 Local51 = clamp(Local50, 0.75f, 1.0f);
	out_0 = Local51.x;
}

static void CalculateMatEmissiveColor(constant LocalUniformsPS& uniforms,
	float2 in_0,
	float3 in_1,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_BMA_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_BMA_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.y;
	float4 Local2 = Texture2DParameter_NM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local2] Convert normalmaps to tangent space vectors
	Local2.xyzw = Local2.wzyx;
	Local2.xyz = ((Local2.xyz * 2.0f) - 1.0f);
	Local2.z = -(Local2.z);
	Local2.xyz = normalize(Local2.xyz);
	//[Local2] Get needed components
	float3 Local3 = Local2.xyz;
	float Local4 = pow((1.0f - saturate(dot(Local3, in_1))), 2.0f);
	float Local5 = (Local1 + Local4);
	float Local6 = pow((1.0f - saturate(dot(Local3, in_1))), 0.15f);
	float Local7 = (1.0f - Local6);
	float Local8 = (Local5 + Local7);
	float Local9 = pow(Local8, 4.5f);
	//Color Gradient (Procedural)
	float Local10 = smoothstep(0.0f, 0.5f, Local9);
	float Local11 = smoothstep(0.5f, 1.0f, Local9);
	float3 Local12 = mix(mix(uniforms.Vector3Parameter_ShadowColor, uniforms.Vector3Parameter_BaseColor, float3(Local10, Local10, Local10)), uniforms.Vector3Parameter_HighlightColor, float3(Local11, Local11, Local11));
	float3 Local13 = (Local12 * uniforms.FloatParameter_CrystalBrightness);
	float3 Local14 = (uniforms.Vector3Parameter_DistanceGlowColor + uniforms.Vector3Parameter_DistanceGlowColor);
	float3 Local15 = (Local13 * Local14);
	float3 Local16 = (Local13 * Local15);
	float3 Local17 = (Local16 * uniforms.FloatParameter_GlowStrength);
	out_0 = Local17;
}

static void CalculateMatNormal(float2 in_0,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_NM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Convert normalmaps to tangent space vectors
	Local0.xyzw = Local0.wzyx;
	Local0.xyz = ((Local0.xyz * 2.0f) - 1.0f);
	Local0.z = -(Local0.z);
	Local0.xyz = normalize(Local0.xyz);
	//[Local0] Get needed components
	float3 Local1 = Local0.xyz;
	out_0 = Local1;
}

static void CalculateMatBaseColor(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	constant EoCGlobalConstantData& eocGlobal,
	float4 in_0,
	float3 in_1,
	float3 in_2,
	float3 in_3,
	float2 in_4,
	float3 in_5,
	thread float3& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_BMA_DefaultWrapSampler)
{
	//Custom Material Lighting
	float Local0 = (1.0f / uniforms.FloatParameter_GlowRadius);
	float3 Local2 = (eocGlobal.global_PlayerPosition0.xyz - in_0.xyz);
	float Local3 = length(Local2);
	float Local1 = ((saturate((1.0f - (Local3 * Local0))) * abs(dot(in_1, (Local2 * (1.0f / (Local3 + 1E-23f)))))) * eocGlobal.global_PlayerPosition0.w);
	float3 Local5 = (eocGlobal.global_PlayerPosition1.xyz - in_0.xyz);
	float Local6 = length(Local5);
	float Local4 = ((saturate((1.0f - (Local6 * Local0))) * abs(dot(in_1, (Local5 * (1.0f / (Local6 + 1E-23f)))))) * eocGlobal.global_PlayerPosition1.w);
	float3 Local8 = (eocGlobal.global_PlayerPosition2.xyz - in_0.xyz);
	float Local9 = length(Local8);
	float Local7 = ((saturate((1.0f - (Local9 * Local0))) * abs(dot(in_1, (Local8 * (1.0f / (Local9 + 1E-23f)))))) * eocGlobal.global_PlayerPosition2.w);
	float3 Local11 = (eocGlobal.global_PlayerPosition3.xyz - in_0.xyz);
	float Local12 = length(Local11);
	float Local10 = ((saturate((1.0f - (Local12 * Local0))) * abs(dot(in_1, (Local11 * (1.0f / (Local12 + 1E-23f)))))) * eocGlobal.global_PlayerPosition3.w);
	float Local13 = max(max(max(Local1, Local4), Local7), Local10);
	float3 Local14 = (in_2 - in_3);
	float2 Local15 = Local14.xy;
	float2 Local16 = Local14.zy;
	float Local17 = in_1.z;
	float Local18 = abs(Local17);
	float Local19 = in_1.x;
	float Local20 = abs(Local19);
	float Local21 = step(Local18, Local20);
	float2 Local22 = mix(Local15, Local16, float2(Local21, Local21));
	float2 Local23 = Local14.xz;
	float Local24 = mix(Local18, Local20, Local21);
	float Local25 = in_1.y;
	float Local26 = abs(Local25);
	float Local27 = step(Local24, Local26);
	float2 Local28 = mix(Local22, Local23, float2(Local27, Local27));
	float2 Local29 = (2.0f * Local28);
	float Local30 = (perFrame.global_Data.x * 4.0f);
	float4 Local31 = Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler.sample(_DefaultWrapSampler, (Local28 + (float2(0.1f, 0.1f) * perFrame.global_Data.x)));
	//[Local31] Get needed components
	float3 Local32 = Local31.xyz;
	float3 Local33 = (Local32 * 2.0f);
	float Local34 = Local33.x;
	float2 Local35 = ((Local29 + (float2(0.0f, 0.175f) * Local30)) + Local34);
	float4 Local36 = Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler.sample(_DefaultWrapSampler, Local35);
	//[Local36] Get needed components
	float Local37 = Local36.x;
	float Local38 = Local33.z;
	float2 Local39 = ((Local29 + (float2(0.0f, -0.15f) * Local30)) + Local38);
	float4 Local40 = Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler.sample(_DefaultWrapSampler, Local39);
	//[Local40] Get needed components
	float Local41 = Local40.x;
	float Local42 = (Local37 + Local41);
	float Local43 = pow(Local42, 3.0f);
	float3 Local44 = (uniforms.Vector3Parameter_DistanceGlowColor * Local43);
	float3 Local45 = (Local13 * Local44);
	float3 Local46 = (Local45 * uniforms.FloatParameter_DistanceGlowStrength);
	float4 Local47 = Texture2DParameter_BMA_DefaultWrapSampler.sample(_DefaultWrapSampler, in_4);
	//[Local47] Get needed components
	float Local48 = Local47.y;
	float4 Local49 = Texture2DParameter_NM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_4);
	//[Local49] Convert normalmaps to tangent space vectors
	Local49.xyzw = Local49.wzyx;
	Local49.xyz = ((Local49.xyz * 2.0f) - 1.0f);
	Local49.z = -(Local49.z);
	Local49.xyz = normalize(Local49.xyz);
	//[Local49] Get needed components
	float3 Local50 = Local49.xyz;
	float Local51 = pow((1.0f - saturate(dot(Local50, in_5))), 2.0f);
	float Local52 = (Local48 + Local51);
	float Local53 = pow((1.0f - saturate(dot(Local50, in_5))), 0.15f);
	float Local54 = (1.0f - Local53);
	float Local55 = (Local52 + Local54);
	float Local56 = pow(Local55, 4.5f);
	//Color Gradient (Procedural)
	float Local57 = smoothstep(0.0f, 0.5f, Local56);
	float Local58 = smoothstep(0.5f, 1.0f, Local56);
	float3 Local59 = mix(mix(uniforms.Vector3Parameter_ShadowColor, uniforms.Vector3Parameter_BaseColor, float3(Local57, Local57, Local57)), uniforms.Vector3Parameter_HighlightColor, float3(Local58, Local58, Local58));
	float3 Local60 = (Local59 * uniforms.FloatParameter_CrystalBrightness);
	float3 Local61 = (Local46 + Local60);
	out_0 = Local61;
}

static void CalculateMatMetalMask(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PM_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_PM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local1;
}

static void CalculateMatReflectance(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PM_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_PM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local1;
}

static void CalculateMatRoughness(float2 in_0,
	thread float& out_0,
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PM_DefaultWrapSampler)
{
	float4 Local0 = Texture2DParameter_PM_DefaultWrapSampler.sample(_DefaultWrapSampler, in_0);
	//[Local0] Get needed components
	float Local1 = Local0.x;
	float Local2 = Local0.y;
	out_0 = Local2;
}

static void CalculateMatRefraction(float3 in_0,
	thread float2& out_0)
{
	float3 Local0 = (float3(0.05f, 0.05f, 0.05f) * in_0);
	out_0 = Local0.xy;
}

fragment PixelOutput Materials_RoguelikeArena_SourceBeacon_Core_On_ST_FOR_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerView& perView,
	constant PerFrame& perFrame,
	constant EoCGlobalConstantData& eocGlobal,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_BMA_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_PM_DefaultWrapSampler,
	sampler _PointMirrorSampler,
	texture2d<float> _sceneDepth,
	texture2d<float> _scene,
	EXPOSURE_PARAMS,
	IBL_PARAMS)
{
	PixelOutput Out;

	float matOpacity;
	//Normalize World Normal
	float3 worldNormalNormalized = normalize(In.WorldNormal);

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(In.WorldBinormal);

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(In.WorldTangent);

	float3x3 NBT = float3x3(float3(worldTangentNormalized.x, worldNormalNormalized.x, worldBinormalNormalized.x), float3(worldTangentNormalized.y, worldNormalNormalized.y, worldBinormalNormalized.y), float3(worldTangentNormalized.z, worldNormalNormalized.z, worldBinormalNormalized.z));

	//Normalized world space view vector
	float3 worldViewNormalized = normalize(In.WorldView);

	//Calculate tangent space view vector
	float3 tangentView = (NBT * worldViewNormalized);

	CalculateMatOpacity(uniforms, perFrame, eocGlobal, In.WorldPosition, worldNormalNormalized, In.WorldPosition.xyz, In.ObjectWorldPosition, In.TexCoords0, tangentView, matOpacity, _DefaultWrapSampler, Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler, Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler, Texture2DParameter_NM_DefaultWrapSampler);
	matOpacity = (matOpacity * uniforms._OpacityFade);

	float3 matEmissiveColor;
	CalculateMatEmissiveColor(uniforms, In.TexCoords0, tangentView, matEmissiveColor, _DefaultWrapSampler, Texture2DParameter_NM_DefaultWrapSampler, Texture2DParameter_BMA_DefaultWrapSampler);
	float3 matNormal;
	CalculateMatNormal(In.TexCoords0, matNormal, _DefaultWrapSampler, Texture2DParameter_NM_DefaultWrapSampler);
	matNormal = normalize((matNormal * NBT));

	float3 matBaseColor;
	CalculateMatBaseColor(uniforms, perFrame, eocGlobal, In.WorldPosition, worldNormalNormalized, In.WorldPosition.xyz, In.ObjectWorldPosition, In.TexCoords0, tangentView, matBaseColor, _DefaultWrapSampler, Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler, Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler, Texture2DParameter_NM_DefaultWrapSampler, Texture2DParameter_BMA_DefaultWrapSampler);
	float matMetalMask;
	CalculateMatMetalMask(In.TexCoords0, matMetalMask, _DefaultWrapSampler, Texture2DParameter_PM_DefaultWrapSampler);
	float matReflectance;
	CalculateMatReflectance(In.TexCoords0, matReflectance, _DefaultWrapSampler, Texture2DParameter_PM_DefaultWrapSampler);
	matReflectance = RemapReflectance(matReflectance);
	float matRoughness;
	CalculateMatRoughness(In.TexCoords0, matRoughness, _DefaultWrapSampler, Texture2DParameter_PM_DefaultWrapSampler);
	matRoughness = max(0.09f, matRoughness);
	float3 FinalColor = float3(0.0f, 0.0f, 0.0f);

	//Calculate Image Based Lighting
	float3 iblDiffuse;
	float3 iblSpecular;
	EvaluateDistantIBL(matBaseColor, matRoughness, float3(matReflectance, matReflectance, matReflectance), matMetalMask, matNormal, worldViewNormalized, iblDiffuse, iblSpecular, IBL_PARAMS_CONSTRUCT);
	FinalColor = ((FinalColor + iblDiffuse) + iblSpecular);

	float3 LightDiffuseColorOut;
	float3 LightSpecularColorOut;
	DirectionLight(matNormal, worldViewNormalized, perFrame.global_LightPropertyMatrix, matBaseColor, matReflectance, matRoughness, matMetalMask, LightDiffuseColorOut, LightSpecularColorOut);
	FinalColor = ((FinalColor + LightDiffuseColorOut) + LightSpecularColorOut);

	FinalColor = PreExpose(FinalColor, Exposure);

	FinalColor = (FinalColor + (matEmissiveColor * !(bool)(perFrame.global_Data.y)));

	FinalColor = mix(perFrame.global_FogPropertyMatrix[1].xyz, FinalColor, float3(In.HeightFog, In.HeightFog, In.HeightFog));
	FinalColor = mix(perFrame.global_FogPropertyMatrix[0].xyz, FinalColor, float3(In.DistanceFog, In.DistanceFog, In.DistanceFog));

	float2 matRefraction;
	//Normalize Local Normal
	float3 localNormalNormalized = normalize(In.LocalNormal);

	CalculateMatRefraction(localNormalNormalized, matRefraction);
	//Y direction of svMatRefraction is negated because V component of UV is in other direction.
	matRefraction.y = -(matRefraction.y);
	//UV position
	float2 Local0 = (In.ProjectedPosition.xy / perView.global_ViewInfo.zw);

	float Local1 = _sceneDepth.sample(_PointMirrorSampler, (Local0 + matRefraction)).x;
	float2 Local2 = (Local0 + ((matRefraction * step(In.DepthNormalized, Local1)) * uniforms._OpacityFade));
	float4 Local3 = _scene.sample(_PointMirrorSampler, Local2);
	FinalColor = mix(Local3.xyz, FinalColor, float3(matOpacity, matOpacity, matOpacity));
	matOpacity = (matOpacity + ((1.0f - matOpacity) * Local3.w));

	Out.Color0 = float4(FinalColor, matOpacity);
	Out.Color0 = max(Out.Color0, 0.0f);

	return Out;
}
