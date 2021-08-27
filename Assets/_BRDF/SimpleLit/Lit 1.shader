Shader "URPPractice/BRDF/Lit"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("BaseMap",2D) = "white"{}
        _MetallicMap("MetallicMap",2D) = "white"{}
        _Metallic("Metallic",Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness",Range(0.0, 1.0)) = 0.5
        _NormalMap("NormalMap",2D) = "white"{}
        _HeightMap("HeightMap",2D) = "white"{}
        _OcclusionMap("OcclusionMap",2D) = "white"{}
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "Z_LitForward"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma target 4.5

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
                float2 uv               :TEXCOORD0;
                float4 tangent          :TANGENT;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float3 positionWS       : TEXCOORD1;
                float3 normalWS         : TEXCOORD0;
                float2 uv               : VAR_UV;
                float3 TS2WS01          : VAR_TS2WS01;
                float3 TS2WS02          : VAR_TS2WS02;
                float3 TS2WS03          : VAR_TS2WS03;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMatrial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _F0)
                UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
                UNITY_DEFINE_INSTANCED_PROP(float4, _NormalMap_ST)
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
                output.TS2WS01 = normal_input.tangentWS;
                output.TS2WS02 = normal_input.bitangentWS;
                output.TS2WS03 = normal_input.normalWS;
                output.uv = input.uv * _NormalMap_ST.xy + _NormalMap_ST.zw;
                output.normalWS = normal_input.normalWS;
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                return output;
            }

            float k(float roughness)
            {
                return pow(roughness+1,2) * 0.125;
            }

            float G1(half3 v,half3 n,float roughness)
            {
                   return dot(v,n)/(dot(n,v)*(1-k(roughness)) + k(roughness));
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4x4 ts2ws = float4x4(  float4(input.TS2WS01,input.positionWS.x),
                                            float4(input.TS2WS02,input.positionWS.y),
                                            float4(input.TS2WS03,input.positionWS.z),
                                            float4(0,0,0,1));
                UNITY_SETUP_INSTANCE_ID(input);
                float3 v = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3  n = normalize(input.normalWS);
                Light light = GetMainLight();
                float3 l =  normalize(light.direction);
                float3 h = SafeNormalize(v+l);
                half4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial, _BaseColor);
                float smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial, _Smoothness);
                float f0 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial, _F0);
                float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial,_Metallic);
                

                half4 normal = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,input.uv);
                normal = half4(UnpackNormal(normal),0);
                //half4 normalWS = ts2ws * float4(normal,0);
                float3  normalWS =float3(dot(float4(input.TS2WS01,input.positionWS.x),normal),
                                         dot(float4(input.TS2WS02,input.positionWS.y),normal),
                                         dot(float4(input.TS2WS03,input.positionWS.z),normal));



                float perceptualRoughness = 1.0 - smoothness;
                float roughness = max(perceptualRoughness * perceptualRoughness,HALF_MIN_SQRT);
                float HoN2 = pow(saturate(dot(n,h)),2);
                float HoL2 = pow(saturate(dot(l,h)),2);
                float roughness2 = max(roughness * roughness,HALF_MIN);
                half3 albedo = base_color.xyz; // 其实是 baseMap * baseColor
                half3 brdfSpecular = lerp(half3(0.04,0.04,0.04),albedo,metallic);
                half reflectivity = 0.96 * metallic + 0.04;
                float surfaceReduction = 1.0 / (roughness2 + 1.0);
                float NoV = saturate(dot(n,v));
                float NoL = saturate(dot(n,l));
                float HoL = saturate(dot(h,l));
                float fresnelTerm = pow(1-NoV,4);
                float grazingTerm = saturate(smoothness + reflectivity);
                half3 brdfDiffuse = albedo * (1-reflectivity);
                half3 bakedGI = SampleSH(n);
                half3 radiance = light.color * (light.distanceAttenuation * NoL); 
                float brdfDirectSpeclar = roughness2 / (pow(HoN2 *(roughness2-1) +1,2) * max(0.1h,HoL2)*(4 * roughness+2.0));
                half brdfEnv = pow(1-max(roughness,dot(n,v)),3);
                half3 directBDRF = (brdfDiffuse + brdfSpecular * brdfDirectSpeclar)*radiance;
                


                // half3 indirectDiffuse
                // half3 indirectSpecular = 
                half3 environmentBRDFSpecular = surfaceReduction * lerp(brdfSpecular, grazingTerm, fresnelTerm);
                half3 reflectVector = reflect(-v, n);
                half3 environmentBRDF = bakedGI * brdfDiffuse + environmentBRDFSpecular * GlossyEnvironmentReflection(reflectVector,perceptualRoughness,1);
                



                float alpha = roughness2;
                float GGXD = alpha * alpha /(PI*pow(1+(alpha*alpha-1) * HoN2,2));
                float BlinnD = pow(dot(n,h),5);
                
                float G = G1(l,n,roughness) * G1(v,n,roughness);
                half fresnel = f0 + (1-f0) * pow(1 - HoL,5);
                
                float D = GGXD;
                float cook_torrance = fresnel * D * G / (4* NoL * NoV);

                float d90 = 0.5 + 2 * smoothness * (pow(saturate(dot(n,l)),2));
                float diff = ((d90-1)*pow(1-saturate(dot(n,l)),5)+1)*((d90-1)*pow(1-saturate(dot(n,v)),5)+1);
                half4 diffColor = base_color * diff /PI;


                half3 final_color = environmentBRDF + directBDRF;


                
                //return half4(half3(cook_torrance * brdfSpecular),1);
                return half4(directBDRF + environmentBRDF,1);
                // return half4(brdfSpecular * brdfEnv + brdfSpecular * brdfDirectSpeclar,1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}