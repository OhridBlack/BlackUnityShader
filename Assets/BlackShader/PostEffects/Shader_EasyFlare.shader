Shader "BlackShader/Shader_EasyFlare"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold("Light Threshold",Color)=(0.0,0.0,0.0,1.0)
        _Intensity("Light Enhanced Intensity",Float)=2.0
        _GhostIterations("Ghost Iterations",Int)=2
        _GhostDispersal("Ghost Dispersal",Float)=0.5

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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[5] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half2 _MainTex_TexelSize;
            float4 _Threshold;
            float _Intensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex= UnityObjectToClipPos(v.vertex);
                o.uv[0] = UnityStereoScreenSpaceUVAdjust(v.uv, _MainTex_ST);
                o.uv[1] = UnityStereoScreenSpaceUVAdjust(v.uv + _MainTex_TexelSize * half2(1.0, 0.0), _MainTex_ST);
                o.uv[2] = UnityStereoScreenSpaceUVAdjust(v.uv + _MainTex_TexelSize * half2(0.0, 1.0), _MainTex_ST);
                o.uv[3] = UnityStereoScreenSpaceUVAdjust(v.uv + _MainTex_TexelSize * half2(-1.0, 0.0), _MainTex_ST);
                o.uv[4] = UnityStereoScreenSpaceUVAdjust(v.uv + _MainTex_TexelSize * half2(0.0, -1.0), _MainTex_ST);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 color = tex2D(_MainTex,i.uv[0]) + tex2D(_MainTex,i.uv[1]) + tex2D(_MainTex,i.uv[2]) + tex2D(_MainTex,i.uv[3]) + tex2D(_MainTex,i.uv[4]);
                return max(0.0, color / 5 - _Threshold) * _Intensity;
            }
            ENDCG
        }

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
                float4 vertex :SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GhostDispersal;
            int _GhostIterations;

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) :SV_Target{
                half2 newUV = half2 (1.0h, 1.0h) - i.uv;
                half2 ghostVector = (half2 (0.5h, 0.5h) - newUV) * _GhostDispersal;
                fixed4 finalColor = fixed4(0,0,0,0);
                for (int ii = 0; ii < _GhostIterations; ++ii) {
                    half2 offset = frac(newUV + ghostVector * float(ii));
                    float weight = length(half2 (0.5, 0.5) - offset) / length(half2 (0.5, 0.5));
                    weight = pow(1.0 - weight, 1.0);
                    finalColor += tex2D(_MainTex, offset) * weight;
                }
                return finalColor;
            }

            ENDCG
        }
    }
}
