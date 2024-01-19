#version 330 core

in vec2 v_TexCoords;
out vec4 FragColor;

uniform bool isSlider;
uniform float sliderPercentage;

//vec3 rgb2hsv(vec3 c){
//  vec4 K = vec4(0.0,-1.0 / 3.0,2.0 / 3.0,-1.0);
//  vec4 p = mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));
//  vec4 q = mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
//  float d = q.x - min(q.w,q.y);
//  float e = 1.0e-10;
//  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),d / (q.x + e),q.x);
//}

vec3 hsv2rgb(vec3 color){
  vec3 rgb = clamp(abs(mod(color.r * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  rgb = rgb * rgb * (3.0 - 2.0 * rgb);
  return color.b * mix(vec3(1.0), rgb, color.g);
}

void main() {
  if (isSlider) {
    vec3 color = hsv2rgb(vec3(v_TexCoords.y, 1.0, 1.0));
    FragColor = vec4(color, 1.0);
  } else {
    vec3 color = hsv2rgb(vec3(sliderPercentage, v_TexCoords.x, 1.0 - v_TexCoords.y));
    FragColor = vec4(color, 1.0);
  }
}
