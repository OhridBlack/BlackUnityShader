Shader "BlackShader/Shader_RampTexture"
{
    Properties
    {
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256.0)) = 32.0
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
                #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            float _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 worldPos: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _RampTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                //use halfLambert[0,1] to be uv
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                fixed3 diffuse = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb * _LightColor0.rgb;

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(viewDir + worldLightDir);

                fixed3 specular = _LightColor0.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //return fixed4(ambient+diffuse+specular,1.0);
                return fixed4(diffuse, 1.0);
            }
            ENDCG
        }
    }
}
