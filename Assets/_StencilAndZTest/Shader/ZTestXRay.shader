Shader "URPPractice/XRay"
{
    Properties
    {
        _XRayColor("XRayColor",Color) = (1,1,1,1)
        _HighlightColor("HighlightColor",Color) = (1,1,1,1)
        _Threshold("Threshold",float) = 0.1
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
            Stencil{
				Ref 0
				Comp equal
				Pass keep
			}

            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            // #include "UnityCG.cginc"
            #include "HLSLSupport.cginc"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float4 projPos                  : TEXTCOORD0;
            };

            // TEXTURE2D(_CameraDepthTexture);
            // SAMPLER(sampler_CameraDepthTexture);
            half4 _HighlightColor;
            float _Threshold;

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END


            inline float3 UnityObjectToViewPos( in float3 pos )
            {
                return mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(pos, 1.0))).xyz;
            }
            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.projPos = ComputeScreenPos (output.positionCS);      
                output.projPos.z = -UnityObjectToViewPos( input.positionOS ).z;  //计算当前物体的深度值
                return output;
            }

            // Used in Standard (Physically Based) shader
            half4 LitPassFragment(Varyings input) : SV_Target
            {
                // return half4(input.projPos.xy,0,1);
                // return half4(input.projPos.zzz,1);
                float depth = SampleSceneDepth(input.projPos.xy/input.projPos.w);
                // return half4(depth.xxx,1); // 1-0
                float eyeDepth = LinearEyeDepth (depth,_ZBufferParams);  //访问深度纹理图，_CameraDepthTexture存储的是屏幕深度信息
                //return half4(eyeDepth.xxx,1);   // 0-1
                float partZ = input.projPos.z;  //当前片元的深度
                //return half4(partZ.xxx,1);
                float diff = min ( abs(eyeDepth - partZ) / _Threshold, 1);  //判断两点的深度是否小于_Threshold,小于就lerp颜色
                half4 finalColor = lerp(_HighlightColor, half4(1,0,0,1), diff);
                return finalColor;
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
