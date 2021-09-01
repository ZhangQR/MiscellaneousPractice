Shader "URPPractice/Flow/Direction"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Deriv (AG) Height (B)", 2D) = "black" {}
		[NoScaleOffset] _FlowMap ("Flow (RG)", 2D) = "black" {}
        _FlowStrength ("Flow Strength", Float) = 1
        _Speed ("Speed", Float) = 1
        _Angle ("Angle", Float) = 1
        _Color ("Color", Color) = (1,1,1,1)
        _Tiling ("Tiling", Float) = 1
        _NormalScale ("NormalScale", Float) = 1
		_GridResolution ("Grid Resolution", Float) = 10
        _Environment("Environment",Cube) = ""{}
        _HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75
        [Toggle(_Test)]_Test("Test",float) = 0.0
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 100
        
        Pass
        {
            Name "Flow"
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

            #pragma multi_compile __ _Test
            #pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float4 normalOS         : NORMAL;
                float4 tangentOS        :TANGENT;
                float2 uv               :TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex           : SV_POSITION;
                float3 normalWS         : NORMALWS;
                float4 tangentWS        :TangenrWS;
                float3 positionWS       :VAR_POSITION;
                float2 uv               :VAR_UV;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_FlowMap);
            SAMPLER(sampler_FlowMap);
            TEXTURECUBE(_Environment);
            SAMPLER(sampler_Environment);
            

            CBUFFER_START(UnityPerMaterial)
                float _FlowStrength;
                float _Speed;
                float _Angle;
                float4 _Color;
                float _Tiling;
                float _NormalScale;
                float _GridResolution;
                float _HeightScale;
                float _HeightScaleModulated;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertex_input = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                output.normalWS = normalInput.normalWS;
                output.tangentWS.xyz = normalInput.tangentWS;
                output.tangentWS.w = input.tangentOS.w;
                output.vertex = vertex_input.positionCS;
                output.positionWS = vertex_input.positionWS;
                output.uv = input.uv;
                return output;
            }
 

            float2 DirectionalFlowUV(float2 uv,float3 directionAndSpeed,float time,out float2x2 rotateOut)
            {
                directionAndSpeed = normalize(directionAndSpeed);
                //float2x2 rotate = float2x2(directionAndSpeed.x,-directionAndSpeed.y,directionAndSpeed.y,directionAndSpeed.x);
                //float2x2 rotate = float2x2(0,-1,1,0);
                float2x2 rotate = float2x2(1,0,0,1);
                rotateOut = float2x2(1,0,0,1);
                //rotateOut = float2x2(0,1,-1,0);
                //rotateOut = float2x2(directionAndSpeed.x,directionAndSpeed.y,-directionAndSpeed.y,directionAndSpeed.x);
                float2 retUv  = mul(rotate,uv);
                retUv.y -= time * directionAndSpeed.z;
                return retUv;
                
            }

            float3 UnpackDerivativeHeight (float4 textureData)
            {
			    float3 dh = textureData.agb;
			    dh.xy = dh.xy * 2 - 1;
			    return dh;
		    }
            

            float3 FlowCell (float2 uv, float2 offset, float time)
            {
                float2 shift = 1 - offset;
		        shift *= 0.5;
		        offset *= 0.5;
			    float2 uvTiled =
				(floor(uv * _GridResolution + offset) + shift) / _GridResolution;
                //float2 uvTiled = floor(uv * _GridResolution + offset)/_GridResolution; 
                //float4 flowDirection = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uvTiled);
                float4 flowDirection = SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,uv);
                flowDirection.z *= _FlowStrength;
                float2x2 rotate;    // 用于旋转法线
                float2 uvMain = DirectionalFlowUV(uv,flowDirection,time,rotate);
                float3 dh = UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvMain));
                dh.xy = mul(rotate,dh.xy);
                // dh *= flowDirection.z * _HeightScaleModulated + _HeightScale;
                return dh;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float time = _Time.y * _Speed;
			    float3 dhA = FlowCell(input.uv, float2(0, 0), time);
			    float3 dhB = FlowCell(input.uv, float2(1, 0), time);
			    float3 dhC = FlowCell(input.uv, float2(0, 1), time);
			    float3 dhD = FlowCell(input.uv, float2(1, 1), time);

			    float2 t = abs(2 * frac(input.uv * _GridResolution) - 1);
			    float wA = (1 - t.x) * (1 - t.y);
			    float wB = t.x * (1 - t.y);
			    float wC = (1 - t.x) * t.y;
			    float wD = t.x * t.y;

			    //float3 dh = dhA * wA + dhB * wB + dhC * wC + dhD * wD;
                float3 dh = dhA;
                
                // 计算法线
                float3 normalTS = normalize(float3(dh.xy * _NormalScale,1));
                //float3 normalTS = normalize(float3(dh.xy,1));
                float3x3 TS2WS = CreateTangentToWorld(input.normalWS,input.tangentWS.xyz,input.tangentWS.w);
                float3 normalWS = normalize(TransformTangentToWorld(normalTS,TS2WS));
                normalWS.z = -normalWS.z;
                Light light = GetMainLight();
                float LON = saturate(dot(light.direction,normalWS));

                // 计算反射
                float3 viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3 rl = normalize(reflect(viewDirection,normalWS));
                half3 rlColor = SAMPLE_TEXTURECUBE(_Environment,sampler_Environment,rl);
                float f0 = 0.04;
                float fresnel = f0 + (1 - f0)*pow(1 - max(0.00001,dot(viewDirection,normalWS)),5);
                //half3 color = lerp(rlColor,dh.z * dh.z * _Color.xyz,fresnel);
                half3 color = lerp(_Color,rlColor,0);
                #ifdef _Test
                color = color * LON * light.color*light.distanceAttenuation;
                #else
                color = dh.z*dh.z*_Color;
                #endif
                return float4(color,1);
                //return float4(dh.z * dh.z * _Color);
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

