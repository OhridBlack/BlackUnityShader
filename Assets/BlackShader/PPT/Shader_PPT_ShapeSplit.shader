Shader "BlackShader/Shader_PPT_ShappeSplit"
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
                    float alpha;
                    /*float low = 1 / _MiddleWeight * sqrt((uv.x - 0.5) * (uv.x - 0.5) + (uv.y - 0.5) * (uv.y - 0.5)) + 1;
                    float high = 1 / _MiddleWeight * sqrt((uv.x - 0.5) * (uv.x - 0.5) + (uv.y - 0.5) * (uv.y - 0.5)) - 1 / (2 * 1.414 * _MiddleWeight);
                    //shape of circle
                    */

                    float low = 1 / _MiddleWeight * abs(abs(uv.x - 0.5) + abs(uv.y - 0.5)) + 1;
                    float high = 1 / _MiddleWeight * abs(abs(uv.x - 0.5) + abs(uv.y - 0.5)) + 1 - 1 / _MiddleWeight;
                    //shape of rhombus
                    
                    alpha = clamp(low + threshold * (high - low), 0.0, 1.0);
                    return lerp(col1, col2, alpha);
                }
                ENDCG
            }
        }
}
