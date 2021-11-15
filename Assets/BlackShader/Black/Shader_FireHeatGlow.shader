Shader "BlackShader/Shader_FireHeatGlow"
{
    Properties
    {
        _Count("heat glow ",Range(0,1))=0.5
        _NoiseTex("Noise texture",2D)=""{}
        _TimeFactor("Time Factor",Range(0,1))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Overlay"}
        LOD 100
        GrabPass{"_RefractionTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _RefractionTex;
            float4 _RefractionTex_ST;
            float _Count;
            float _TimeFactor;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 scrPos:TEXCOORD0;
                float2 uv:TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 offset = tex2D(_NoiseTex,i.uv - _Time.xy * _TimeFactor);
                i.scrPos.xy += offset.xy * _Count;
                fixed3 col = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
}
