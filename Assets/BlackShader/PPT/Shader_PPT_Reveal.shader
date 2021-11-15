Shader "BlackShader/Shader_PPT_Reveal"
{
    Properties
    {
        _MainTex("Texture 1", 2D) = "white" {}
        _MainTex2("Texture 2",2D) = "black"{}
        _SpeedRatio("Speed Ratio",Range(0.0,1.0)) = 0.5
        _MiddleWeight("Middle Weight",Range(0.1,1.0)) = 0.1
        _ScaleMax("Scale Max",Range(1.0,2.0))=1.5
        _ScaleMin("Scale Min",Range(0.1,1.0))=0.5
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
                float _ScaleMax;
                float _ScaleMin;

                float2 transform(float2 uv, float2 uvCenter, float scaleRatio) {
                    float2 uv_t = uv;
                    uv_t -= uvCenter;
                    uv_t *= scaleRatio;
                    uv_t += uvCenter;
                    return uv_t;
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
                    fixed4 col;
                    if (threshold <= 0.5) {
                        float t = threshold * 2.0;
                        float scaleRatio = _ScaleMax * t + 1;
                        fixed2 center = fixed2(0.75, 0.5);
                        fixed4 c = tex2D(_MainTex, transform(i.uv, center, scaleRatio));
                        float alpha = clamp(-1.0 / _MiddleWeight * i.uv.x + (1.0 + _MiddleWeight) / _MiddleWeight * (1.0 - t), 0.0, 1.0);
                        col = lerp(fixed4(1, 1, 1, 1), c, alpha);
                    }
                    else {
                        float t = (threshold-0.5) * 2.0;
                        float scaleRatio = _ScaleMin * t + 1;
                        fixed2 center = fixed2(0.25, 0.5);
                        fixed4 c = tex2D(_MainTex2, transform(i.uv, center, scaleRatio));
                        float alpha = 1.0-clamp(-1.0 / _MiddleWeight * i.uv.x + (1.0 + _MiddleWeight) / _MiddleWeight * t, 0.0, 1.0);
                        col = lerp(fixed4(1, 1, 1, 1), c, alpha);
                    }
                    
                    return col;
                }
                ENDCG
            }
        }
}
