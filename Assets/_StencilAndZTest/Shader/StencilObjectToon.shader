Shader "URPPractice/StencilObjectToon"
{
    Properties
    {
        _Color ("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Ramp ("Toon Ramp (RGB)", 2D) = "black" {} 
        _StencilID("StencilID",float) = 1       
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry+2" "ShaderModel"="4.5"}
        LOD 300

        Pass
        {
            Name "StencilObjectToon"
            Tags{"LightMode" = "UniversalForward"}
            
            // ColorMask rgba
            ZWrite On
            Stencil{
				Ref [_StencilID]
				Comp equal
            }

            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normalOS     : NORMAL;
                float2 uv           :TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       :TEXCOORD0;
                float3 normalWS                 :TEXCOORD1;
            };
            

            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            TEXTURE2D(_Ramp);   SAMPLER(sampler_Ramp);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _RampTex_ST;
            CBUFFER_END


            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInput.normalWS;
                output.positionCS = vertexInput.positionCS;
                output.uv = input.uv;
                return output;
            }

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                float4 aldobe = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float4 finalColor = aldobe * _Color;
                // return float4(finalColor.rgb,1.0);

                Light mainLight = GetMainLight();
                float3 normalWS = normalize(input.normalWS);
                // return float4(normalWS,1.0);
                float3 lightDir = normalize(mainLight.direction);
                // return float4(lightDir,1.0);
                float NoL = max(0.005,dot(normalWS,lightDir));
                // return float4(NoL.xxx,1.0);
                float3 grendient = SAMPLE_TEXTURE2D(_Ramp,sampler_Ramp,float2(NoL,NoL));
                // return float4(grendient.rgb,1.0);

                finalColor.rgb *= grendient;
                
                
                return float4(finalColor.rgb,1);
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
