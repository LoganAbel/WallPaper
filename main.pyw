import pyglet
from pyglet.gl import *
# from pyglet import clock
from pyglet.window import key
from pyglet.graphics.shader import Shader, ShaderProgram
import win32gui
from datetime import datetime

import os

def get_resource_path(path):
	return os.path.join(os.path.dirname(__file__), path)

class WallPaper:
	def __init__(self, shader_name):
		style = pyglet.window.Window.WINDOW_STYLE_BORDERLESS
		self.window = pyglet.window.Window(width=960, height=540,
									  style=style, resizable=False)
		self.window.set_size(1920, 1200)
		# set behind icons

		progman = win32gui.FindWindow("Progman", None)
		result = win32gui.SendMessageTimeout(progman, 0x052c, 0, 0, 0x0, 1000)
		workerw = 0

		def _enum_windows(tophandle, topparamhandle):
			p = win32gui.FindWindowEx(tophandle, 0, "SHELLDLL_DefView", None)
			if p != 0:
				workerw = win32gui.FindWindowEx(0, tophandle, "WorkerW", None)

				pyglet_hwnd = self.window._hwnd
				# pyglet_hdc = win32gui.GetWindowDC(pyglet_hwnd)
				win32gui.SetParent(pyglet_hwnd, workerw)

			return True

		win32gui.EnumWindows(_enum_windows, 0)

		self.shader = None
		self.tris = None

		framerate = 60
		timescale = 0.5
		self.time = 0

		def _update_shader_time(dt):
			if self.shader == None: return
			if "iTime" in self.shader.uniforms:
				self.time += dt * timescale
				self.shader["iTime"] = self.time

			if "iDate" in self.shader.uniforms:
				now = datetime.now()
				seconds = (now - now.replace(hour=0, minute=0, second=0, microsecond=0)).total_seconds()
				self.shader["iDate"] = (now.year, now.month, now.day, seconds)

		pyglet.clock.schedule_interval(_update_shader_time, 1 / framerate)

		@self.window.event
		def on_draw():
			if self.shader == None: return
			gl.glClearColor(1, 0, 0, 0)
			gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT)
			self.shader.use()
			self.tris.draw(GL_TRIANGLES)

		@self.window.event
		def on_resize(width, height):
			if self.shader == None: return
			if "iResolution" in self.shader.uniforms:
				self.shader["iResolution"] = (width, height)

		vert = """
			#version 150 core
			in vec2 position;
			out vec2 uv;

			void main() {
			    gl_Position = vec4(position, 0.0, 1.0);
			    uv = position;
			}
		"""
		frag = get_resource_path(f'{shader_name}.glsl')
		frag_header = """
			#version 150 core
			precision highp float;
			uniform vec2 iResolution;
			uniform float iTime;
			uniform vec4 iDate;
			out vec4 fragColor;
			in vec2 uv;
		"""
		frag_footer = """void main() { mainImage(fragColor, (uv * .5 + .5) * iResolution); }"""
		with open(frag, 'r') as frag_file:
			vert_shader = Shader(vert, 'vertex')
			frag_shader = Shader(frag_header + frag_file.read() + frag_footer, 'fragment')

		self.shader = ShaderProgram(vert_shader, frag_shader)
		self.tris = self.shader.vertex_list(6, pyglet.gl.GL_TRIANGLES)
		self.tris.position = (-1, -1, -1, 1, 1, -1, 1, 1, -1, 1, 1, -1)

margin = 10
font_size = 36

class Option:
	def __init__(self, text, i, height):
		self.button = pyglet.shapes.Rectangle(margin, height-margin-font_size-i*font_size*1.4, font_size, font_size)
		self.label = pyglet.text.Label(text,
			font_name='Times New Roman', font_size=font_size,
			x=margin*2+font_size, y=height-margin-font_size-i*font_size*1.4)
	def draw(self, selected):
		self.button.color = (255, 255, 255) if selected else (65, 65, 65)
		self.label.draw()
		self.button.draw()
	def overlap(self, x, y):
		return x > self.button.x and y > self.button.y \
			and x < self.button.x + self.button.width \
			and y < self.button.y + self.button.height

with open(get_resource_path('options.txt'), 'r') as file:
	titles = [line if line[-1] != '\n' else line[:-1] for line in file.readlines()]
	selected, *titles = titles
	selected = int(selected)

width = 640
height = int(font_size * (len(titles) + 1) * 1.4 + margin * 2)
window = pyglet.window.Window(width, height, caption='WallPaper')

options = [
	Option(label, i, height) 
	for i, label in enumerate(titles)
]

wallpaper = WallPaper(options[selected].label.text)

@window.event
def on_draw():
	window.clear()
	for i, option in enumerate(options):
		option.draw(i == selected)

@window.event
def on_close():
	pyglet.app.exit()

@window.event
def on_mouse_press(x, y, button, modifiers):
	if button != pyglet.window.mouse.LEFT: return
	for i, option in enumerate(options):
		if i != selected and option.overlap(x, y):
			with open(get_resource_path('options.txt'), 'w') as file:
				file.write(str(i) + '\n' + '\n'.join(titles))
			pyglet.app.exit()

pyglet.app.run()