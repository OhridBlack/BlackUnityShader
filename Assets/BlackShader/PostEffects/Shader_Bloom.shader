Shader "BlackShader/Shader_Bloom"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Bloom("Bloom",2D) = "" {}
        _BlurSize("Blur Size",Float) = 1.0
        _LuminanceThreshold("Luminance Threshold",Float)=0.5

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100
            ZTest Always
            Cull Off
            ZWrite Off

            Pass{
                NAME "HIGHLIGHT"
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
                half4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float _BlurSize;
                float _LuminanceThreshold;

                v2f vert(appdata v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }

                fixed luminance(fixed4 color) {
                    return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
                }

                fixed4 frag(v2f i) :SV_Target{
                    fixed4 c = tex2D(_MainTex,i.uv);
                    fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
                    return c * val;
                }

                ENDCG
            }

            Pass
            {
                NAME "GAUSSIAN_BLUR_VERTICAL"
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
                half4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float _BlurSize;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    float2 uv = TRANSFORM_TEX(v.uv, _MainTex);

                    o.uv[0] = uv;
                    o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
                    o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
                    o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
                    o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    const float weight[3] = {0.4026,0.2442,0.0545};
                    fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

                    for (int it = 1; it < 3; ++it) {
                        sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                        sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
                    }
                    return fixed4(sum,1.0);
                }
                ENDCG
            }

            Pass
            {
                NAME "GAUSSIAN_BLUR_HORIZONTAL"
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
                half4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float _BlurSize;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    float2 uv = TRANSFORM_TEX(v.uv, _MainTex);

                    o.uv[0] = uv;
                    o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0,0.0) * _BlurSize;
                    o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0,0.0) * _BlurSize;
                    o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0,0.0) * _BlurSize;
                    o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0,0.0) * _BlurSize;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    const float weight[3] = {0.4026,0.2442,0.0545};
                    fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

                    for (int it = 1; it < 3; ++it) {
                        sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                        sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
                    }
                    return fixed4(sum,1.0);
                }

            ENDCG
            }

            Pass{
                NAME "MIXBLOOM"
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
                    float4 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                sampler2D _MainTex;
                half4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float _BlurSize;
                sampler2D _Bloom;
                float4 _Bloom_ST;
                v2f vert(appdata v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.uv, _Bloom);
                    return o;
                }

                fixed4 frag(v2f i) :SV_Target{
                    return tex2D(_MainTex,i.uv.xy) + tex2D(_Bloom,i.uv.zw);
                }

                ENDCG
            }
        }
}
