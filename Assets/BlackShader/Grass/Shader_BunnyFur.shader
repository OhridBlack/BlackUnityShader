Shader "BlackShader/Shader_BunnyFur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FurStrength("Fur Strength",Range(0,0.2))=0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g {
                float4 vertex:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _FurStrength;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            [maxvertexcount(9)]
            void geo(triangle v2g input[3], inout TriangleStream<g2f>triStream) {
                float3 edge1 = input[1].vertex - input[0].vertex;
                float3 edge2 = input[2].vertex - input[0].vertex;
                float3 normalFace = normalize(cross(edge1, edge2));

                float3 centerPos = (input[0].vertex + input[1].vertex + input[2].vertex) / 3;
                float4 centerPos_ = float4(centerPos, 0);
                float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3;

                centerPos += normalFace * _FurStrength;
                g2f o;
                for (int i = 0; i < 3; ++i) {
                    
                    float3 _edge1 = input[i].vertex - centerPos_;
                    float3 _edge2 = input[(i + 1) % 3].vertex - centerPos_;
                    float3 normal_ = UnityObjectToWorldNormal(normalize(cross(_edge1, _edge2)));


                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    o.uv = input[i].uv;
                    o.normal = normal_;
                    triStream.Append(o);

                    o.vertex = UnityObjectToClipPos(input[(i+1)%3].vertex);
                    o.uv = input[(i + 1) % 3].uv;
                    o.normal = normal_;
                    triStream.Append(o);

                    o.vertex = UnityObjectToClipPos(float4(centerPos, 1));
                    o.uv = centerUV;
                    o.normal = normal_;
                    triStream.Append(o);

                    triStream.RestartStrip();
                }
            }

            fixed4 frag(g2f i, fixed facing : VFACE) : SV_Target
            {
                float3 normal = facing > 0 ? i.normal : -i.normal;
                float3 ambient = ShadeSH9(float4(normal, 1));
                float NdotL = saturate((dot(normal, _WorldSpaceLightPos0)));
                float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
                fixed4 col = tex2D(_MainTex, i.uv)*lightIntensity;
                return col;
                //return tex2D(_MainTex,i.uv);
            }
            ENDCG
        }
    }
}
