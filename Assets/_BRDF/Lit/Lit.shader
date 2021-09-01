Shader "URPPractice/BRDF/Lit"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("BaseMap",2D) = "white"{}
        _Metallic("Metallic",Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness",Range(0.0, 1.0)) = 0.5
        [Enum(UnityEngine.Rendering.BlendMode)] _Blend ("Blend mode", Float) = 1
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "LitBrdfForword"
            Tags{"LightMode" = "UniversalForward"}
            CULL Back
            Blend One Zero
            ZWrite ON
            HLSLPROGRAM
            #pragma target 4.5

            //--------------------------------------
            // GPU Instancing
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float4 normalOS           : NORMAL;
                float4 tangent          :TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float3 positionWS       : TEXCOORD1;
                float3 normalWS         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
                UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
            UNITY_INSTANCING_BUFFER_END(UnityPerMatrial)

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                VertexPositionInputs vertex_input = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertex_input.positionCS;
                output.positionWS = vertex_input.positionWS;
                VertexNormalInputs normal_input = GetVertexNormalInputs(input.normalOS.xyz,input.tangent);
                output.normalWS = normal_input.normalWS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                ///////////////////////////////////////////////////////////////////////////////
                //                      准备数据                                               //
                ///////////////////////////////////////////////////////////////////////////////
                half4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                float smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
                float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Metallic);

                Light light = GetMainLight();       // 目前只考虑一个灯光
                float3 v = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3  n = normalize(input.normalWS);
                float3 l =  normalize(light.direction);
                float3 h = SafeNormalize(v+l);
                float NOH2 = pow(saturate(dot(n,h)),2);
                float LOH2 = pow(saturate(dot(l,h)),2);
                float VON = saturate(dot(n,v));
                float LON = saturate(dot(n,l));

                float perceptualRoughness = 1.0 - smoothness;
                float roughness = max(perceptualRoughness * perceptualRoughness,HALF_MIN_SQRT);
                float roughness2 = max(roughness * roughness,HALF_MIN);

                half3 albedo = base_color.xyz; // 其实是 baseMap * baseColor
                half reflectivity = 0.96 * metallic + 0.04;

                ///////////////////////////////////////////////////////////////////////////////
                //                      直接光 BRDF，公式见博客                                 //
                ///////////////////////////////////////////////////////////////////////////////
                half3 directBrdfSpecularColor = lerp(half3(0.04,0.04,0.04),albedo,metallic);                
                half3 directBrdfDiffuseColor = albedo * (1-reflectivity);
                half3 radiance = light.color * (light.distanceAttenuation * LON); 
                float directBrdfSpeclar = roughness2 / (pow(NOH2 *(roughness2-1) +1,2) * max(0.1h,LOH2)*(4 * roughness+2.0));
                half3 directBDRF = (directBrdfDiffuseColor + directBrdfSpecularColor * directBrdfSpeclar) * radiance;

                ///////////////////////////////////////////////////////////////////////////////
                //                      环境光 BRDF                                           //
                ///////////////////////////////////////////////////////////////////////////////                
                // half3 indirectDiffuse
                // half3 indirectSpecular =
                float grazingTerm = saturate(smoothness + reflectivity);
                float surfaceReduction = 1.0 / (roughness2 + 1.0);
                float fresnelTerm = pow(1-VON,4);
                half3 environmentBRDFSpecularColor = surfaceReduction * lerp(directBrdfSpecularColor, grazingTerm, fresnelTerm);
                half3 reflectVector = reflect(-v, n);
                half3 bakedGI = SampleSH(n);
                half3 environmentBRDF = bakedGI * directBrdfDiffuseColor + environmentBRDFSpecularColor * GlossyEnvironmentReflection(reflectVector,perceptualRoughness,1);
                
                ///////////////////////////////////////////////////////////////////////////////
                //                      合并输出                                              //
                /////////////////////////////////////////////////////////////////////////////// 
                half3 final_color = environmentBRDF + directBDRF;
                return half4(final_color,1);
            }
            ENDHLSL
        }
        
        // 没有 LightMode = DepthOnly 的一层 pass，Scene 中的网格会画到物体前面去
        Pass
        {
            Name "BRDFDepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
            };

            Varyings DepthOnlyVertex(Attributes input) 
            {
                Varyings output = (Varyings)0;

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}