Shader "URPPractice/TessellationDisplace"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
        _DisplacementMap("_DisplacementMap",2D)="gray"{}
        _DisplacementStrength("DisplacementStrength",Range(0,1)) = 0
        _Smoothness("Smoothness",Range(0,5))=0.5
        _TessellationUniform("TessellationUniform",Range(1,64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 
               /*"LightMode"="ForwardBase"*/}
        LOD 100
        Pass
        {
            CGPROGRAM
            //定义2个函数 hull domain
            //#pragma hull hullProgram
            //#pragma domain ds
           
            #pragma vertex vert
            #pragma fragment frag

            // #include "UnityCG.cginc"
            #include "Lighting.cginc"
            //引入曲面细分的头文件
            //#include "Tessellation.cginc" 

            #pragma target 5.0
            float _TessellationUniform;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DisplacementMap;
            float4 _DisplacementMap_ST;
            float _DisplacementStrength;
            float _Smoothness;

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                half3 tspace0 :TEXCOORD2;
                half3 tspace1 :TEXCOORD3;
                half3 tspace2 :TEXCOORD4;
            };

            VertexOutput vert (VertexInput v)
            //这个函数应用在domain函数中，用来空间转换的函数
            {
                VertexOutput o;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                //Displacement
                //由于并不是在Fragnent shader中读取图片，GPU无法获取mipmap信息，因此需要使用tex2Dlod来读取图片，使用第四坐标作为mipmap的level，这里取了0
                float Displacement = tex2Dlod(_DisplacementMap,float4(o.uv.xy,0.0,0.0)).g;
                // float Displacement = 1;
                // Displacement =  -UnpackNormal(tex2Dlod(_DisplacementMap,float4(o.uv.xy,0.0,0.0)).b);
                Displacement = (Displacement-0.5)*_DisplacementStrength;
                v.normal = normalize(v.normal);
                v.vertex.xyz += v.normal * Displacement;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                //计算切线空间转换矩阵
                half3 vNormal = UnityObjectToWorldNormal(v.normal);
                half3 vTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //compute bitangent from cross product of normal and tangent
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 vBitangent = cross(vNormal,vTangent)*tangentSign;
                //output the tangent space matrix
                o.tspace0 = half3(vTangent.x,vBitangent.x,vNormal.x);
                o.tspace1 = half3(vTangent.y,vBitangent.y,vNormal.y);
                o.tspace2 = half3(vTangent.z,vBitangent.z,vNormal.z);
                return o;
            }

            inline fixed3 UnpackNormalDXT5nm1 (fixed4 packednormal)
            {
                fixed3 normal;
                normal.xy = packednormal.wy * 2 - 1;
                normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
                return normal;
            }

            // Unpack normal as DXT5nm (1, y, 1, x) or BC5 (x, y, 0, 1)
            // Note neutral texture like "bump" is (0, 0, 1, 1) to work with both plain RGB normal and DXT5nm/BC5
            fixed3 UnpackNormalmapRGorAG1(fixed4 packednormal)
            {
                // This do the trick
               packednormal.x *= packednormal.w;

                fixed3 normal;
                normal.xy = packednormal.xy * 2 - 1;
                normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
                return normal;
            }
            inline fixed3 UnpackNormal1(fixed4 packednormal)
            {
            #if  defined(UNITY_NO_DXT5nm)
                return packednormal.xyz * 2 - 1;
            #elif defined(UNITY_ASTC_NORMALMAP_ENCODING)
                return UnpackNormalDXT5nm1(packednormal);
            #else
                return UnpackNormalmapRGorAG1(packednormal);
            #endif
            }


            float4 frag (VertexOutput i) : SV_Target
            {
                float3 lightDir =_WorldSpaceLightPos0.xyz;
                //float3 tnormal = UnpackNormal (tex2D (_DisplacementMap, i.uv));
                float3 tnormal = half3(0,0,1);
                half3 worldNormal;
                worldNormal.x=dot(i.tspace0,tnormal);
                worldNormal.y= dot (i.tspace1, tnormal);
                worldNormal.z=dot (i.tspace2, tnormal);
                float3 albedo=tex2D (_MainTex, i.uv). rgb;
                float3 lightColor = _LightColor0.rgb;
                float3 diffuse = albedo * lightColor * DotClamped(lightDir,worldNormal);
                float3 viewDir = normalize (_WorldSpaceCameraPos. xyz-i. worldPos. xyz);
                float3 halfVector = normalize(lightDir + viewDir);
                float3 specular = albedo * pow (DotClamped (halfVector, worldNormal), _Smoothness * 100);
                float3 result = specular + diffuse;

                float2 Displacement = tex2Dlod(_DisplacementMap,float4(i.uv.xy,0.0,0.0)).rg;
                Displacement = Displacement * 2 - 1; 
                float h = sqrt(1 - saturate(dot(Displacement.xy,Displacement.xy)));
                // float h = UnpackNormal1(Displacement).g;
                
                // float Displacement = 1;
                //Displacement =  UnpackNormal(tex2Dlod(_DisplacementMap,float4(i.uv.xy,0.0,0.0)).b);
                //Displacement =  UnpackNormal(tex2Dlod(_DisplacementMap,float4(i.uv.xy,0.0,0.0)).b);
                Displacement = (Displacement-0.5)*1;
                return float4(h.xxx, 1.0);

                return float4(result,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}