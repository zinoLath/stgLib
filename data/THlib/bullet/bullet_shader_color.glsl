#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform sampler2D u_texture;
uniform vec3 center_color;

void main()
{
    vec4 tex_color = texture2D(u_texture, v_texCoord);
    gl_FragColor.rgb = mix(v_fragmentColor.rgb,center_color,tex_color.r);
    gl_FragColor.a = tex_color.a * v_fragmentColor.a;
}