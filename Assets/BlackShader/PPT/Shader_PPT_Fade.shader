Shader "BlackShader/Shader_PPT_Fade"
{
    Properties
    {
        _MainTex ("Texture 1", 2D) = "white" {}
        _MainTex2("Texture 2",2D)="black"{}
        _Ratio("Fade Ratio",Range(0.0,1.0))=0.5
        [Toggle]
        _UseTime("Use Time",Float)=1.0
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MainTex2;
            float _Ratio;
            float _UseTime;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col1 = tex2D(_MainTex,i.uv);
                fixed4 col2 = tex2D(_MainTex2, i.uv);
                float r;
                if (_UseTime) {
                    r = sin(_Time.y);
                }
                else {
                    r = _Ratio;
                }
                return lerp(col1, col2, r);
            }
            ENDCG
        }
    }
}
