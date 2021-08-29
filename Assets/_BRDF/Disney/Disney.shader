Shader "URPPractice/BRDF/Disney"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Metallic("Metallic",Range(0.0, 1.0)) = 0.5
        _Subsurface("Subsurface",float) = 0.5
        _Specular("Specular",float) = 0.5
        _Roughness ("Roughness",float) = 0.5
        _SpecularTint("SpecularTint",float) = 0.5
        _Anisotropic("Anisotropic",float) = 0.5 
        _Sheen("Sheen",float) = 0.5
        _SheenTint("SheenTint",float) = 0.5
        _Clearcoat("Clearcoat",float) = 0.5
        _ClearcoatGloss("ClearcoatGloss",float) = 0.5 
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "Disney"
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

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
                UNITY_DEFINE_INSTANCED_PROP(float, _Subsurface)
                UNITY_DEFINE_INSTANCED_PROP(float, _Specular)
                UNITY_DEFINE_INSTANCED_PROP(float, _Roughness)
                UNITY_DEFINE_INSTANCED_PROP(float, _SpecularTint)
                UNITY_DEFINE_INSTANCED_PROP(float, _Anisotropic)
                UNITY_DEFINE_INSTANCED_PROP(float, _Sheen)
                UNITY_DEFINE_INSTANCED_PROP(float, _SheenTint)
                UNITY_DEFINE_INSTANCED_PROP(float, _Clearcoat)
                UNITY_DEFINE_INSTANCED_PROP(float, _ClearcoatGloss)
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

            half Pow5(half v)
            {
	            return v * v * v * v * v;
            }

            float sqr(float x)
            {
                return x*x;
            }

            float SchlickFresnel(float u)
            {
                float m = clamp(1-u, 0, 1);
                float m2 = m*m;
                return m2*m2*m; // pow(m,5)
            }

            float GTR1(float NdotH, float a)
            {
                if (a >= 1) return 1/PI;
                float a2 = a*a;
                float t = 1 + (a2-1)*NdotH*NdotH;
                return (a2-1) / (PI*log(a2)*t);
            }

            float GTR2(float NdotH, float a)
            {
                float a2 = a*a;
                float t = 1 + (a2-1)*NdotH*NdotH;
                return a2 / (PI * t*t);
            }

            float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
            {
                return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
            }

            float smithG_GGX(float NdotV, float alphaG)
            {
                float a = alphaG*alphaG;
                float b = NdotV*NdotV;
                return 1 / (NdotV + sqrt(a + b - a*b));
            }

            float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
            {
                return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
            }

            float3 mon2lin(float3 x)
            {
                return float3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                ///////////////////////////////////////////////////////////////////////////////
                //                      准备数据                                               //
                ///////////////////////////////////////////////////////////////////////////////
                half4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
                float subsurface  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Subsurface);
                float specular  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Specular);
                float roughness  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Roughness);
                float specularTint  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_SpecularTint);
                float anisotropic  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Anisotropic);
                float sheen  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Sheen);
                float sheenTint  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_SheenTint);
                float clearcoat  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Clearcoat);
                float clearcoatGloss  = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_ClearcoatGloss);

                Light light = GetMainLight();       // 目前只考虑一个灯光
                float3 V = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3  N = normalize(input.normalWS);
                float3 L =  normalize(light.direction);
                float3 H = SafeNormalize(V+L);
                float3 X = 0.5;
                float3 Y = 0.5;

                ///////////////////////////////////////////////////////////////////////////////
                //                      BRDF                                                //
                ///////////////////////////////////////////////////////////////////////////////
                half3 finalColor = float3(0,0,0);
                float NdotL = dot(N,L);
                float NdotV = dot(N,V);
                if (NdotL < 0 || NdotV < 0) return half4(finalColor,1);

                // float3 H = normalize(L+V);
                float NdotH = dot(N,H);
                float LdotH = dot(L,H);

                float3 Cdlin = mon2lin(base_color.xyz);
                float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.

                float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1,1,1); // normalize lum. to isolate hue+sat
                float3 Cspec0 = lerp(specular*.08*lerp(float3(1,1,1), Ctint, specularTint), Cdlin, metallic);
                float3 Csheen = lerp(float3(1,1,1), Ctint, sheenTint);

                // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
                // and lerp in diffuse retro-reflection based on roughness
                float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
                float Fd90 = 0.5 + 2 * LdotH*LdotH * roughness;
                float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);

                // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
                // 1.25 scale is used to (roughly) preserve albedo
                // Fss90 used to "flatten" retroreflection based on roughness
                float Fss90 = LdotH*LdotH*roughness;
                float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
                float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);

                // specular
                float aspect = sqrt(1-anisotropic*.9);
                float ax = max(.001, sqr(roughness)/aspect);
                float ay = max(.001, sqr(roughness)*aspect);
                float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
                float FH = SchlickFresnel(LdotH);
                float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
                float Gs;
                Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
                Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);

                // sheen
                float3 Fsheen = FH * sheen * Csheen;

                // clearcoat (ior = 1.5 -> F0 = 0.04)
                float Dr = GTR1(NdotH, lerp(.1,.001,clearcoatGloss));
                float Fr = lerp(.04, 1.0, FH);
                float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);

                finalColor = ((1/PI) * lerp(Fd, ss, subsurface)*Cdlin + Fsheen)
                    * (1-metallic)
                    + Gs*Fs*Ds + .25*clearcoat*Gr*Fr*Dr;
                return half4(finalColor,1);
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