Shader "URPPractice/BRDF/Fresnel"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _F0("F0",Range(0.0,1.0)) = 0.04
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "fresnel"

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
            UNITY_INSTANCING_BUFFER_START(UnityPerMatrial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _F0)
            UNITY_INSTANCING_BUFFER_END(UnityPerMatrial)

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertex_input = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertex_input.positionCS;
                output.positionWS = vertex_input.positionWS;
                VertexNormalInputs normal_input = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normal_input.normalWS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                float3 v = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3  n = normalize(input.normalWS);
                Light light = GetMainLight();
                float3 l =  normalize(light.direction);
                float3 h = normalize(v+l);
                half3 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial, _BaseColor);
                float f0 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMatrial, _F0);
                half fresnel = f0 + (1-f0) * pow(1-saturate(dot(h,l)),5);
                half3 final_color = fresnel * base_color; 
                return half4(final_color, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}