Shader "Unlit/BasicShader2"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "black" {}
        
        _ColorA ("ColorA", Color) = (1,1,1,1)
        _ColorB ("ColorB", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct MeshData
            {
                float3 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _ColorA;
            float4 _ColorB;

            float invLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }
            
            Interpolators vert (MeshData v)
            {
                Interpolators i;
                i.uv = v.uv;
                i.vertex = UnityObjectToClipPos(v.vertex);
                i.worldPos = mul(UNITY_MATRIX_M, float4(v.vertex, 1));

                return i;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                float4 color = tex2D(_MainTex, i.uv);
                
                //return lerp(_ColorA, _ColorB, 0.5f*sin(_Time.y)+0.5f);
                //float2 coords = i.uv;
                //return float4(coords.xxxx);

                return lerp(color, _ColorA, saturate(i.worldPos.y));
            }
            ENDCG
        }
    }
}
