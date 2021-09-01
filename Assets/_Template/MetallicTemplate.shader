Shader "Template/Lit"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        // _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        // _MetallicGlossMap("Metallic", 2D) = "white" {}

//        _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
//        _SpecGlossMap("Specular", 2D) = "white" {}

//        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
//        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}

//        _Parallax("Scale", Range(0.005, 0.08)) = 0.005
//        _ParallaxMap("Height Map", 2D) = "black" {}

//        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
//        _OcclusionMap("Occlusion", 2D) = "white" {}

//        [HDR] _EmissionColor("Color", Color) = (0,0,0)
//        _EmissionMap("Emission", 2D) = "white" {}

//        _DetailMask("Detail Mask", 2D) = "white" {}
//        _DetailAlbedoMapScale("Scale", Range(0.0, 2.0)) = 1.0
//        _DetailAlbedoMap("Detail Albedo x2", 2D) = "linearGrey" {}
//        _DetailNormalMapScale("Scale", Range(0.0, 2.0)) = 1.0
//        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        // SRP batching compatibility for Clear Coat (Not used in Lit)
//        [HideInInspector] _ClearCoatMask("_ClearCoatMask", Float) = 0.0
//        [HideInInspector] _ClearCoatSmoothness("_ClearCoatSmoothness", Float) = 0.0

        // Blending state
//        [HideInInspector] _Surface("__surface", Float) = 0.0
//        [HideInInspector] _Blend("__blend", Float) = 0.0
//        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
//        [HideInInspector] _SrcBlend("__src", Float) = 1.0
//        [HideInInspector] _DstBlend("__dst", Float) = 0.0
//        [HideInInspector] _ZWrite("__zw", Float) = 1.0
//        [HideInInspector] _Cull("__cull", Float) = 2.0

//        _ReceiveShadows("Receive Shadows", Float) = 1.0
//        // Editmode props
//        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
//
//        // ObsoleteProperties
//        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
//        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
//        [HideInInspector] _GlossMapScale("Smoothness", Float) = 0.0
//        [HideInInspector] _Glossiness("Smoothness", Float) = 0.0
//        [HideInInspector] _GlossyReflections("EnvironmentReflections", Float) = 0.0
//
//        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
//        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
//        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
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
            Name "ForwardLit"
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

            #pragma enable_d3d11_debug_symbols

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
            TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);
            

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Smoothness;
            half _Metallic;
            half _BumpScale;
            CBUFFER_END

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
    // float3  positionWS;
    // half3   normalWS;
    // half3   viewDirectionWS;
    // float4  shadowCoord;
    // half    fogCoord;
    // half3   vertexLighting;
    // half3   bakedGI;
    // float2  normalizedScreenSpaceUV;
    // half4   shadowMask;
                
                inputData = (InputData)0;

            //#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                inputData.positionWS = input.positionWS;
            //#endif

                half3 viewDirWS = SafeNormalize(input.viewDirWS);
            // #if defined(_NORMALMAP) || defined(_DETAIL)
                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
            // #else
            //     inputData.normalWS = input.normalWS;
            // #endif

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
    // half3 albedo;
    // half3 specular;
    // half  metallic;
    // half  smoothness;
    // half3 normalTS;
    // half3 emission;
    // half  occlusion;
    // half  alpha;
    // half  clearCoatMask;
    // half  clearCoatSmoothness;

                outSurfaceData.alpha = 1;

                //half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
                outSurfaceData.albedo = _BaseColor.rgb * SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);

                outSurfaceData.metallic = _Metallic;
                outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv),_BumpScale);
                // outSurfaceData.normalTS = normalize(float3(2,2,1));
                
                outSurfaceData.occlusion = 0;
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

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input.uv, surfaceData);

                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                // color.a = OutputAlpha(color.a, _Surface);

                return color;
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
