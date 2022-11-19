Shader "Roystan/Toon/Water"
{
    Properties
    {	
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0,1)) = 0.777
    	_FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamMaxDistance("Foam Max Distance", Float) = 0.4
        _FoamMinDistance("Foam Min Distance", Float) = 0.04
        
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
    }
    SubShader
    {
    	Tags
		{
			"Queue" = "Transparent"
		}
    	
        Pass
        {
        	Blend SrcAlpha OneMinusSrcAlpha
        	ZWrite off
        	
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#define SMOOTHSTEP_AA 0.01
            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
			    float4 uv : TEXCOORD0;
            };
			
			float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
			float4 _FoamColor;
			
            float _DepthMaxDistance;
			float _SurfaceNoiseCutoff;
            float _FoamMinDistance;
            float _FoamMaxDistance;
			float2 _SurfaceNoiseScroll;
			
            sampler2D _CameraDepthTexture;
			sampler2D _CameraNormalsTexture;

			sampler2D _SurfaceNoise;
			float4 _SurfaceNoise_ST;

			sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
			float _SurfaceDistortionAmount;

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 viewNormal : NORMAL;
                float2 noiseUV : TEXOORD0;
            	float2 distortUV : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

			float4 alphaBlend(float4 top, float4 bottom)
			{
				float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
				float alpha = top.a + bottom.a * (1 - top.a);

				return float4(color, alpha);
			}
			

            Interpolators vert (MeshData v)
            {
                Interpolators i;

                i.vertex = UnityObjectToClipPos(v.vertex);
                i.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise); //TRANSFORM_TEX applies tiling and offset settings to texture
            	i.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                i.screenPos = ComputeScreenPos(i.vertex);
				i.viewNormal = COMPUTE_VIEW_NORMAL;
            	
                return i;
            }


            float4 frag (Interpolators i) : SV_Target
            {
                //gives us depth using the DepthTexture and projecting it using our screen space pos
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);

                float depthDifference = existingDepthLinear - i.screenPos.w;

                //returns a value between 0-1 relative to the difference of depthDifference and the max distance
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

				float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;
                float2 noiseUV = float2((i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y)
                	+ distortSample.y);
                
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;

				float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPos));
            	float3 normalDot = saturate(dot(existingNormal, i.viewNormal));

            	float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
                float foamDepthDifference01 = saturate(depthDifference / foamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                //float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? 1 : 0;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
            	float4 surfaceNoiseColor = _FoamColor;
            	surfaceNoiseColor.a *= surfaceNoise;
                
				return alphaBlend(surfaceNoiseColor, waterColor);
            }
            ENDCG
        }
    }
}