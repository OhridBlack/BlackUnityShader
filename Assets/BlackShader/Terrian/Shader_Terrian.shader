Shader "Unlit/Shader_Terrian"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HighestStep("Highest Step",Float)=1.0
        _LowestStep("Lowest Step",Float)=0.0
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
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float height : TEXCOORD1;
                float3 normal:NORMAL;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HighestStep;
            float _LowestStep;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.height = v.vertex.y;
                o.normal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 col;
                // sample the texture
                if (i.height > _HighestStep) {
                    col = fixed3(1.0,1.0,1.0);
                }
                else if (i.height > _LowestStep) {
                    col = fixed3(0.0, 1.0, 0.0);
                }
                else {
                    col = fixed3(0.0,0.0,1.0);
                }

                fixed3 normal = normalize(i.normal);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed lambert = max(0.0, dot(normal, -lightDir));

                fixed shadow = SHADOW_ATTENUATION(i);

                return fixed4(col*lambert*shadow,1.0);
            }
            ENDCG
        }
    }
}
