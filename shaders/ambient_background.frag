#include <flutter/runtime_effect.glsl>

precision highp float;
const float TAU = 6.28318530718;

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uBaseA;
uniform vec3 uBaseB;
uniform vec3 uAccent;
uniform vec3 uGlow;
uniform float uIntensity;
uniform float uVisibilityBoost;
uniform float uBlobRadiusScale;
uniform float uBlobSoftnessScale;
uniform float uMotionScale;
uniform float uAccentStrength;
uniform float uGlowStrength;
uniform float uDistortionAmount;

out vec4 fragColor;

float softBlob(vec2 uv, vec2 center, float radius, float softness) {
  float d = distance(uv, center);
  return smoothstep(radius + softness, radius - softness, d);
}

float organicBlob(
  vec2 uv,
  vec2 center,
  float radius,
  float softness,
  vec2 lobeDirection
) {
  float core = softBlob(uv, center, radius, softness);
  float lobe = softBlob(
    uv,
    center + lobeDirection * radius * 0.48,
    radius * 0.72,
    softness * 1.08
  );
  float carve = softBlob(
    uv,
    center - lobeDirection * radius * 0.28,
    radius * 0.32,
    softness * 0.86
  );

  return clamp(max(core, lobe) - carve * 0.16, 0.0, 1.0);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 p = uv * 2.0 - 1.0;
  p.x *= uSize.x / max(uSize.y, 1.0);

  float phase = uTime * TAU;
  float motionAmount = 1.0 + max(uMotionScale - 1.0, 0.0) * 0.8;
  float waveA =
      sin(p.x * 2.4 + phase + sin(p.y * 1.6 - phase * 2.0) * 0.5);
  float waveB =
      sin(p.y * 2.0 - phase * 2.0 + sin(p.x * 1.5 + phase) * 0.45);
  float field = 0.5 + 0.18 * waveA + 0.14 * waveB;
  vec2 flow = vec2(
    sin((uv.y * 2.15 + uv.x * 0.62) * TAU + phase) +
        0.5 * cos((uv.x * 1.35 - uv.y * 0.78) * TAU - phase * 2.0),
    cos((uv.x * 1.95 - uv.y * 0.48) * TAU - phase) +
        0.5 * sin((uv.y * 1.58 + uv.x * 0.72) * TAU + phase * 2.0)
  ) / 1.5;
  vec2 blobUv = clamp(
    uv + flow * uDistortionAmount * motionAmount,
    0.0,
    1.0
  );

  vec3 color = mix(uBaseA, uBaseB, smoothstep(0.08, 0.92, uv.y + field * 0.06));

  float upperBlob = organicBlob(
    blobUv,
    vec2(
      0.24 + 0.03 * motionAmount * sin(phase + 0.3),
      0.22 + 0.02 * motionAmount * cos(phase * 2.0 - 0.2)
    ),
    0.34 * uBlobRadiusScale,
    0.22 * uBlobSoftnessScale,
    normalize(vec2(0.72, -0.18))
  );
  float sideBlob = organicBlob(
    blobUv,
    vec2(
      0.84 + 0.02 * motionAmount * cos(phase - 0.55),
      0.30 + 0.03 * motionAmount * sin(phase * 2.0 + 0.6)
    ),
    0.28 * uBlobRadiusScale,
    0.2 * uBlobSoftnessScale,
    normalize(vec2(-0.66, 0.24))
  );
  float lowerBlob = organicBlob(
    blobUv,
    vec2(
      0.56 + 0.025 * motionAmount * sin(phase * 2.0 + 0.8),
      0.82 + 0.02 * motionAmount * cos(phase - 0.7)
    ),
    0.42 * uBlobRadiusScale,
    0.26 * uBlobSoftnessScale,
    normalize(vec2(0.28, -0.74))
  );

  float intensityScale = mix(0.55, 1.95, uIntensity);
  float visibilityScale = uVisibilityBoost;
  float accentGain = visibilityScale * uAccentStrength;
  float glowGain = visibilityScale * uGlowStrength;
  vec3 blendedAccent = mix(uAccent, uGlow, 0.45);

  color += uAccent * upperBlob * 0.18 * intensityScale * accentGain;
  color += uGlow * sideBlob * 0.17 * intensityScale * glowGain;
  color +=
      blendedAccent *
      lowerBlob *
      0.14 *
      intensityScale *
      mix(accentGain, glowGain, 0.45);

  float bloomMask = clamp(
    upperBlob * 0.88 + sideBlob * 0.82 + lowerBlob * 0.72,
    0.0,
    1.0
  );
  color +=
      blendedAccent *
      bloomMask *
      0.045 *
      (0.5 + uIntensity) *
      mix(accentGain, glowGain, 0.5);

  float sweep = sin((uv.x + uv.y) * 5.0 - phase * 2.0) * 0.5 + 0.5;
  color +=
      vec3(0.012, 0.018, 0.03) *
      pow(sweep, 3.0) *
      (0.18 + 0.42 * uIntensity) *
      mix(1.0, visibilityScale, 0.55);

  color = 1.0 - exp(-color * 1.08);
  fragColor = vec4(color, 1.0);
}
