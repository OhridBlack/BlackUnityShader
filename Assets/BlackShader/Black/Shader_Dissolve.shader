Shader "BlackShader/Shader_Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BurnAmount("Burn Amount",Range(0.0,1.0))=0.0
        _LineWidth("Burn Line Width",Range(0.0,0.2))=0.1
        _BumpMap("Normal Map",2D)="white"{}
        _BurnFirstColor("Burn First Color",Color)=(1,0,0,1)
        _BurnSecondColor("Burn Second Color",Color)=(1,0,0,1)
        _BurnMap("Noise Map",2D)="white"{}
        [Toggle]
        _UseTime("Use Time",FLOAT)=0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 uvBump:TEXCOORD1;
                float2 uvBurn:TEXCOORD2;
                float3 lightDir:TEXCOORD3;
                float3 worldPos:TEXCOORD4;
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            float _LineWidth;
            float _BurnAmount;
            float _UseTime;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvBump = TRANSFORM_TEX(v.uv, _BumpMap);
                o.uvBurn = TRANSFORM_TEX(v.uv, _BurnMap);

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float burnAmount;
                if (_UseTime) {
                    burnAmount = sin(_Time.y);
                }
                else {
                    burnAmount = _BurnAmount;
                }
                fixed3 burn = tex2D(_BurnMap,i.uvBurn).rgb;
                clip(burn.r - burnAmount);
                float3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBump));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - burnAmount);
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
                burnColor = pow(burnColor, 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, burnAmount));
                
                return fixed4(finalColor, 1);
            }
            ENDCG
        }

        Pass {
                Tags{"LightMode"="ShadowCaster"}
                CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"
                struct v2f {
                    V2F_SHADOW_CASTER;
                    float2 uvBurn:TEXCOORD1;
                };

            sampler2D _BurnMap;
            float4 _BurnMap_ST;
            float _BurnAmount;
            float _UseTime;

            v2f vert(appdata_base v) {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                o.uvBurn = TRANSFORM_TEX(v.texcoord, _BurnMap);
                return o;
            }

            fixed4 frag(v2f i) :SV_Target{
                fixed3 burn = tex2D(_BurnMap,i.uvBurn).rgb;
            float burnAmount;
            if (_UseTime) {
                burnAmount = sin(_Time.y);
            }
            else {
                burnAmount = _BurnAmount;
            }
            clip(burn.r - burnAmount);
            SHADOW_CASTER_FRAGMENT(i)
            }

                ENDCG
        }
    }
}
