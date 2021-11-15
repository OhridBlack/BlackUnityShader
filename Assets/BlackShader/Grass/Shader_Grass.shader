Shader "BlackShader/Shader_Grass"
{
    Properties
    {
        _TopColor("TopColor",Color) = (0.0,1.0,0.0,1.0)
        _BottomColor("BottomColor",Color)=(0.0,0.5,0.0,1.0)
        _TranslucentGain("Translucent Gain",Range(0,1))=0.5

        _BendRotationrRandom("Bend Rotation Random",Range(0,1))=0.2
        _BladeWidth("Blade Width",Float)=0.05
        _BladeWidthRandom("Blade Width Random",Float)=0.02
        _BladeHeight("Blade Height",Float)=0.5
        _BladeHeightRandom("Blade Height Random",Float)=0.3
        _BladeForward("Blade Forward",Float)=0.38
        _BladeCurve("Blade Curvature",Range(1,4))=2
        _TessellationUniform("Tessellation Uniform",Range(1,64))=1

        _WindDistortionMap("Wind Distortion Map",2D)="white"{}
        _WindFrequency("Wind Frequency",Vector)=(0.05,0.05,0,0)
        _WindStrength("Wind Strength",Float)=1
    }

    CGINCLUDE
#include "UnityCG.cginc"
#include "CustomTessellation.cginc"
#include "AutoLight.cginc"
#define BLADE_SEGMENTS 3

            struct appdata
        {
            float4 vertex : POSITION;
            float3 normal:NORMAL;
            float4 tangent:TANGENT;
        };

        struct v2g {
            float4 vertex:SV_POSITION;
            float3 normal:NORMAL;
            float4 tangent:TANGENT;

        };

        struct g2f {
            float4 pos:SV_POSITION;
            float3 normal:NORMAL;
            float2 uv:TEXCOORD0;
            unityShadowCoord4 _ShadowCoord : TEXCOORD1;
        };

        float rand(float3 co) {
            return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
        }

        float3x3 AngleAxis3x3(float angle, float3 axis) {
            float c, s;
            sincos(angle, s, c);
            float t = 1 - c;
            float x = axis.x;
            float y = axis.y;
            float z = axis.z;
            return float3x3(t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                t * x * z - s * y, t * y * z + s * x, t * z * z + c);
        }

        g2f vo(float3 pos,float3 normal, float2 uv) {
            g2f o;
            o.pos = UnityObjectToClipPos(pos);
            o.normal = UnityObjectToWorldNormal(normal);
            o.uv = uv;
            o._ShadowCoord = ComputeScreenPos(o.pos);
            return o;
        }

        g2f generateGrassVertex(float3 vertexPos, float width, float height, float forward, float2 uv, float3x3 transformMatrix) {
            float3 tangentPoint = float3(width, forward, height);
            float3 tangentNormal = normalize(float3(0, -1, forward));
            float3 localPos = vertexPos + mul(transformMatrix, tangentPoint);
            float3 localNormal = mul(transformMatrix, tangentNormal);
            return vo(localPos, localNormal, uv);
        }

        float4 _TopColor;
        float4 _BottomColor;
        float _BendRotationRandom;
        float _BladeHeight;
        float _BladeWidth;
        float _BladeHeightRandom;
        float _BladeWidthRandom;
        float _BladeForward;
        float _BladeCurve;

        sampler2D _WindDistortionMap;
        float4 _WindDistortionMap_ST;
        float2 _WindFrequency;
        float _WindStrength;

        [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
        void geo(triangle v2g input[3]:SV_POSITION, inout TriangleStream<g2f>triStream) {
            float3 pos = input[0].vertex.xyz;
            float3 vNormal = input[0].normal;
            float4 vTangent = input[0].tangent;
            float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;
            float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;

            float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
            float3 wind = normalize(float3(windSample.x, windSample.y, 0));
            float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

            float3x3 tangentToLocal = float3x3(vTangent.x, vBinormal.x, vNormal.x,
                vTangent.y, vBinormal.y, vNormal.y,
                vTangent.z, vBinormal.z, vNormal.z);

            float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
            float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
            float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, facingRotationMatrix), bendRotationMatrix), windRotation);
            float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);


            float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
            float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
            float forward = rand(pos.yyz) * _BladeForward;

            for (int i = 0; i < BLADE_SEGMENTS; ++i) {
                float t = i / (float)BLADE_SEGMENTS;

                float segmentHeight = height * t;
                float segmentWidth = width * (1 - t);
                float segementForward = pow(t, _BladeCurve) * forward;

                float3x3 tm = i == 0 ? transformationMatrixFacing : transformationMatrix;

                triStream.Append(generateGrassVertex(pos, segmentWidth, segmentHeight, segementForward, float2(0, t), tm));
                triStream.Append(generateGrassVertex(pos, -segmentWidth, segmentHeight, segementForward, float2(1, t), tm));
            }

            triStream.Append(generateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMatrix));
        }

        ENDCG

            SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100


            Cull Off
            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma hull hull
                #pragma domain domain
                #pragma geometry geo
                #pragma fragment frag
                #pragma multi_compile_fwdbase
                #include "Lighting.cginc"
                

                float _TranslucentGain;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }

            fixed4 frag(g2f i, fixed facing : VFACE) : SV_Target
            {
                float3 normal = facing > 0 ? i.normal : -i.normal;
                float shadow = SHADOW_ATTENUATION(i);
                float NdotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0) + _TranslucentGain)) * shadow;
                float3 ambient = ShadeSH9(float4(normal, 1));
                float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
                return lerp(_BottomColor, _TopColor*lightIntensity, i.uv.y);
            }
            ENDCG
        }

        Pass{
                Tags{
                    "LightMode" = "ShadowCaster"
                }
                CGPROGRAM
                #pragma vertex vert
                #pragma hull hull
                #pragma domain domain
                #pragma geometry geo
                #pragma fragment frag
                #pragma multi_compile_shadowcaster

                float4 frag(g2f i) :SV_Target{
                    SHADOW_CASTER_FRAGMENT(i);
                }
                ENDCG
        }
    }
}
