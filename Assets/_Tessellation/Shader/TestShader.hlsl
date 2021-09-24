#ifndef TESTSHADER_INCLUDED
#define TESTSHADER_INCLUDED
 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Lighting.cginc"
 
#define UNITY_MATRIX_TEXTURE0 float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
 
 
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};
 
struct v2g
{
    float4 objPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD3;
    float3 worldPos : TEXCOORD2;
};
 
struct g2f
{
    float4 worldPos : SV_POSITION;
    float2 uv : TEXCOORD0;
    half4 color : TEXCOORD4;
    float3 normal : TEXCOORD3;
};
 
sampler2D _MainTex;
float4 _MainTex_ST;
float4 _Color;
float4 _AmbientColor;
sampler2D _BumpMap;
float _BumpStr;
float _Metallic;
 
sampler2D _FlowMap;
float4 _FlowMap_ST;
sampler2D _DissolveTexture;
float4 _DissolveColor;
float _DissolveBorder;
 
 
float _Exapnd;
float _Weight;
float4 _Direction;
float4 _DisintegrationColor;
float _Glow;
sampler2D _Shape;
float _R;
 
 
float remap(float value, float from1, float to1, float from2, float to2)
{
    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}
 
float4 remapFlowTexture(float4 tex)
{
    return float4(
        remap(tex.x, 0, 1, -1, 1),
        remap(tex.y, 0, 1, -1, 1),
        0,
        remap(tex.w, 0, 1, -1, 1)
    );
}
 
float2 MultiplyUV (float4x4 mat, float2 inUV) {
    float4 temp = float4 (inUV.x, inUV.y, 0, 0);
    temp = mul (mat, temp);
    return temp.xy;
}
 
 
v2g vert(appdata v)
{
    v2g o = (v2g)0;
 
    o.objPos = v.vertex;
    o.uv = v.uv;
    o.normal = TransformObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    return o;
}
 
[maxvertexcount(7)]
void geom(triangle v2g inputs[3], inout TriangleStream<g2f> triStream)
{
    float2 avgUV = (inputs[0].uv + inputs[1].uv + inputs[2].uv) / 3;
    float3 avgPos = (inputs[0].objPos + inputs[1].objPos + inputs[2].objPos) / 3;
    float3 avgNormal = (inputs[0].normal + inputs[1].normal + inputs[2].normal) / 3;
 
    float dissolve_value = tex2Dlod(_DissolveTexture, float4(avgUV, 0, 0)).r;
    float t = clamp(_Weight * 2 - dissolve_value, 0, 1);
 
    float2 flowUV = TRANSFORM_TEX(mul(unity_ObjectToWorld, avgPos).xz, _FlowMap);
    float4 flowVector = remapFlowTexture(tex2Dlod(_FlowMap, float4(flowUV, 0, 0)));
 
    float3 pseudoRandomPos = (avgPos) + _Direction;
    pseudoRandomPos += (flowVector.xyz * _Exapnd);
 
    float3 p = lerp(avgPos, pseudoRandomPos, t);
    float radius = lerp(_R, 0, t);
 
 
    if (t > 0)
    {
        float3 look = _WorldSpaceCameraPos - p;
        look = normalize(look);
 
        float3 right = UNITY_MATRIX_IT_MV[0].xyz;
        float3 up = UNITY_MATRIX_IT_MV[1].xyz;
 
        float halfS = 0.5f * radius;
 
        float4 v[4];
        v[0] = float4(p + halfS * right - halfS * up, 1.0f);
        v[1] = float4(p + halfS * right + halfS * up, 1.0f);
        v[2] = float4(p - halfS * right - halfS * up, 1.0f);
        v[3] = float4(p - halfS * right + halfS * up, 1.0f);
 
 
        g2f vert;
        vert.worldPos = TransformObjectToHClip(v[0]);
        vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 0.0f));
        vert.color = float4(1, 1, 1, 1);
        vert.normal = avgNormal;
        triStream.Append(vert);
 
        vert.worldPos = TransformObjectToHClip(v[1]);
        vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 1.0f));
        vert.color = float4(1, 1, 1, 1);
        vert.normal = avgNormal;
        triStream.Append(vert);
 
        vert.worldPos = TransformObjectToHClip(v[2]);
        vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 0.0f));
        vert.color = float4(1, 1, 1, 1);
        vert.normal = avgNormal;
        triStream.Append(vert);
 
        vert.worldPos = TransformObjectToHClip(v[3]);
        vert.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 1.0f));
        vert.color = float4(1, 1, 1, 1);
        vert.normal = avgNormal;
        triStream.Append(vert);
 
        triStream.RestartStrip();
    }
 
    for (int j = 0; j < 3; j++)
    {
        g2f o;
        o.worldPos = TransformObjectToHClip(inputs[j].objPos);
        o.uv = TRANSFORM_TEX(inputs[j].uv, _MainTex);
        o.color = half4(0, 0, 0, 0);
        o.normal = inputs[j].normal;
        triStream.Append(o);
    }
 
    triStream.RestartStrip();
}
 
half4 frag(g2f i) : SV_Target
{
    half4 col = tex2D(_MainTex, i.uv) * _Color;
               
    float3 normal = normalize(i.normal);
    half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
    tnormal.xy *= _BumpStr;
    tnormal = normalize(tnormal);
 
    float NdotL = dot((float4)0, normal * tnormal);
    float4 light = NdotL * (half4)0;
    col *= (_AmbientColor + light);
             
    float brightness = i.color.w  * _Glow;
    col = lerp(col, _DisintegrationColor,  i.color.x);
 
    if(brightness > 0){
        col *= brightness + _Weight;
    }
 
 
    float dissolve = tex2D(_DissolveTexture, i.uv).r;
               
    if(i.color.w == 0){
        clip(dissolve - 2*_Weight);
        if(_Weight > 0){
            col +=  _DissolveColor * _Glow * step( dissolve - 2*_Weight, _DissolveBorder);
        }
    }else{
        float s = tex2D(_Shape, i.uv).r;
        if(s < .5) {
            discard;
        }
 
    }
 
    return col;
}
 
#endif