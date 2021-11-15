Shader "BlackShader/Shader_PPT_PushOut"
{
    Properties
    {
        _MainTex("Texture 1", 2D) = "white" {}
        _MainTex2("Texture 2",2D) = "black"{}
        _SpeedRatio("Speed Ratio",Range(0.0,1.0)) = 0.5
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
                    if (i.uv.x >= threshold) {
                        col = tex2D(_MainTex, float2(i.uv.x - threshold, i.uv.y));
                    }
                    else {
                        col = tex2D(_MainTex2, float2(i.uv.x - threshold + 1.0, i.uv.y));
                    }
                    
                    
                    return col;
                }
                ENDCG
            }
        }
}
