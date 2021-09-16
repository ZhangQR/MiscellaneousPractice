Shader "URPPractice/Flow/Water"
{
    Properties
    {
    	[Header(Base)][Space(10)]
        [SingleLineTexture] _MainTex("Albedo", 2D) = "white" {}
    	_AnimationParams("XY=Direction, Z=Speed", Vector) = (1,1,1,0)
    	
	    [Header(Waves)][Space(10)]
		// [Toggle(_WAVES)] _WavesOn("_WAVES", Float) = 0

		_WaveSpeed("Speed", Float) = 2
		_WaveHeight("Height", Range(0 , 10)) = 0.25
		_WaveNormalStr("Normal Strength", Range(0 , 6)) = 0.5
		_WaveDistance("Distance", Range(0 , 1)) = 0.8
		_WaveFadeDistance("Fade Distance", vector) = (150, 300, 0, 0)

		_WaveSteepness("Steepness", Range(0 , 5)) = 0.1
		_WaveCount("Count", Range(1 , 5)) = 1
		_WaveDirection("Direction", vector) = (1,1,1,1)
    	
		[Header(Normals)][Space(10)]
		[NoScaleOffset][Normal][SingleLineTexture]_BumpMap("Normals", 2D) = "bump" {}
		_NormalTiling("Tiling", Float) = 1
		_NormalStrength("Strength", Range(0 , 1)) = 0.5
		_NormalSpeed("Speed multiplier", Float) = 0.2
		//X: Start
		//Y: End
		//Z: Tiling multiplier
//		_DistanceNormalParams("Distance normals", vector) = (100, 300, 0.25, 0)
//		[NoScaleOffset][Normal][SingleLineTexture]_BumpMapLarge("Normals (Distance)", 2D) = "bump" {}
//
		_SparkleIntensity("Sparkle Intensity", Range(0 , 10)) = 00
		_SparkleSize("Sparkle Size", Range( 0 , 1)) = 0.280
    	
	    [Header(Sun Reflection)][Space(10)]
		_SunReflectionSize("Size", Range(0 , 1)) = 0.5
		_SunReflectionStrength("Strength", Float) = 10
		_SunReflectionDistortion("Distortion", Range( 0 , 1)) = 0.49
		_PointSpotLightReflectionExp("Point/spot light exponent", Range(0.01 , 128)) = 64
    	
	    [Header(World Reflection)][Space(10)]
		_ReflectionStrength("Strength", Range( 0 , 1)) = 0
		_ReflectionDistortion("Distortion", Range( 0 , 1)) = 0.05
		_ReflectionBlur("Blur", Range( 0 , 1)) = 0	
		_ReflectionFresnel("Curvature mask", Range( 0.01 , 20)) = 5	
		//_PlanarReflectionLeft("Planar Reflections", 2D) = "" {} //Instanced
		//_PlanarReflectionRight("Planar Reflections", 2D) = "" {} //Instanced
		//_PlanarReflectionsEnabled("Planar Enabled", float) = 0 //Instanced
		//_PlanarReflectionsParams("Planar angle mask", Range(0 , 2)) = 0
		//X: Angle mask
    	
        [Header(Color)][Space(10)]
        [HDR]_BaseColor("Deep", Color) = (0, 0.44, 0.62, 1)
		[HDR]_ShallowColor("Shallow", Color) = (0.1, 0.9, 0.89, 0.02)
		[HDR]_HorizonColor("Horizon", Color) = (0.84, 1, 1, 0.15)
		_HorizonDistance("Horizon Distance", Range(0.01 , 32)) = 8
		_DepthVertical("Vertical Depth", Range(0.01 , 8)) = 4
		_DepthHorizontal("Horizontal Depth", Range(0.01 , 8)) = 1
		//[Toggle(_DepthExp)]_DepthExp("Exponential Blend", Range(0 , 1)) = 1
		[MaterialEnum(True Off,0,True On,1)] _DepthExp("Exponential Blend", Float) = 1
		_WaveTint("Wave tint", Range( -0.1 , 0.1)) = 0
		_TranslucencyParams("Translucency", Vector) = (1,8,1,0)
		//X: Strength
		//Y: Exponent
		//Z: Curvature mask
	    _EdgeFade("Edge Fade", Float) = 0.1
//		_ShadowStrength("Shadow Strength", Range(0 , 1)) = 1
        
//        [Header(Wave)][Space(10)]
//        _WaveDirAB("Wave A(xy) B(zw)",Vector) = (1,1,1,1)
//    	_WaveDirCD("Wave C(xy) D(zw)",Vector) = (1,1,1,1)
//    	_ALSSWaveA("Amplitude(x),Length(y),Steepness(z),Speed(w)",Vector) = (1,20,0.25,1)
//    	_ALSSWaveB("Amplitude(x),Length(y),Steepness(z),Speed(w)",Vector) = (1,20,0.25,1)
//    	_ALSSWaveC("Amplitude(x),Length(y),Steepness(z),Speed(w)",Vector) = (1,20,0.25,1)
//    	_ALSSWaveD("Amplitude(x),Length(y),Steepness(z),Speed(w)",Vector) = (1,20,0.25,1)
//        _WaveCount("WaveCount",float) = 1
    	
		[Header(Intersection)][Space(10)]
//		[MaterialEnum(Camera Depth,0,Vertex Color (Red),1,Both combined,2)] _IntersectionSource("Intersection source", Float) = 0
//		[MaterialEnum(None,0,Sharp,1,Smooth,2)] _IntersectionStyle("Intersection style", Float) = 1
		[NoScaleOffset][SingleLineTexture]_IntersectionNoise("Intersection noise", 2D) = "white" {}
		_IntersectionColor("Color", Color) = (1,1,1,1)
		_IntersectionLength("Distance", Range(0.01 , 5)) = 2
//		_IntersectionClipping("Cutoff", Range(0.01, 1)) = 0.5
		_IntersectionFalloff("Falloff", Range(0.01 , 1)) = 0.5
		_IntersectionTiling("Noise Tiling", float) = 0.2
		_IntersectionSpeed("Speed multiplier", float) = 0.1
//		_IntersectionRippleDist("Ripple distance", float) = 32
//		_IntersectionRippleStrength("Ripple Strength", Range(0 , 1)) = 0.5
        
    	
    	[Header(Foam)][Space(10)]
		[NoScaleOffset][SingleLineTexture]_FoamTex("Foam Mask", 2D) = "black" {}
		_FoamColor("Color", Color) = (1,1,1,1)
		_FoamSize("Cutoff", Range(0.01 , 0.999)) = 0.01
		_FoamSpeed("Speed multiplier", float) = 0.1
		_FoamWaveMask("Wave mask", Range(0 , 1)) = 0
		_FoamWaveMaskExp("Wave mask exponent", Range(1 , 8)) = 1
		_FoamTiling("Tiling", float) = 0.1
    	
    	
    	[Header(Caustics)][Space(10)]
    	_CausticsBrightness("Brightness", Float) = 2
	    _CausticsTiling("Tiling", Float) = 0.5
		_CausticsSpeed("Speed multiplier", Float) = 0.1
		_CausticsDistortion("Distortion", Range(0, 1)) = 0.15
		[NoScaleOffset][SingleLineTexture]_CausticsTex("Caustics Mask", 2D) = "black" {}
    	
    	
    	[Header(Unused)][Space(10)]
        _WaterFogColor ("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity ("Water Fog Density", Range(0, 2)) = 0.1
    	_Depth("Depth",float) = 20
    	_Environment("Environment",Cube) = ""{}
    }

    SubShader
    {
        Tags{"RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 300
        Pass
        {
            Name "Water"
            Tags{"LightMode" = "UniversalForward"}
            
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //#pragma enable_d3d11_debug_symbols

			#pragma vertex WaterVertex
            #pragma fragment WaterFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
				float4 color 		: COLOR0;
				float4 uv 			: TEXCOORD0;
            };

            struct Varyings
            {
                float4 uv                       : TEXCOORD0;
                // float3 positionWS               : TEXCOORD2;
                // float3 normalWS                 : TEXCOORD3;
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
                float3 viewDirWS                : TEXCOORD5;
                float4 positionCS               : SV_POSITION;
            	float4 screenPos				: TEXCOORD1;
            	half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 color 					: COLOR0;

            	//wPos.x in w-component
            	float4 normal 					: NORMAL;
				//wPos.y in w-component
				float4 tangent 					: TANGENT;
				//wPos.z in w-component
				float4 bitangent 				: TEXCOORD3;
            	float4 lightmapUVOrVertexSH : TEXCOORD6;
            };

            // TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            // TEXTURECUBE(_Environment);            SAMPLER(sampler_Environment);
            TEXTURE2D(_FoamTex);
			SAMPLER(sampler_FoamTex);
			// TEXTURE2D(_BumpMapLarge);
			// SAMPLER(sampler_BumpMapLarge);
			TEXTURE2D(_IntersectionNoise);	SAMPLER(sampler_IntersectionNoise);

			// half _IntersectionFalloff;
			// half _IntersectionTiling;

            CBUFFER_START(UnityPerMaterial)

            // **** Base ****
            // float4 _MainTex_ST;
            float4 _AnimationParams;

            // **** Normal ****
            float _NormalTiling;
			float _NormalSpeed;
			// half4 _DistanceNormalParams;
			half _NormalStrength;
			float _SparkleIntensity;
			half _SparkleSize;

			// **** Waves ****
			half _WaveHeight;
			half _WaveNormalStr;
			float _WaveDistance;
			half4 _WaveFadeDistance;
			float _WaveSteepness;
			uint _WaveCount;
			half4 _WaveDirection;
			float _WaveSpeed;
			half _WaveTint;

            // **** Color ****
			float4 _ShallowColor;
			float4 _BaseColor;
			//float4 _IntersectionColor;
			float _DepthVertical;
			float _DepthHorizontal;
			float _DepthExp;
			// float _WorldSpaceUV;
			// float _NormalTiling;
			// float _NormalSpeed;
			// half4 _DistanceNormalParams;
			// half _NormalStrength;
			half4 _TranslucencyParams;
			half _EdgeFade;
			float4 _HorizonColor;
			half _HorizonDistance;

			// **** Intersection ****
			float4 _IntersectionColor;
			// half _IntersectionSource;
			half _IntersectionLength;
			half _IntersectionFalloff;
			half _IntersectionTiling;
			// half _IntersectionRippleDist;
			// half _IntersectionRippleStrength;
			// half _IntersectionClipping;
			float _IntersectionSpeed;

			// **** Foam ****
			float _FoamTiling;
			float4 _FoamColor;
			float _FoamSpeed;
			half _FoamSize;
			half _FoamWaveMask;
			half _FoamWaveMaskExp;

            // **** Sun Reflection ****
			float _SunReflectionDistortion;
			float _SunReflectionSize;
			float _SunReflectionStrength;
			float _PointSpotLightReflectionExp;

            // **** Environment Reflection ****
            float _ReflectionDistortion;
			float _ReflectionBlur;
			float _ReflectionFresnel;
			float _ReflectionStrength;
			// half _PlanarReflectionsParams;
			// half _PlanarReflectionsEnabled;

            // **** Caustics **** 
			half _CausticsBrightness;
			float _CausticsTiling;
			half _CausticsSpeed;
			half _RefractionStrength;
			half _CausticsDistortion;

            // **** Unused ****
			float4 _WaterFogColor;
            float _WaterFogDensity,_Depth,_A;

            CBUFFER_END

            #include "Shared/Wave.hlsl"
            #include "Shared/Common.hlsl"
            #include "Shared/Features.hlsl"
            #include "Shared/Lighting.hlsl"
            #include "Shared/Caustics.hlsl"
            #include "Shared/Fog.hlsl"

            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            // Used in Standard (Physically Based) shader
            Varyings WaterVertex(Attributes input)
            {
				Varyings output = (Varyings)0;
				output.uv.xy = input.uv.xy;
				output.uv.z = _TimeParameters.x;
				output.uv.w = 0;
				
				float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS.xyz, input.tangentOS);
				
				//float4 vertexColor = GetVertexColor(input.color.rgba, _VertexColorMask.rgba);
            	float4 vertexColor = GetVertexColor(input.color.rgba,float4(0,0,0,0));
				
				//Returns mesh or world-space UV
				float2 uv = GetSourceUV(output.uv.xy, positionWS.xz,1);// _WorldSpaceUV);

				//Vertex animation
				// WaveInfo waves = GetWaveInfo(uv, TIME_VERTEX * _WaveSpeed,  _WaveFadeDistance.x, _WaveFadeDistance.y);
				WaveInfo waves = GetWaveInfo(uv, output.uv.z * _WaveSpeed,  _WaveFadeDistance.x, _WaveFadeDistance.y);
				//Offset in direction of normals (only when using mesh uv)
				// if(_WorldSpaceUV == 0) waves.position *= normalInput.normalWS.xyz;
				positionWS.xz += waves.position.xz * HORIZONTAL_DISPLACEMENT_SCALAR * _WaveHeight;
				positionWS.y += waves.position.y * _WaveHeight * lerp(1, 0, vertexColor.b);

				//SampleWaveSimulationVertex(positionWS, positionWS.y);

				output.positionCS = TransformWorldToHClip(positionWS);
				half fogFactor = CalculateFogFactor(output.positionCS.xyz);
				half3 vertexLight = 0;
            	output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
            	OUTPUT_SH(normalInput.normalWS.xyz, output.lightmapUVOrVertexSH.xyz);

				output.screenPos = ComputeScreenPos(output.positionCS);
				output.normal = float4(normalInput.normalWS, positionWS.x);
				output.tangent = float4(normalInput.tangentWS, positionWS.y);
				output.bitangent = float4(normalInput.bitangentWS, positionWS.z);

            	output.color = vertexColor;
				return output;
            }

            // Used in Standard (Physically Based) shader
            half4 WaterFragment(Varyings input,FRONT_FACE_TYPE vertexFace : FRONT_FACE_SEMANTIC_REAL) : SV_Target
            {
            	float4 vertexColor = input.color; //Mask already applied in vertex shader
				// return float4(vertexColor.aaa, 1);

				//Vertex normal in world-space
				float3 normalWS = normalize(input.normal.xyz);
				float3 WorldTangent = input.tangent.xyz;
				float3 WorldBiTangent = input.bitangent.xyz;
				float3 wPos = float3(input.normal.w, input.tangent.w, input.bitangent.w);
				//Not normalized for depth-pos reconstruction. Normalization required for lighting (otherwise breaks on mobile)
				float3 viewDir = (_WorldSpaceCameraPos - wPos);
				float3 viewDirNorm = SafeNormalize(viewDir);
				// return float4(viewDir, 1);
				
				half VdotN = 1.0 - saturate(dot(viewDirNorm, normalWS));

            	// **** Waves ****
				float2 uv = wPos.xz;
				WaveInfo waves = GetWaveInfo(uv, TIME * _WaveSpeed, _WaveFadeDistance.x, _WaveFadeDistance.y);
				//Flatten by blue vertex color weight
				waves.normal = lerp(waves.normal, normalWS, lerp(0, 1, vertexColor.b));
				//Blend wave/vertex normals in world-space
				float3 waveNormal = BlendNormalWorldspaceRNM(waves.normal, normalWS, UP_VECTOR);
				// return float4(waveNormal.xyz, 1);
				float height = waves.position.y * 0.5 + 0.5;
				height *= lerp(1, 0, vertexColor.b);
				// return float4(height, height, height, 1);

				//vertices are already displaced on XZ, in this case the world-space UV needs the same treatment
				uv.xy -= waves.position.xz * HORIZONTAL_DISPLACEMENT_SCALAR * _WaveHeight;
				// return float4(frac(uv.xy), 0, 1);

            	// ************** Color ***********************
            	SceneDepth depth = SampleDepth(input.screenPos);
				float3 opaqueWorldPos = ReconstructViewPos(input.screenPos, viewDir, depth);

				float normalSign = ceil(dot(viewDirNorm, normalWS));
				normalSign = normalSign == 0 ? -1 : 1;
            	float opaqueDist = DepthDistance(wPos,opaqueWorldPos,normalWS * normalSign);
            	//return half4(opaqueDist,opaqueDist,opaqueDist,1);

            	float surfaceDepth = SurfaceDepth(depth, input.positionCS);
            	float distanceAttenuation = 1.0 - exp(-surfaceDepth * _DepthVertical * lerp(0.1, 0.01, unity_OrthoParams.w));
            	// return float4(distanceAttenuation.xxx,1.0);
            	float heightAttenuation = saturate(lerp(opaqueDist * _DepthHorizontal, 1.0 - exp(-opaqueDist * _DepthHorizontal), _DepthExp));
				float waterDensity = max(distanceAttenuation, heightAttenuation);
            	// float vFace = IS_FRONT_VFACE(vertexFace, true, false);
				// waterDensity = lerp(1, waterDensity, vFace);
				// return float4(waterDensity.xxx, 1.0);

            	// **** intersection **** 
				float interSecGradient = 1-saturate(exp(opaqueDist) / _IntersectionLength);
				// return float4(interSecGradient.xxx,1.0);
				//float intersection = SampleIntersection(uv.xy, interSecGradient, TIME * _IntersectionSpeed);
            	float intersection = SampleIntersection(input.uv.xy, interSecGradient, TIME* _IntersectionSpeed);
				intersection *= _IntersectionColor.a;
            	// return float4(intersection.xxx,1.0);

            	// **** foam ****
				float foam = 0;
				float foamMask = lerp(1, saturate(height), _FoamWaveMask);
				foamMask = pow(abs(foamMask), _FoamWaveMaskExp);
            	// return float4(foamMask, foamMask, foamMask, 1);

            	float2 flowMap = float2(1, 1);
            	float slope = 0;
				foam = SampleFoam(uv * _FoamTiling, TIME, flowMap, _FoamSize, foamMask, slope);

				foam *= saturate(_FoamColor.a + vertexColor.a);
				// return float4(foam, foam, foam, 1);

            	
				// **** Albedo ****
				float3 finalColor = 0;
				float alpha = 1;
				float4 baseColor = lerp(_ShallowColor, _BaseColor, waterDensity);
            	
				baseColor.rgb += _WaveTint * height;
				
				finalColor.rgb = baseColor.rgb;
				alpha = baseColor.a;

				float3 NormalsCombined = float3(0.5, 0.5, 1);
				float3 worldTangentNormal = waveNormal;
				NormalsCombined = SampleNormals(uv * _NormalTiling, wPos, TIME, flowMap, _NormalSpeed, slope);
				//return float4((NormalsCombined.x * 0.5 + 0.5), (NormalsCombined.y * 0.5 + 0.5), 1, 1);

				worldTangentNormal = normalize(TransformTangentToWorld(NormalsCombined, half3x3(WorldTangent, WorldBiTangent, waveNormal)));

            	// Debug Normals
				// return float4(SRGBToLinear(float3(NormalsCombined.x * 0.5 + 0.5, NormalsCombined.y * 0.5 + 0.5, 1)), 1.0);
				float3 sparkles = 0;
            	Light mainLight = GetMainLight(/*ShadowCoords*/);
				float NdotL = saturate(dot(UP_VECTOR, worldTangentNormal));
				half sunAngle = saturate(dot(UP_VECTOR, mainLight.direction));
				half angleMask = saturate(sunAngle * 10); /* 1.0/0.10 = 10 */
				sparkles = saturate(step(_SparkleSize, (saturate(NormalsCombined.y) * NdotL))) * _SparkleIntensity * mainLight.color * angleMask;
				
				finalColor.rgb += sparkles.rgb;
            	// return float4(baseColor.rgb, alpha);
				//return float4(finalColor.rgb, alpha);

            	// **** sun reflection ****
				half4 sunSpec = 0;
				float3 sunReflectionNormals = worldTangentNormal;
				//Blinn-phong reflection
				sunSpec = SunSpecular(mainLight, viewDirNorm, sunReflectionNormals, _SunReflectionDistortion, _SunReflectionSize, _SunReflectionStrength);
				sunSpec.rgb *=  saturate((1-foam) * (1-intersection) /* *shadowMask*/); //Hide
				// return float4(sunSpec.rgb,1.0);

            	// **** environment reflection ****
				// Reflection probe
			 	float3 refWorldTangentNormal = lerp(waveNormal, normalize(waveNormal + worldTangentNormal), _ReflectionDistortion);
            	// return float4(refWorldTangentNormal,1.0);

            	float3 reflectionVector = reflect(-viewDirNorm , refWorldTangentNormal);
            	// return float4(reflectionVector,1.0);

            	float2 reflectionPerturbation = lerp(waveNormal.xz * 0.5, worldTangentNormal.xy, _ReflectionDistortion).xy;
            	// return float4(reflectionPerturbation.xy,1.0,1.0);

            	float4 ScreenPos = input.screenPos;
            	// return float4(ScreenPos);

            	float3 reflections = SampleReflections(reflectionVector, _ReflectionBlur, 0/*_PlanarReflectionsParams*/, 
			 		0/*_PlanarReflectionsEnabled*/, ScreenPos.xyzw, wPos, refWorldTangentNormal, viewDirNorm, reflectionPerturbation);
			 	//return float4(reflections,1.0);
			 	half reflectionFresnel = ReflectionFresnel(refWorldTangentNormal, viewDirNorm, _ReflectionFresnel);
			 	// return float4(reflectionFresnel.xxx, 1);
				finalColor.rgb = lerp(finalColor.rgb, reflections, _ReflectionStrength * reflectionFresnel);
				// return float4(finalColor.rgb, 1);

            	// **** Caustics ****
				float3 caustics = SampleCaustics(opaqueWorldPos.xz + lerp(waveNormal.xz, NormalsCombined.xz, _CausticsDistortion),
					TIME * _CausticsSpeed, _CausticsTiling) * _CausticsBrightness;
				// return float4(caustics, 1);

				float causticsMask = waterDensity;
				causticsMask = saturate(causticsMask + intersection/* + 1-vFace*/);
				finalColor = lerp(finalColor + caustics, finalColor, causticsMask);
            	// return float4(finalColor,1.0);

            	// **** translucency ****
            	float waveHeight = saturate(height);
				//Note value is subtracted
				float transmissionMask = saturate((foam * 0.25)/* + (1-shadowMask)*/); //Foam isn't 100% opaque
				//transmissionMask = 0;
				// return float4(transmissionMask, transmissionMask, transmissionMask, 1);
				TranslucencyData translucencyData = (TranslucencyData)0;
				translucencyData = PopulateTranslucencyData(_ShallowColor.rgb, mainLight.direction,
					mainLight.color, viewDirNorm, lerp(UP_VECTOR, waveNormal, 1/*vFace*/), worldTangentNormal,
					transmissionMask, _TranslucencyParams);

            	// **** ****
				//Foam application on top of everything up to this point
				finalColor.rgb = lerp(finalColor.rgb, _FoamColor.rgb, foam);
				finalColor.rgb = lerp(finalColor.rgb, _IntersectionColor.rgb, intersection);

            	//Full alpha on intersection and foam
				alpha = saturate(alpha + intersection + foam);

            	//At this point, normal strength should affect lighting
				half normalMask = saturate((intersection + foam));
				worldTangentNormal = lerp(waveNormal, worldTangentNormal, saturate(_NormalStrength - normalMask));
				
				// return float4(normalMask, normalMask, normalMask, 1);

				//Horizon color (note: not using normals, since they are perturbed by waves)
				float fresnel = saturate(pow(VdotN, _HorizonDistance));
				// #if UNDERWATER_ENABLED
				// fresnel *= vFace;
				// #endif
				finalColor.rgb = lerp(finalColor.rgb, _HorizonColor.rgb, fresnel * _HorizonColor.a);

				#if UNITY_COLORSPACE_GAMMA
				//Gamma-space is likely a choice, enabling this will have the water stand out from non gamma-corrected shaders
				//finalColor.rgb = LinearToSRGB(finalColor.rgb);
				#endif
				
				//Final alpha
				float edgeFade = saturate(opaqueDist / (_EdgeFade * 0.01));

				// #if UNDERWATER_ENABLED
				// edgeFade = lerp(1.0, edgeFade, vFace);
				// #endif

				//Prevent from peering through waves when camera is at the water level
				//Note: only filters pixels above water surface, below is practically impossible
				if(wPos.y <= opaqueWorldPos.y) edgeFade = 1;

				alpha *= edgeFade;

				//Not yet implemented, does nothing now
				SampleDiffuseProjectors(finalColor.rgb, wPos, ScreenPos);
            	// return float4(finalColor.rgb,1.0);

				SurfaceData surfaceData = (SurfaceData)0;

				float density = 1;
				// #if UNDERWATER_ENABLED
				// //Match color gradient and alpha to fog for backfaces
				// ApplyUnderwaterShading(finalColor.rgb, density, wPos, worldTangentNormal, viewDirNorm, _ShallowColor.rgb, _BaseColor.rgb, 1-vFace);
				// #endif
				//return float4(density.rrr, 1.0);

				alpha = lerp(density, alpha, 1/*vFace*/);
				
				surfaceData.albedo = finalColor.rgb;
				surfaceData.specular = sunSpec.rgb;
				//surfaceData.metallic = lerp(0.0, _Metallic, 1-(intersection+foam));
				surfaceData.metallic = 0;
				//surfaceData.smoothness = _Smoothness;
				surfaceData.smoothness = 0;
				surfaceData.normalTS = NormalsCombined;
				surfaceData.emission = 0;
				surfaceData.occlusion = 1;
				surfaceData.alpha = alpha;

				InputData inputData;
				inputData.positionWS = wPos;
				inputData.viewDirectionWS = viewDirNorm;
				float4 ShadowCoords = float4(0, 0, 0, 0);
				inputData.shadowCoord = ShadowCoords;
				//Flatten normals for underwater lighting (distracting, peers through the fog)
				// #if UNDERWATER_ENABLED
				// inputData.normalWS = lerp(float3(0,1,0), worldTangentNormal, vFace);
				// #else
				inputData.normalWS = worldTangentNormal;
				// #endif
				inputData.fogCoord = input.fogFactorAndVertexLight.x;
				inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
				inputData.bakedGI = SAMPLE_GI(input.lightmapUVOrVertexSH.xy, input.lightmapUVOrVertexSH.xyz, inputData.normalWS);

				float4 color = float4(ApplyLighting(surfaceData, inputData, translucencyData, density, 0.6/*_ShadowStrength*/, 1), alpha);
            	// return float4(color);

				float4 refractedScreenPos = ScreenPos.xyzw + (float4(worldTangentNormal.xz, 0, 0) * (_RefractionStrength * lerp(0.1, 0.01,  unity_OrthoParams.w)));
				float3 sceneColor = SampleSceneColor(refractedScreenPos.xy / refractedScreenPos.w).rgb;
			
				color.rgb = lerp(sceneColor, color.rgb, alpha);
				alpha = lerp(1.0, edgeFade, 1);

				color.a = alpha * saturate(alpha - vertexColor.g);
				ApplyFog(color.rgb, input.fogFactorAndVertexLight.x, ScreenPos, wPos, 1);
            	return float4(color); 
            }

            ENDHLSL
        }
//        Pass
//        {
//            Name "DepthOnly"
//            Tags{"LightMode" = "DepthOnly"}
//
//            ZWrite On
//            ColorMask 0
//            Cull[_Cull]
//
//            HLSLPROGRAM
//            #pragma exclude_renderers gles gles3 glcore
//            #pragma target 4.5
//
//            #pragma vertex DepthOnlyVertex
//            #pragma fragment DepthOnlyFragment
//
//            // -------------------------------------
//            // Material Keywords
//            #pragma shader_feature_local_fragment _ALPHATEST_ON
//            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//
//            //--------------------------------------
//            // GPU Instancing
//            #pragma multi_compile_instancing
//            #pragma multi_compile _ DOTS_INSTANCING_ON
//
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
//            ENDHLSL
//        }

    }
	//CustomEditor "Yamyii.CustomWaterUI"
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
