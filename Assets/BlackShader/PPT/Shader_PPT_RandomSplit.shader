Shader "BlackShader/Shader_PPT_RandomSplit"
{
    Properties
    {
        _MainTex("Texture 1", 2D) = "white" {}
        _MainTex2("Texture 2",2D) = "black"{}
        _SpeedRatio("Speed Ratio",Range(0.0,1.0)) = 0.5
        _MiddleWeight("Middle Weight",Range(0.1,1.0)) = 0.1
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _MainTex2;
                float _SpeedRatio;
                float _MiddleWeight;

                float random(int seed) {
                    return frac(sin(seed) * 1000000);
                }

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float threshold = sin(_Time.y * _SpeedRatio);
                    fixed4 col1 = tex2D(_MainTex, i.uv);
                    fixed4 col2 = tex2D(_MainTex2, i.uv);
                    float2 uv = i.uv;

                    float alpha=1.0;
                    for (int i = 0; i < 20; ++i) {
                        float pos = random(i);
                        float low = abs(uv.x/ _MiddleWeight - (pos/_MiddleWeight)) + 1.0;
                        float high = ((-1 / 20 * 3) / _MiddleWeight - 1.0);
                        alpha = min(alpha,clamp(low + threshold * high, 0.0, 1.0));
                    }
                    return lerp(col1, col2, alpha);
                }
                ENDCG
            }
        }
}
