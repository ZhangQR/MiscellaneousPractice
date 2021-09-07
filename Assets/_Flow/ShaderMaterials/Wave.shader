Shader "URPPractice/Flow/Wave"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        // _FlowSpeed("FlowSpeed",float) = 1    //  _FlowSpeed 与 _Period 关联 
        //_Amplitude("Amplitude",float) = 1     // _Amplitude 与 _Period 关联  
//        _Steepness ("Steepness", Range(0, 1)) = 0.5
//        _Period("Period",float) = 1
//        _Direction ("Direction (2D)", Vector) = (1,0,0,0)         // 挤一挤，合并一下
        _WaveA ("Wave A (dir, steepness(0,1), wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B", Vector) = (0,1,0.25,20)
        _WaveC ("Wave C", Vector) = (0,1,0.25,20)
        _WaveD ("Wave D", Vector) = (0,1,0.25,20)   // 所有波长的 steepness 加起来不能超过 1
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 300
        Pass
        {
            Name "Wave"
            Tags{"LightMode" = "UniversalForward"}
            
            Blend One Zero
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

            #pragma enable_d3d11_debug_symbols

            //--------------------------------------
            // GPU Instancing
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Smoothness;
            half _Metallic;
            // float _FlowSpeed;
            // float _Amplitude;
            // float _Period;
            // float _Steepness;
            // float2 _Direction;
            float4 _WaveA,_WaveB,_WaveC,_WaveD;
            CBUFFER_END

            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {                
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
                outSurfaceData.alpha = 1;

                //half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
                outSurfaceData.albedo = _BaseColor.rgb * SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);

                outSurfaceData.metallic = _Metallic;
                outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);

                outSurfaceData.smoothness = _Smoothness;
                //outSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv),_BumpScale);
                outSurfaceData.normalTS = float3(0,0,1);
                // outSurfaceData.normalTS = normalize(float3(2,2,1));
                
                outSurfaceData.occlusion = 0;
                outSurfaceData.emission = 0;

                outSurfaceData.clearCoatMask       = 0.0h;
                outSurfaceData.clearCoatSmoothness = 0.0h;
            }

            float3 GerstnerWave (
			float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
			{
		        float steepness = wave.z;
		        float wavelength = wave.w;
		        float k = 2 * PI / wavelength;
			    float c = sqrt(9.8 / k);
			    float2 d = normalize(wave.xy);
			    float f = k * (dot(d, p.xz) - c * _Time.y);
			    float a = steepness / k;
			    
			    //p.x += d.x * (a * cos(f));
			    //p.y = a * sin(f);
			    //p.z += d.y * (a * cos(f));

			    tangent += float3(
				    -d.x * d.x * (steepness * sin(f)),
				    d.x * (steepness * cos(f)),
				    -d.x * d.y * (steepness * sin(f))
			    );
			    binormal += float3(
				    -d.x * d.y * (steepness * sin(f)),
				    d.y * (steepness * cos(f)),
				    -d.y * d.y * (steepness * sin(f))
			    );
			    return float3(
				    d.x * (a * cos(f)),
				    a * sin(f),
				    d.y * (a * cos(f))
			    );
		    }

            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            // Used in Standard (Physically Based) shader
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

            ///////////////////////////////////////////////////////////////////////////////
            //                  Sin Wave                                                 //
            ///////////////////////////////////////////////////////////////////////////////

                // // 改变顶点位置
                // float k = 2 * PI / _Period;
                // float f = k * input.positionOS.x - _Time.y * _FlowSpeed;
                // float y = _Amplitude * sin(f);
                // float3 positionOS = input.positionOS;
                // positionOS.y = y;
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);
                //
                // // 计算法线方向
                // // tangent = P'(x,asin(f)),     f=(kx+time)
                // // tangent = (1,akcos(f)),      normal = (-tangent.y,tangent,x)
                // float3 tangent = normalize(float3(1,_Amplitude*k*cos(f),0));
                // float3 normal = float3(-tangent.y,tangent.x,0);
                // VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));
                //
                // half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                // half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                // half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

            // ///////////////////////////////////////////////////////////////////////////////
            // //                  Gerstner Wave                                            //
            // ///////////////////////////////////////////////////////////////////////////////
            //     // 改变顶点位置
            //     float k = 2 * PI / _Period;
            //     float speed = sqrt(9.8/k);
            //     float f = k * input.positionOS.x - _Time.y * speed;
            //     float3 positionOS = input.positionOS;
            //     float a = _Steepness / k;
            //     positionOS.x += a * cos(f);
            //     //positionOS.x = a * cos(f);
            //     positionOS.y = a * sin(f);
            //     VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);
            //
            //     // 没有引进 _Steepness 前
            //     // // 计算法线方向
            //     // // tangent = P'(x+acos(f),asin(f)),     f=(kx+time)
            //     // // tangent = (1-aksin(f),akcos(f)),      normal = (-tangent.y,tangent,x)
            //     // float3 tangent = normalize(float3(1 - _Amplitude * k * sin(f),_Amplitude*k*cos(f),0));
            //     // float3 normal = float3(-tangent.y,tangent.x,0);
            //     // VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));
            //
            //     float3 tangent = normalize(float3(1 - _Steepness * k * sin(f),_Steepness*k*cos(f),0));
            //     float3 normal = float3(-tangent.y,tangent.x,0);
            //     VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));

            ///////////////////////////////////////////////////////////////////////////////
            //                  Gerstner Wave Direction                                  //
            ///////////////////////////////////////////////////////////////////////////////
                // // 改变顶点位置
                // float k = 2 * PI / _Period;
                // float speed = sqrt(9.8/k);
                // float2 d = normalize(_Direction);
                // float f = k * dot(d,input.positionOS.xz) - _Time.y * speed;
                // float3 positionOS = input.positionOS;
                // float a = _Steepness / k;
                // positionOS.x += d.x * a * cos(f);
                // //positionOS.x = a * cos(f);
                // positionOS.y = a * sin(f);
                // positionOS.z += d.y * a * cos(f);
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);
                //
                // // P(x+d_x*s/kcos(f), s/ksin(f), z+d_y*s/kcos(f)),  f=k*(d_x*x+d_y*z)-t;
                // // f' = k*d_x,  T = (1-d_x^2ssin(f),    d_xscos(f),    -d_xd_yssin(f))
                // // N = (-d_xd_yssin(f),     d_yscos(f),    1-d_y^2ssin(f))
                // float3 tangent = float3(1 - _Steepness *d.x*d.x * sin(f),_Steepness*d.x*cos(f),-d.x*d.y*_Steepness*sin(f));
                // float3 biNormal = float3(-d.x*d.y*_Steepness*sin(f),d.y*_Steepness*cos(f),1-d.y*d.y*_Steepness*sin(f));
                // float3 normal = normalize(cross(biNormal,tangent));
                // VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));


                float3 gridPoint = input.positionOS.xyz;
			    float3 tangent = float3(1, 0, 0);
			    float3 binormal = float3(0, 0, 1);
			    float3 p = gridPoint;
			    p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
                p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
                p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
                //p += GerstnerWave(_WaveD, gridPoint, tangent, binormal);
                float3 normal = normalize(cross(binormal,tangent));
                VertexPositionInputs vertexInput = GetVertexPositionInputs(p.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(normal, float4(tangent,1));

                
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
