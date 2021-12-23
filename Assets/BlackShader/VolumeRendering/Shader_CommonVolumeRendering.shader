Shader "BlackShader/Shader_CommonVolumeRendering"
{
    Properties
    {
        _Volume ("Volume", 3D) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler3D _Volume;

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

            v2f vert (appdata v)
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
                    float4 src = float4(v, v, v, v);
                    src.a *= 0.5;
                    src.rgb *= src.a;

                    dst = (1.0 - dst.a) * src + dst;
                    p += ds;

                }
                return saturate(dst);
            }
            ENDCG
        }
    }
}
