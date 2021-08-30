Shader "URPPractice/BRDF/Cook_Torrance"
{
    Properties
    {
        [MainMap] _AlbedoMap("AlbedoMap",2D) = "white"{}
        _BaseColor("baseColor",Color) = (1.0,1.0,1.0,1.0)
        _NormalMap("NormalMap",2D) = "bump"{}
        _NormalScale("Normal Scale", Range(0, 1)) = 1
        [Toggle(Use_Texture)]_UesTexture("UseTexture",float) = 0.0
        [NoScaleOffset]_MODSMap("MODSMap",2D) = "white"{}
        _IrradianceMap("IrradianceMap",Cube) = ""{}
        _Metallic("Metallic",Range(0.0, 1.0)) = 0.5
        _Occlusion("Occlusion",Range(0.0, 1.0)) = 0.5
        _Roughness ("Roughness",Range(0.0, 1.0)) = 0.5
        [Toggle(_Ues_Environment)]_UesEnvironment("UesEnvironment",float) = 0.0
        
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "Cook_Torrance"
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

            #pragma multi_compile __ Use_Texture
            #pragma multi_compile __ _Ues_Environment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float4 normalOS           : NORMAL;
                float4 tangent          :TANGENT;
                float2 uv               :TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float3 positionWS       : TEXCOORD1;
                float3 normalWS         : TEXCOORD0;
                float4 uv               :VAR_UV;    // xy,albedo ,wz,MODS
                float4 tangentWS          :VAR_TS2WS01;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_AlbedoMap);
            SAMPLER(sampler_AlbedoMap);
            TEXTURE2D(_MODSMap);
            SAMPLER(sampler_MODSMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURECUBE(_IrradianceMap);
            SAMPLER(sampler_IrradianceMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
                UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
                UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AlbedoMap_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _MODSMap_ST)
            UNITY_INSTANCING_BUFFER_END(UnityPerMatrial)

//#define metallic UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic)
#define roughness UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Roughness)
#define albedoMapST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_AlbedoMap_ST)
#define modsMapST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MODSMap_ST)
#define baseColor UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseColor)
#define meta UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Metallic)
#define occlusion UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Occlusion)
#define normalMapScale UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_NormalScale)

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                VertexPositionInputs vertex_input = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertex_input.positionCS;
                output.positionWS = vertex_input.positionWS;
                VertexNormalInputs normal_input = GetVertexNormalInputs(input.normalOS.xyz,input.tangent);
                output.tangentWS.xyz = normal_input.tangentWS;
                output.tangentWS.w = input.tangent.w;
                output.normalWS = normalize(normal_input.normalWS);
                output.uv.xy = input.uv*albedoMapST.xy+albedoMapST.zw;
                output.uv.wz = input.uv*modsMapST.xy+modsMapST.zw;
                return output;
            }

            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                float a      = roughness*roughness;
                float a2     = a*a;
                float NdotH  = max(dot(N, H), 0.0);
                float NdotH2 = NdotH*NdotH;

                float nom   = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;

                return nom / denom;
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }
            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2  = GeometrySchlickGGX(NdotV, roughness);
                float ggx1  = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }

            float3 fresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }

            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                float OneMinusRoughness = 1.0 - roughness;
                return F0 + (max(float3(OneMinusRoughness,OneMinusRoughness,OneMinusRoughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }  

            // https://learnopengl-cn.github.io/07%20PBR/02%20Lighting/
            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                ///////////////////////////////////////////////////////////////////////////////
                //                      准备数据                                               //
                ///////////////////////////////////////////////////////////////////////////////
                Light light = GetMainLight();       // 目前只考虑一个灯光
                float3 V = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3  N = normalize(input.normalWS);
                float3 L =  normalize(light.direction);
                float3 H = SafeNormalize(V+L);
                float4 albedo = SAMPLE_TEXTURE2D(_AlbedoMap,sampler_AlbedoMap,input.uv.xy) * baseColor;
                float4 mods = SAMPLE_TEXTURE2D(_MODSMap,sampler_MODSMap,input.uv.wz);
                
                #ifdef Use_Texture
                float ao = mods.y * occlusion ;
                float metallic = mods.x * meta;
                float4 normal = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,input.uv.xy);
                normal.xyz = UnpackNormalmapRGorAG(normal, normalMapScale);
                float3x3 tangent2world =CreateTangentToWorld(input.normalWS,input.tangentWS.xyz,input.tangentWS.w);
                N = normalize(TransformTangentToWorld(normal,tangent2world));

                #else
                float ao = occlusion;
                float metallic = meta;
                albedo = baseColor;
                #endif
                

                ///////////////////////////////////////////////////////////////////////////////
                //                           BRDF : 直接光                                    //
                ///////////////////////////////////////////////////////////////////////////////

                float3 F0 = float3(0.04,0.04,0.04); 
                F0 = lerp(F0, albedo, metallic); 

                // reflectance equation
                float3 Lo = float3(0.0,0.0,0.0);

                // calculate per-light radiance
                float distance    = length(light.direction);
                float attenuation = 1.0 / (distance * distance);
                float3 radiance     = light.color * attenuation;        

                // cook-torrance brdf
                float NDF = DistributionGGX(N, H, roughness);        
                float G   = GeometrySmith(N, V, L, roughness);      
                float3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       

                float3 kS = F;
                float3 kD = float3(1.0,1.0,1.0) - kS;
                kD *= 1.0 - metallic;     

                float3 nominator    = NDF * G * F;
                float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
                float3 specular     = nominator / denominator;

                // add to outgoing radiance Lo
                float NdotL = max(dot(N, L), 0.0);                
                Lo += (kD * albedo / PI + specular) * radiance * NdotL; // 这里没有 *kS 是因为 F 已经乘过了

                ///////////////////////////////////////////////////////////////////////////////
                //                           BRDF : 间接光                                    //
                ///////////////////////////////////////////////////////////////////////////////

                #ifdef _Ues_Environment
                float3 kSEvr = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
                //float3 kSEvr = fresnelSchlick(max(dot(N, V), 0.0), F0);
                float3 kDEvr = 1.0 - kSEvr;
                float3 irradiance = SAMPLE_TEXTURECUBE(_IrradianceMap,sampler_IrradianceMap,N).rgb;
                float3 diffuse    = irradiance * albedo;
                // float3 ambient    = (kDEvr * diffuse) * ao;  // 正确应该是这样，但上面那个 F0,为什么那么写，没搞懂，albedo 中的金属是黄色的，难道反射率是 (0.8,0.8,0) 嘛？
                float3 ambient    = diffuse * ao;
                #else
                float3 ambient = float3(0.03,0.03,0.03) * albedo * ao;
                #endif
                
                float3 color = ambient + Lo;

                // color = color / (color + float3(1.0,1.0,1.0));
                // color = pow(color, float3(1.0,1.0,1.0) / 2.2);

                return float4(color ,1.0);
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
