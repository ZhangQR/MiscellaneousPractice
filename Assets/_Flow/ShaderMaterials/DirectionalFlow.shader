Shader "URPPractice/Flow/Directional"
{
    Properties
    {
	    _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
	    [NoScaleOffset] _BaseMap ("Deriv (AG) Height (B)", 2D) = "black" {}
		[NoScaleOffset] _FlowMap ("Flow (RG)", 2D) = "black" {}
        _BumpScale ("NormalScale", Float) = 1
        _FlowStrength ("Flow Strength", Float) = 1
        _Speed ("Speed", Float) = 1
        _BaseColor ("Color", Color) = (1,1,1,1)
        _Tiling ("Tiling", Float) = 1
        _TilingModulated ("Tiling, Modulated", Float) = 1   
        _GridResolution ("Grid Resolution", Float) = 10
	    _HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75
    	[Toggle(_DUAL_GRID)] _DualGrid ("Dual Grid", Int) = 0
        [Toggle(_Test)]_Test("Test",float) = 0.0

    }

    SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "Directional"
            Tags{"LightMode" = "UniversalForward"}

//            Blend[_SrcBlend][_DstBlend]
//            ZWrite[_ZWrite]
//            Cull[_Cull]
            
            Blend One Zero

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local _NORMALMAP
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            // #pragma shader_feature_local_fragment _EMISSION
            // #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature_local_fragment _OCCLUSIONMAP
            // #pragma shader_feature_local _PARALLAXMAP
            // #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            // #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            // #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            // #pragma shader_feature_local_fragment _SPECULAR_SETUP
            // #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

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
            #pragma shader_feature _DUAL_GRID

            #ifdef _Test
            #pragma enable_d3d11_debug_symbols
            #endif
            

            //--------------------------------------
            // GPU Instancing
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                // UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
                float3 positionWS               : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
                float3 viewDirWS                : TEXCOORD5;
                half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
                float4 positionCS               : SV_POSITION;
                // UNITY_VERTEX_INPUT_INSTANCE_ID
                // UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_FlowMap);            SAMPLER(sampler_FlowMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Smoothness;
            half _Metallic;
            half _BumpScale;
            float _Speed;
            float _FlowStrength;
            float _Tiling,_TilingModulated;
            float _GridResolution;
            float _HeightScale;
            float _HeightScaleModulated;
            CBUFFER_END

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {   
                inputData = (InputData)0;

            //#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                inputData.positionWS = input.positionWS;

                half3 viewDirWS = SafeNormalize(input.viewDirWS);
                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = viewDirWS;

            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                inputData.shadowCoord = input.shadowCoord;
            #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
            #else
                inputData.shadowCoord = float4(0, 0, 0, 0);
            #endif

                inputData.fogCoord = input.fogFactorAndVertexLight.x;
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
            }

            half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
            {
                half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
                return normalize(UnpackNormalScale(n, scale));
            }   

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                outSurfaceData.alpha = _BaseColor.a;

                //half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
                //outSurfaceData.albedo = _BaseColor.rgb * SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
                // float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
                // float3 dh = baseMap.agb;
                outSurfaceData.albedo = _BaseColor.rgb;
                // dh.xy = dh.xy * 2 - 1;
                outSurfaceData.normalTS =float3(0,0,1);

                outSurfaceData.metallic = _Metallic;
                outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
                outSurfaceData.smoothness = _Smoothness;
                
                
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0;

                outSurfaceData.clearCoatMask       = 0.0h;
                outSurfaceData.clearCoatSmoothness = 0.0h;
            }

            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            // Used in Standard (Physically Based) shader
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                // already normalized from normal transform to WS.
                output.normalWS = normalInput.normalWS;
                output.viewDirWS = viewDirWS;
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
                output.tangentWS.xyz = normalInput.tangentWS;
                output.tangentWS.w = input.tangentOS.w;

                return output;
            }

            float3 UnpackDerivativeHeight (float4 textureData)
            {
			    float3 dh = textureData.agb;
			    dh.xy = dh.xy * 2 - 1;
			    return dh;
		    }

            float2 DirectionalFlowUV(float2 uv,float3 flowVector,float time,float tiling,out float2x2 rotateOut)
            {
	            float2 dir = normalize(flowVector.xy);
	            uv = mul(float2x2(dir.y, -dir.x, dir.x, dir.y), uv);
                //uv = mul(float2x2(cos(time), -sin(time), sin(time), cos(time)), uv);
                //uv = mul(float2x2(dir.x, -dir.y,dir.y, dir.x), uv);
                //float2x2 rotate = float2x2(0,-1,1,0);
                // float2x2 rotate = float2x2(1,0,0,1);
                // rotateOut = float2x2(1,0,0,1);
                //rotateOut = float2x2(0,1,-1,0);
                rotateOut = float2x2(dir.y,dir.x,-dir.x,dir.y);
                //rotateOut = float2x2(dir.x, dir.y,-dir.y, dir.x);
                uv.y -= time * flowVector.z;
                return uv * tiling;
                
            }



            float3 FlowCell (float2 uv, float2 offset, float time, float gridB)
            {
                float2 shift = 1 - offset;
		        shift *= 0.5;
		        offset *= 0.5;
				if (gridB)
				{
			        offset += 0.25;
			        shift -= 0.25;
				}
			    float2 uvTiled =
				(floor(uv * _GridResolution + offset) + shift ) / _GridResolution;
                // float2 uvTiled = floor(uv * _GridResolution + offset)/_GridResolution; 
                //float4 flowDirection = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uvTiled);
                float4 flow = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uvTiled);
                flow.xy = flow.xy * 2 - 1;
                flow.z *= _FlowStrength;
                float2x2 rotate;    // 用于旋转法线
                float tiling = flow.z * _TilingModulated + _Tiling;
                float2 uvMain = DirectionalFlowUV(uv + offset,flow,time,tiling,rotate);
                float3 dh = UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uvMain));
                dh.xy = mul(rotate,dh.xy);
                dh *= flow.z * _HeightScaleModulated + _HeightScale;
                return dh;
            }

            float3 FlowGrid (float2 uv, float time, bool gridB)
            {
		        float3 dhA = FlowCell(uv, float2(0, 0), time,gridB);
			    float3 dhB = FlowCell(uv, float2(1, 0), time,gridB);
			    float3 dhC = FlowCell(uv, float2(0, 1), time,gridB);
			    float3 dhD = FlowCell(uv, float2(1, 1), time,gridB);

				float2 t = uv * _GridResolution;
				if (gridB) {
				    t += 0.25;
				}
				t = abs(2 * frac(t) - 1);
			    float wA = (1 - t.x) * (1 - t.y);
			    float wB = t.x * (1 - t.y);
			    float wC = (1 - t.x) * t.y;
			    float wD = t.x * t.y;

			    return dhA * wA + dhB * wB + dhC * wC + dhD * wD;
		    }

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                float time = _Time.y * _Speed;
                float2 uv = input.uv;
			    // float3 dhA = FlowCell(uv, float2(0, 0), time);
			    // float3 dhB = FlowCell(uv, float2(1, 0), time);
			    // float3 dhC = FlowCell(uv, float2(0, 1), time);
			    // float3 dhD = FlowCell(uv, float2(1, 1), time);
       //
			    // float2 t = abs(2 * frac(uv * _GridResolution) - 1);
			    // // float wA = (1 - t.x) * (1 - t.y);
			    // // float wB = t.x * (1 - t.y);
       //          // 			    float wC = (1 - t.x) * t.y;
			    // //float wD = t.x * t.y;
       //
       //          //float2 t = frac(uv * _GridResolution);
       //          float wA = (1-t.x)*(1-t.y);
			    // float wB = t.x*(1-t.y);
       //          float wC = (1-t.x)*t.y;
       //          float wD = t.x*t.y;

                float3 dh = FlowGrid(uv, time, false);
            	#if defined(_DUAL_GRID)
			    dh = (dh + FlowGrid(uv, time, true)) * 0.5;
            	#endif
            	
                //float3 dh = dhA * wA + dhB * wB ;
                //float3 dh = dhC * wC + dhA * wA;
                
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(uv, surfaceData);
                float4 c = dh.z*dh.z*_BaseColor;
                surfaceData.normalTS = normalize(float3(-dh.xy,1));
                surfaceData.albedo = c.rgb;

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                // color.a = OutputAlpha(color.a, _Surface);

                return color;
                return float4(1,1,1,1);
                //float term = 2*frac(uv * _GridResolution)-1;
                // float term = 1-t.y;
                // return float4(term,term,term,1);
                //return float4(t.x,t.x,t.x,1);
                //return float4(1-t.x,1-t.x,1-t.x,1);
            }


            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
