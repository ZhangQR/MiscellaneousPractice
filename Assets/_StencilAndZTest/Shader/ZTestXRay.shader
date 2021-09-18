Shader "URPPractice/XRay"
{
    Properties
    {
        _XRayColor("XRayColor",Color) = (1,1,1,1)
        
    }

    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+1" "ShaderModel"="4.5"}

        Pass
        {
            Name "XRayNormal"
            Tags{"LightMode" = "UniversalForward"}
            Blend One Zero
            ZTest Less
            ZWrite On

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
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
            };
            

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END


            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {    
                return float4(1,0,0,1);
            }

            ENDHLSL
        }
        
        Pass
        {
            Name "XRay"
            Tags{"LightMode" = "SRPDefaultUnlit"}
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Greater
            ZWrite Off

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
                float4 normalOS       : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float3 normalWS       : NORMAL;
            };
            

            CBUFFER_START(UnityPerMaterial)
                half4 _XRayColor;
            CBUFFER_END


            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.positionOS.xyz);
                output.normalWS = normalInput.normalWS;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                float3 viewDir =  -GetViewForwardDir();
                // return float4(-viewDir.rgb,1.0);
                float VoN = dot(viewDir,normalize(input.normalWS));
                // return float4(VoN.xxx,1.0);
                // half3 finalColor = _XRayColor * VoN;
                half4 finalColor = lerp(_XRayColor,half4(1,1,1,0),VoN);
                return float4(finalColor);
            }

            ENDHLSL
        }
    }

FallBack "Hidden/Universal Render Pipeline/FallbackError"
    //CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
