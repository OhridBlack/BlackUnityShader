Shader "BlackShader/Shader_WaterSimulatingNoiseMap"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NoiseMap("Noise Map",2D) = ""{}
        _WaveXSpeed("Wave X Speed",Range(0.0,10.0)) = 0.5
        _WaveYSpeed("Wave Y Speed",Range(0.0,10.0)) = 0.5
        _Cubemap("CubeMap",Cube) = ""{}
        _Color("Color",Color) = (1,1,1,1)

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            GrabPass{
                "_RefractionTex"
            }
            Pass
                {
                    CGPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag

                    #include "UnityCG.cginc"
                    #include "Lighting.cginc"

                    struct appdata
                    {
                        float4 vertex : POSITION;
                        float2 uv : TEXCOORD0;
                        float3 normal :NORMAL;
                    };

                    struct v2f
                    {
                        float4 uv : TEXCOORD0;
                        float4 vertex : SV_POSITION;
                        float4 scrPos:TEXCOORD1;
                        float3 normal:TEXCOORD2;
                        float3 pos:TEXCOORD3;
                    };

                    sampler2D _MainTex;
                    float4 _MainTex_ST;
                    sampler2D _NoiseMap;
                    float4 _NoiseMap_ST;
                    float _WaveXSpeed;
                    float _WaveYSpeed;
                    sampler2D _RefractionTex;
                    half4 _RefractionTex_TexelSize;
                    samplerCUBE _Cubemap;
                    fixed4 _Color;

                    v2f vert(appdata v)
                    {
                        v2f o;
                        o.vertex = UnityObjectToClipPos(v.vertex);
                        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                        o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseMap);
                        o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                        o.scrPos = ComputeGrabScreenPos(o.vertex);
                        o.pos = mul(unity_ObjectToWorld, v.vertex).xyz;
                        return o;
                    }

                    fixed4 frag(v2f i) : SV_Target
                    {
                        float3 worldPos = i.pos;

                        fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                        fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                        float3 bump = normalize(i.normal);
                        float2 offset = bump.xy * _RefractionTex_TexelSize.xy;
                        i.scrPos.xy += offset * i.scrPos.z;
                        fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

                        fixed4 uvoffset1;
                        float2 p_10 = (i.uv.zw + (_Time.xz * 0.5));
                        uvoffset1 = tex2D(_NoiseMap, p_10);

                        fixed4 uvoffset2;
                        float2 p_12 = (i.uv.zw + (_Time.yx * 0.5));
                        uvoffset2 = tex2D(_NoiseMap, p_12);

                        float2 uvMain;
                        uvMain.x = (i.uv.x + ((((uvoffset1.x + uvoffset2.x) * (uvoffset1.w + uvoffset2.w)) - 1.0) * _WaveXSpeed));
                        uvMain.y = (i.uv.y + ((((uvoffset1.x + uvoffset2.x) * (uvoffset1.w + uvoffset2.w)) - 1.0) * _WaveYSpeed));

                        fixed4 texColor = tex2D(_MainTex, uvMain);
                        fixed3 reflDir = reflect(-viewDir, bump);
                        fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor * _Color.rgb;

                        fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
                        fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
                        return fixed4(finalColor, 1.0);
                    }
                    ENDCG
                }
        }
}
