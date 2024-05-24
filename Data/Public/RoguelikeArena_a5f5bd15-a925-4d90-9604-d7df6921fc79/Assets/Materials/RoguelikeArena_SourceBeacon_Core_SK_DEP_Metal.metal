//[Vertex shader]


#define __HAVE_MATRIX_MULTIPLE_SCALAR_CONSTRUCTORS__
#include <metal_stdlib>

using namespace metal;

#include "Shaders/Metal/CommonHelpers.shdh"
#include "Shaders/GlobalConstants_MTL.shdh"
#include "Shaders/GlobalConstants_PS_MTL.shdh"

typedef struct
{
	uint4 BoneIndices BLENDINDICES0;
	float4 BoneWeights BLENDWEIGHT0;
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
} VertexOutput;

struct LocalUniformsVS
{
	float3x4 BoneMatrices[128];
	float4x4 WorldMatrix;
};

vertex VertexOutput Materials_RoguelikeArena_SourceBeacon_Core_SK_DEP_Metal_vertexMain(constant LocalUniformsVS& uniforms [[buffer(5)]],
	constant PerView& perView [[buffer(6)]],
	VertexInput In [[stage_in]])
{
	VertexOutput Out;

	float4x3 boneMatrix1 = transpose(uniforms.BoneMatrices[In.BoneIndices.x]);
	float4x3 boneMatrix2 = transpose(uniforms.BoneMatrices[In.BoneIndices.y]);
	float4x3 boneMatrix3 = transpose(uniforms.BoneMatrices[In.BoneIndices.z]);
	float4x3 boneMatrix4 = transpose(uniforms.BoneMatrices[In.BoneIndices.w]);
	//World space position
	float4 worldPosition = float4(0.0f, 0.0f, 0.0f, 1.0f);
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.x * (boneMatrix1 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.y * (boneMatrix2 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.z * (boneMatrix3 * float4(In.Position, 1.0f))));
	worldPosition.xyz = (worldPosition.xyz + (In.BoneWeights.w * (boneMatrix4 * float4(In.Position, 1.0f))));
	worldPosition = (uniforms.WorldMatrix * worldPosition);

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
	float3 worldNormal = float3(0.0f, 0.0f, 0.0f);
	worldNormal = (worldNormal + (In.BoneWeights.x * (boneMatrix1 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.y * (boneMatrix2 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.z * (boneMatrix3 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (worldNormal + (In.BoneWeights.w * (boneMatrix4 * float4(localNormalNormalized, 0.0f))));
	worldNormal = (uniforms.WorldMatrix * float4(worldNormal, 0.0f)).xyz;

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
	float3 worldBinormal = float3(0.0f, 0.0f, 0.0f);
	worldBinormal = (worldBinormal + (In.BoneWeights.x * (boneMatrix1 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.y * (boneMatrix2 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.z * (boneMatrix3 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (worldBinormal + (In.BoneWeights.w * (boneMatrix4 * float4(localBinormalNormalized, 0.0f))));
	worldBinormal = (uniforms.WorldMatrix * float4(worldBinormal, 0.0f)).xyz;

	//Normalize World Binormal
	float3 worldBinormalNormalized = normalize(worldBinormal);

	Out.WorldBinormal = worldBinormalNormalized;

	float3 LocalTangent = LocalTangentFrame[0];

	//Normalize Local Tangent
	float3 localTangentNormalized = normalize(LocalTangent);

	//World space Tangent
	float3 worldTangent = float3(0.0f, 0.0f, 0.0f);
	worldTangent = (worldTangent + (In.BoneWeights.x * (boneMatrix1 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.y * (boneMatrix2 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.z * (boneMatrix3 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (worldTangent + (In.BoneWeights.w * (boneMatrix4 * float4(localTangentNormalized, 0.0f))));
	worldTangent = (uniforms.WorldMatrix * float4(worldTangent, 0.0f)).xyz;

	//Normalize World Tangent
	float3 worldTangentNormalized = normalize(worldTangent);

	Out.WorldTangent = worldTangentNormalized;

	//World space view vector
	float3 worldView = (perView.global_ViewPos.xyz - worldPosition.xyz);

	Out.WorldView = worldView;


	return Out;
}


//[Fragment shader]



typedef struct
{
} PixelOutput;

struct LocalUniformsPS
{
	float FloatParameter_GlowRadius;
	float3 Vector3Parameter_DistanceGlowColor;
	float FloatParameter_DistanceGlowStrength;
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

fragment PixelOutput Materials_RoguelikeArena_SourceBeacon_Core_SK_DEP_Metal_fragmentMain(constant LocalUniformsPS& uniforms,
	constant PerFrame& perFrame,
	constant EoCGlobalConstantData& eocGlobal,
	VertexOutput In [[stage_in]],
	sampler _DefaultWrapSampler,
	texture2d<float> Texture2DParameter_6cacb6396fe94aef83ac4f17e82f5b83_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_aa6a0d9586aa46d38f31ebadaffef4d1_DefaultWrapSampler,
	texture2d<float> Texture2DParameter_NM_DefaultWrapSampler)
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
	if ((matOpacity - 0.5f) < 0) discard_fragment();


	return Out;
}
