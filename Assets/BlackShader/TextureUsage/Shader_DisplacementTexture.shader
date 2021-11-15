Shader "BlackShader/Shader_DisplacementTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisplacementTex("displacement Texture",2D)=""{}
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
                float3 normal :NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DisplacementTex;

            v2f vert (appdata v)
            {
                v2f o;
                fixed3 pos = mul(unity_ObjectToWorld,v.vertex);
                fixed3 dir = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                fixed height = tex2Dlod(_DisplacementTex, float4(v.uv,0,0)).r;
                pos += height * dir;
                o.vertex = mul(UNITY_MATRIX_VP, fixed4(pos, 1.0));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                return col;
            }
            ENDCG
        }
    }
}
