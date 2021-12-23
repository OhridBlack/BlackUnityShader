Shader "BlackShader/Shader_TransferFunctionVolumeRendering"
{
    Properties
    {
        _Volume("Volume", 3D) = "" {}
        //_TransferFunctionTex("Transfer Function Texture",2D)=""{}
        _TransferStep1("Transfer Step1",Range(0.4,1.0))=0.5
        _TransferStep2("Transfer Step2",Range(0.25,0.4))=0.3
        _TransferStep3("Transfer Step3",Range(0.0,0.25))=0.1
    }
        SubShader
    {
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Transparent" }
        LOD 100
        Blend One OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler3D _Volume;
        float _TransferStep1;
        float _TransferStep2;
        float _TransferStep3;

            struct Ray {
                float3 origin;
                float3 dir;
            };

            struct AABB {
                float3 min;
                float3 max;
            };

            bool intersect(Ray r, AABB aabb, out float t0, out float t1) {
                float3 invR = 1.0 / r.dir;
                float3 tbot = invR * (aabb.min - r.origin);
                float3 ttop = invR * (aabb.max - r.origin);
                float3 tmin = min(ttop, tbot);
                float3 tmax = max(ttop, tbot);
                float2 t = max(tmin.xx, tmin.yz);
                t0 = max(t.x, t.y);
                t = min(tmax.xx, tmax.yz);
                t1 = min(t.x, t.y);
                return t0 <= t1;
            }

            float3 get_uv(float3 p) {
                return p + 0.5;
            }

            float sample_volume(float3 uv) {
                float v = tex3D(_Volume, uv).r;
                return v;
            }

            float4 sample_tex(float v) {
                if (v >= _TransferStep1)return float4(0.0f, 1.0f, 0.0f, 1.0f);
                if (v >= _TransferStep2)return float4(0.0f, 0.6f, 0.6f, 0.8f);
                if (v >= _TransferStep3)return float4(0.2f, 0.4f, 0.0f, 0.2f);
                return float4(0.0f, 0.0f, 0.0f, 0.0f);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 world:TEXCOORD1;
                float3 local:TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.local = v.vertex.xyz;
                return o;
            }
#define ITERATIONS 100
            fixed4 frag(v2f i) : SV_Target
            {
                Ray ray;
                ray.origin = i.local;
                float3 dir = (i.world - _WorldSpaceCameraPos);
                ray.dir = normalize(mul(unity_WorldToObject, dir));

                AABB aabb;
                aabb.min = float3(-0.5, -0.5, -0.5);
                aabb.max = float3(0.5, 0.5, 0.5);

                float tnear;
                float tfar;
                intersect(ray, aabb, tnear, tfar);

                tnear = max(0.0, tnear);

                float3 start = ray.origin;
                float3 end = ray.origin + ray.dir * tfar;
                float dist = abs(tfar - tnear);
                float step_size = dist / float(ITERATIONS);
                float3 ds = normalize(end - start) * step_size;

                float4 dst = float4(0, 0, 0, 0);
                float3 p = start;

                [unroll]
                for (int iter = 0; iter < ITERATIONS; iter++) {
                    float3 uv = get_uv(p);
                    float v = sample_volume(uv);
                    float4 src = sample_tex(v);
                    
                    dst.rgb = src.a * src.rgb + (1.0f - src.a) * dst.rgb;
                    dst.a = src.a + (1.0f - src.a) * dst.a;
                    if (dst.a > 1)break;
                    p += ds;

                }
                return saturate(dst);
            }
            ENDCG
        }
    }
}
