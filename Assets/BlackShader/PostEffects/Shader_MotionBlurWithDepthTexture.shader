Shader "BlackShader/Shader_MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("Blur Size",Float)=1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
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
                float2 uv_depth:TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _MainTex_TexelSize;
            sampler2D _CameraDepthTexture;
            float4x4 _CurrentViewProjectionInverseMatrix;
            float4x4 _PreviousViewProjectionMatrix;
            half _BlurSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv_depth = o.uv;

#if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0) {
                    o.uv_depth.y = 1 - o.uv_depth.y;
                }
#endif
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
                float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
                float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
                float4 worldPos = D / D.w;

                float4 currentPos = H;
                float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
                previousPos /= previousPos.w;

                float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;
                
                float2 uv = i.uv;
                float4 c = tex2D(_MainTex, uv);
                uv += velocity * _BlurSize;
                for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
                    float4 currentColor = tex2D(_MainTex, uv);
                    c += currentColor;
                }
                c /= 3;
                return fixed4(c.rgb, 1.0);
            }
            ENDCG
        }
    }
}
