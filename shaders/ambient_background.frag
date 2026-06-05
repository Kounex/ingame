#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uBaseA;
uniform vec3 uBaseB;
uniform vec3 uAccent;
uniform vec3 uGlow;
uniform float uIntensity;

out vec4 fragColor;

float softBlob(vec2 uv, vec2 center, float radius, float softness) {
  float d = distance(uv, center);
  return smoothstep(radius + softness, radius - softness, d);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 p = uv * 2.0 - 1.0;
  p.x *= uSize.x / max(uSize.y, 1.0);

  float t = uTime * 0.08;
  float waveA = sin(p.x * 2.4 + t + sin(p.y * 1.6 - t * 0.6) * 0.5);
  float waveB = sin(p.y * 2.0 - t * 0.8 + sin(p.x * 1.5 + t * 0.3) * 0.45);
  float field = 0.5 + 0.18 * waveA + 0.14 * waveB;

  vec3 color = mix(uBaseA, uBaseB, smoothstep(0.08, 0.92, uv.y + field * 0.06));

  float upperBlob = softBlob(
    uv,
    vec2(0.24 + 0.03 * sin(t * 1.2), 0.22 + 0.02 * cos(t * 0.8)),
    0.34,
    0.22
  );
  float sideBlob = softBlob(
    uv,
    vec2(0.84 + 0.02 * cos(t * 0.7), 0.30 + 0.03 * sin(t * 0.9)),
    0.28,
    0.2
  );
  float lowerBlob = softBlob(
    uv,
    vec2(0.56 + 0.025 * sin(t * 0.5), 0.82 + 0.02 * cos(t * 0.6)),
    0.42,
    0.26
  );

  float intensityScale = mix(0.45, 1.85, uIntensity);

  color += uAccent * upperBlob * 0.16 * intensityScale;
  color += uGlow * sideBlob * 0.14 * intensityScale;
  color += mix(uAccent, uGlow, 0.35) * lowerBlob * 0.1 * intensityScale;

  float sweep = sin((uv.x + uv.y) * 5.0 - t * 1.4) * 0.5 + 0.5;
  color += vec3(0.012, 0.018, 0.03) * pow(sweep, 3.0) * (0.18 + 0.42 * uIntensity);

  fragColor = vec4(color, 1.0);
}
