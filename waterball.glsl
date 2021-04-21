#define MAX_STEPS 200
#define MAX_DISTANCE 100.0
#define EPSILON 0.0001

const vec3 ambient = vec3(0., 0., 0.);
const vec3 lightColor = vec3(1., 1., 1.);
const vec3 specularColor = vec3(0, 0, 0);
const float gloss = 80.;
const float fieldOfView = 45.;
const float near = 1.;
const vec3 sphereCenter = vec3(0, 0, 0);
const float fresnelScale = .6;

float hash12(vec2 p) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);	
	vec3 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
	float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
	float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
	b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
	d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
}

vec2 dir2uv(vec3 dir) {
    vec2 uv = dir.xy / (2. * length(dir + vec3(0, 1, 0))) + 0.5;
    return uv;
}

float SDF_sphere(vec3 sp, vec3 center) {
    vec3 dir = sp - center;
    return length(dir) - 1.;
}

float SDF(vec3 sp) {
    vec3 dir = sp;
    vec2 uv = dir2uv(normalize(dir));
    
    vec3 speed1 = vec3(1,1,1)*2.;
    vec3 speed2 = vec3(-1,1,0)*2.;
    float noiseR = noise_3(dir*8. + speed1*iTime) + noise_3(dir*8.+speed2*iTime);
    
    float dis1 = SDF_sphere(sp, vec3(0,0,-.9));
    float dis2 =  SDF_sphere(sp, vec3(0,0,.9));
    
    float k = 0.5;
    float h = clamp(0.5+0.5*(dis1-dis2)/k, 0., 1.);
    return mix(dis1, dis2, h) - k*h*(1.-h) - noiseR*.05;
    //return dis1*dis2/(dis1+dis2) - noiseR*.05;
}

vec3 getNorm(vec3 sp) {
    vec3 spPlus = sp + EPSILON;
    vec3 spMinus = sp - EPSILON;
    float x1 = SDF(vec3(spPlus.x, sp.y, sp.z));
    float x0 = SDF(vec3(spMinus.x, sp.y, sp.z));
    float y1 = SDF(vec3(sp.x, spPlus.y, sp.z));
    float y0 = SDF(vec3(sp.x, spMinus.y, sp.z));
    float z1 = SDF(vec3(sp.x, sp.y, spPlus.z));
    float z0 = SDF(vec3(sp.x, sp.y, spMinus.z));
    
    return normalize(vec3(x1-x0, y1-y0, z1-z0));
}

vec4 backgroundSampler(vec3 rd) {
    return texture(iChannel0, rd);
}

vec3 calcLight(vec3 sp, vec3 rd) {
    vec3 lightDir = normalize(vec3(1, 1, 1));
    vec3 normDir = getNorm(sp);
    vec3 viewDir = -rd;
    vec3 halfDir = normalize(viewDir + lightDir);
    
    vec3 diffuse = lightColor * max(0., dot(normDir, lightDir));
    vec3 specular = specularColor * pow(max(0., dot(normDir, halfDir)), gloss);
    
    vec3 reflDir = reflect(rd, normDir);
    vec3 reflColor = backgroundSampler(reflDir).xyz;
    
    vec3 refrDir = refract(rd, normDir, .95);
    vec3 refrColor = backgroundSampler(refrDir).xyz;
    
    float fresnel = fresnelScale + (1. - fresnelScale) * pow((1. - dot(viewDir, normDir)), 5.);
    
    //rimlight
    float rimPower = 1. - dot(normDir, viewDir);
    vec3 rimLight = vec3(1, 1, 1);
    
    return mix(refrColor, reflColor, fresnel) + rimLight*rimPower*.5 + specular;
}

vec3 rayMarching(vec3 ro, vec3 rd) {
    float dist = 0.;
    for(int i = 0; i < MAX_STEPS; ++i) {
        vec3 sp = ro + rd * dist;
        float deltaDist = SDF(sp);
        dist += deltaDist;
        if(deltaDist < EPSILON) {
            return calcLight(sp, rd);
        }
        if(dist >= MAX_DISTANCE) {
            return backgroundSampler(rd).xyz;
        }
    }
    return backgroundSampler(rd).xyz;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float angle = iTime*.5;
    vec3 ro = vec3(4.*sin(angle), 1., 4.*cos(angle));
    vec3 camDirection = normalize(sphereCenter - ro);
    vec3 camXAxis = normalize(vec3(cos(angle), 0, -sin(angle)));
    vec3 camYAxis = cross(camXAxis, camDirection);
    
    float nearPlaneHeight = near * tan(radians(fieldOfView / 2.)) * 2.;
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) * nearPlaneHeight / iResolution.y; 
    vec3 rd = normalize(camXAxis*uv.x + camYAxis*uv.y + camDirection*near);
    
    fragColor = vec4(rayMarching(ro, rd), 1.);
}