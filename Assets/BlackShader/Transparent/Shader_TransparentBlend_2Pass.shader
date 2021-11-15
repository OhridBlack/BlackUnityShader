Shader "BlackShader/Shader_TransparentBlend_2Pass"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _AlphaScale("Alpha Scale",Range(0,1)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }
            LOD 100

            Pass{
            //z buffer to get the nearest fragment
                ZWrite On
            //ColorMask 0:not to write any color channel but to get the z buffer
                ColorMask 0
            }

            Pass
            {
            //blend the nearest transparent fragment with the destination color
                ZWrite off
                Blend SrcAlpha OneMinusSrcAlpha

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "UnityCG.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _AlphaScale;


                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float3 normal : TEXCOORD1;
                    float3 pos : TEXCOORD2;
                    float4 vertex : SV_POSITION;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    o.normal = UnityObjectToWorldNormal(v.normal);
                    return o;
                }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 normal = normalize(i.normal);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.pos));
                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(normal, lightDir));
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
        }
}
