#ifdef GL_ES
precision lowp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
varying vec4 v_font_color;

uniform sampler2D u_texture;
uniform vec4 u_border;
uniform float u_alpha;

void main()
{
    vec4 FragColor = texture2D(u_texture, v_texCoord);
    gl_FragColor = mix(v_font_color, u_border, 1-FragColor.r);
    gl_FragColor.a = FragColor.a * u_alpha;
}
