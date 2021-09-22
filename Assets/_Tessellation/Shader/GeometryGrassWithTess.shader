Shader "URPPractice/GrassWithTess"
{
    Properties
    {
        [Header(shading)]
        _TopColor ("Top Color", Color) = (1,1,1,1)
        _BottomColor ("Bottom Color", Color) = (1,1,1,1)
        _TranslucentGain("Translucent Gain",Range(0,1)) = 0.05
        _BladeWidth ("Blade Width",float) = 0.05
        _BladeWidthRandom ("Blade Width Random",float) = 0.02
        _BladeHeight ("Blade Height",float) = 0.5
        _BladeHeightRandom ("Blade Height Random",float) = 0.3
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency ("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", float) = 1
        _TessellationUniforn("Tessellation Uniform", Range(1, 64)) = 1
        _BendRotationRandom("Bend Rotation Random", Range(0,1)) = 0.2
        _BladeForward("B1ade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1,4)) = 2  
    }
    
    CGINCLUDE
    #include "UnityCG.cginc"
    #include "Lighting.cginc"
    #include "Autolight.cginc"

    #define BLADE_SEGMENT 3


    // Simple noise function,sourced from http://answers.unity.com/answers/524136/view.html
    // https://forum.unity.com/threads/am-i-over-complication-this-random-function.454887/#post-2949326
    // return a number in the 0...1 range
    float rand(float3 co)
    {
        return frac(sin(dot(co.xyz,float3(12.9898,78.233,53.539))) * 43758.5453);
    }
    
    // Construct a rotation matrix that rotates around the provided axis,sourced from:
    // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
    float3x3 AngleAxis3x3(float angle, float3 axis)//旋转矩阵
    {
        float c,s;

        sincos(angle,s,c);

        float t = 1 - c;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        return float3x3(
        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c
        );
    }
    float _BladeHeight;
    float _BladeHeightRandom;
    float _BladeWidth;
    float _BladeWidthRandom;
    sampler2D _WindDistortionMap;
    float4 _WindDistortionMap_ST;
    float _WindStength;
    float3 _WindFrequency;
    float _BendRotationRandom;
    float _BladeForward;
    float _BladeCurve;

    struct geometryOutput
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    struct vertexInput
    {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
    };

    struct vertexOutput
    {
        float3 normal : NORMAL;
        float4 vertex : SV_POSITION;
        float4 tangent : TANGENT;
    };

    geometryOutput CreateGeoOutput(float3 pos,float2 uv)// 用于空间转换的函数
    {
        geometryOutput o;
        o.pos = UnityObjectToClipPos(pos);
        o.uv = uv;
        return o;
    }

    geometryOutput GenerateGrassVertex(float3 vertexPosition,float width,float height,
        float forword,float2 uv,float3x3 transformMatrix)
    {
        float3 rangentPoint = float3(width,forword,height);
        float3 localPosition = vertexPosition + mul(transformMatrix,rangentPoint);
        return CreateGeoOutput(localPosition,uv);
    }

    [maxvertexcount(BLADE_SEGMENT * 2 + 1)]//定义最大输出点，此处输出三角形所以是3
    //输出使用了TriangleStream，每个顶点都用到了结构体geometryOutput
    void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
    {
        //抛弃顶点本身位置信息的影响，所以采用切线空间，类比法线
        float3 pos = IN[0].vertex;
        float3 vNormal = IN[0].normal;
        float4 vTangent = IN[0].tangent;
        float3 vBitangent = cross(vNormal,vTangent) * vTangent.w;

        float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
        float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
        float forward = rand(pos.yyz) * _BladeForward;

        // Wind
        float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw +
            _WindFrequency * _Time.y;
        float2 windSample = (tex2Dlod(_WindDistortionMap,float4(uv,0,0)).xy * 2 -1) * _WindStength;
        float3 wind = normalize(float3(windSample.x,windSample.y,0));
        float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample,wind);

        // 构建矩阵
        // 朝向矩阵
        float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI,float3(0,0,1));

        // 向前弯曲矩阵
        float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom *
            UNITY_PI * 0.5,float3(-1,0,0));
        
        float3x3 tangentToLocal = float3x3(
        vTangent.x,vBitangent.x,vNormal.x,
        vTangent.y,vBitangent.y,vNormal.y,
        vTangent.z,vBitangent.z,vNormal.z
        );
        float3x3 transformationMat =mul(mul(mul(tangentToLocal,windRotation),facingRotationMatrix),bendRotationMatrix);

        float3x3 transformationMatrixFacing = mul(tangentToLocal,facingRotationMatrix);

        geometryOutput o;
        // triStream.Append(CreateGeoOutput(pos + mul(transformationMat,float3(width,0,0)),float2(0,0)));
        // triStream.Append(CreateGeoOutput(pos + mul(transformationMat,float3(-width,0,0)),float2(1,0)));
        // triStream.Append(CreateGeoOutput(pos + mul(transformationMat,float3(0,0,height)),float2(0.5,1)));
        for(int i = 0;i<BLADE_SEGMENT;i++)
        {
            float t = i/(float)BLADE_SEGMENT;
            float segmentHeight = height *t;
            float segmentWidth = width * (1-t);
            float segmentForward = pow(t,_BladeCurve) * forward;
            float3x3 transformMaxtrix = i==0?transformationMatrixFacing : transformationMat;
            triStream.Append(GenerateGrassVertex(pos,segmentWidth,segmentHeight,segmentForward,
                float2(0,t),transformMaxtrix));
            triStream.Append(GenerateGrassVertex(pos,-segmentWidth,segmentHeight,segmentForward,
                float2(1,t),transformMaxtrix));
        }
        triStream.Append(GenerateGrassVertex(pos,0,height,forward,
                float2(0.5,1),transformationMat));
    }
    ENDCG
        


    SubShader
    {
        Cull Off

        Pass
        {
            Tags
            {
                "RenderType" = "Opaque"
                // "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex tessvert
            #pragma hull hullProgram
            #pragma domain ds
            #pragma geometry geo
            #pragma fragment frag
            #pragma target 4.6

            #include "Lighting.cginc" 

            float4 _TopColor;
            float4 _BottomColor;
            float _TranslucentGain;
           
            fixed4 frag (geometryOutput i,fixed facing : VFACE) : SV_Target
            {
                return lerp(_BottomColor,_TopColor,i.uv.y);
            }
            ENDCG
        }
    }
}

