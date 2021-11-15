Shader "BlackShader/Shader_BackgroundAnimation"
{
    Properties
    {
        _MainTex1("Texture", 2D) = "white" {}
        _MainTex2("Texture",2D)="white"{}
        _Speed1("Speed1",Range(0,1)) = 0.5
        _Speed2("Speed2",Range(0,1))=0.5
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
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex1;
            float4 _MainTex1_ST;
            sampler2D _MainTex2;
            float4 _MainTex2_ST;
            fixed _Speed1;
            fixed _Speed2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex1) + frac(float2(_Speed1, 0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.uv, _MainTex2) + frac(float2(_Speed2, 0) * _Time.y);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {

                float4 col1 = tex2D(_MainTex1, i.uv.xy);
                float4 col2 = tex2D(_MainTex2, i.uv.zw);
                fixed4 col = lerp(col1, col2, col2.a);
                return col;
            }
            ENDCG
        }
    }
}
