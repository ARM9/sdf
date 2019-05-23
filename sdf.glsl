#iChannel0 https://66.media.tumblr.com/tumblr_mcmeonhR1e1ridypxo1_500.jpg
#iChannel1 buf://./test.glsl

#define EPSILON 0.0001

float ground (vec3 point) {
  return point.y;
}

float sphere (vec3 point, float radius) {
  return length(point) - radius;
}

float box (vec3 point, vec3 bounds) {
  vec3 d = abs(point) - bounds;
  return length (max(d,0.0))
         + min (max (d.x, max(d.y, d.z)), 0.0);
}
float torus ( vec3 point, vec2 t ) {
  vec2 q = vec2(length(point.xz) - t.x, point.y);
  return length(q) - t.y;
}
/*
float sd_repeat ( in vec3 p, in vec3 c, in (primitive) ) {
    vec3 q = mod(p,c)-0.5*c;
    return primitve( q );
}
float sd_twist( in sdf3d primitive, in vec3 p ) {
    const float k = 10.0; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return primitive(q);
}
float sd_cheapBend( in sdf3d primitive, in vec3 p ) {
    const float k = 10.0; // or some other amount
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return primitive(q);
}*/

#define sd_symX (p) vec3(abs(p.x), p.yz);

/*float opSymX(vec3 p, sdf3d primitive ) {
    p.x = abs(p.x);
    return primitive(p);
}

float opSymXZ(vec3 p, sdf3d primitive ) {
    p.xz = abs(p.xz);
    return primitive(p);
}*/

float sd_union (float a, float b) {
  return min(a, b);
}
float sd_diff (float a, float b) {
  return max(-a, b); // max(a, -b)?
}
float sd_intersect (float a, float b) {
  return max(a, b);
}
float sd_smooth_union ( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5 * (d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
float sd_smooth_diff ( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5 * (d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h);
}
float sd_smooth_intersect ( float d1, float d2, float k ) {
  float h = clamp( 0.5 - 0.5 * (d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) + k*h*(1.0-h);
}

float world (in vec3 position) {
  vec3 tp = position - vec3 (0.5, 1.0, 0.0);
  tp.x = abs(tp.x);

  return sd_union (
          ground(position - vec3 (0.0, -1.5, 0.0)),
          sd_smooth_union (
            //sphere(position - vec3 (-0.5, 1.0, -2.0), 0.1),
            torus(tp, vec2(1.0,0.1+abs(sin(iGlobalTime)))),
            box(tp, vec3(0.5, 1.0, 0.5)),
            0.3
          )
         );
}

float raymarch (in vec3 origin, in vec3 direction) {
  const float minDistance = 1.0, maxDistance = 50.0;
  float totalDistance = minDistance;
  const int maxSteps = 64;
  for (int steps = 0; steps < maxSteps; steps++) {
    float p = 0.0005 * totalDistance;
    float distance = world(origin + direction * totalDistance);
    if (distance < EPSILON || totalDistance >= maxDistance) break;
    totalDistance += distance;
  }
  if (totalDistance >= maxDistance) totalDistance = -1.0;
  return totalDistance;
}

vec3 normal (vec3 point) {
  vec3 v = vec3(1.0);
  return v;
}

vec3 render (in vec3 origin, in vec3 direction) {
  vec3 color = vec3(0.0);
  float t = raymarch(origin, direction);
  if (t > -0.5) {
    vec3 material = vec3(0.3);
    color = material * 4.0 * vec3(1.0, 0.7, 0.5);
    color *= exp( -0.0001 * t*t*t );
    vec2 tuv = gl_FragCoord.xy / iResolution.xy;
    color *= texture2D(iChannel1,tuv).rgb;
  }
  return color;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main() {

  float time = iGlobalTime * 1.0;

  vec2 tuv = gl_FragCoord.xy / iResolution.xy;
  vec2 uv = (gl_FragCoord.xy / iResolution.xx - 0.5) * 8.0;

  vec3 light = vec3(2.0, 2.0, 2.0);

        vec2 p = (-iResolution.xy + 2.0*gl_FragCoord.xy)/iResolution.y;

        float an = 12.0 - sin(0.1*iTime);
        vec3 ray_origin = vec3(0.0,0.0,18.0+6.0*sin(time));//vec3( 3.0*cos(0.1*an), 1.0, -3.0*sin(0.1*an) );
        vec3 ta = vec3(cos(time)*3.0, sin(time) , cos(time)*2.0 );
        // camera-to-world transformation
        mat3 camera = setCamera( ray_origin, ta, 0.0 );

        // ray direction
        vec3 ray_direction = camera * normalize( vec3(p.xy,2.0) );

        // render
        vec3 col = render( ray_origin, ray_direction );

		    // gamma
        //col = pow( col, vec3(0.4545) );

    gl_FragColor = vec4( col, 1.0 );

}
