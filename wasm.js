// ----------------------------------------------------------------
// WEBASSEMBLY GLUE
// ----------------------------------------------------------------

var wasm = (function() {
	var wasmModule = {};

	wasmModule.memory = null;
	wasmModule.instance = null;

	// ----------------------------------------------------------------
	// STANDARD LIBRARY FUNCTIONS
	// ----------------------------------------------------------------

	wasmModule.libc = (function() {
		var modules = {};

		modules.stdlib = (function() {
			var stdlib = {};

			var PAGE_SIZE = 1024 * 64;
			var NUM_PAGES = 256;
			var HEAP_PTR = 0;

			var BUFFER;

			var alignHeapPtr = function() {
				HEAP_PTR = (HEAP_PTR % 4) == 0 ? HEAP_PTR : HEAP_PTR + (4 - (HEAP_PTR % 4));
			};

			stdlib.prepareHeap = function(buffer, offset) {
				HEAP_PTR = offset;
				alignHeapPtr();
				BUFFER = buffer;
			};

			stdlib.abort = function() {
				console.error("ABORT");
			};

			stdlib.assert = function(expression) {
			};

			stdlib.malloc = function(bytes) {
				if (bytes > PAGE_SIZE * NUM_PAGES - HEAP_PTR) {
					return null;
				}
				var ptr = HEAP_PTR;
				HEAP_PTR += bytes;
				alignHeapPtr();
				return ptr;
			};

			stdlib.calloc = function(numItems, size) {
				var bytes = numItems * size;
				var ptr = stdlib.malloc(bytes);
				new Uint8Array(BUFFER).fill(0, ptr, ptr + bytes);
				return ptr;
			};

			stdlib.free = function(ptr) {
			};

			return stdlib;
		})();

		modules.string = (function() {
			var string = {};

			string.memcpy = function(dst, src, size) {
				new Uint8Array(wasm.memory.buffer).copyWithin(dst, src, src + size);
			};

			string.memset = function(ptr, value, num) {
				new Uint8Array(wasm.memory.buffer, ptr, num).fill(value, 0);
			};

			return string;
		})();

		return modules;
	})();

	wasmModule.createInstance = function(url) {
		return new Promise(function(resolve, reject) {
			fetch(url).then(function(response) {
				response.arrayBuffer().then(function(buffer) {
					wasmModule.memory = new WebAssembly.Memory({ initial: 1024 });
					wasmModule.libc.stdlib.prepareHeap(wasmModule.memory.buffer, 1024 * 64);

					WebAssembly.compile(buffer).then(function(module) {
						var imports = {};

						imports.env = {};
						imports.env.memoryBase = 0;
						imports.env.memory = wasmModule.memory;
						imports.env.tableBase = 0;
						imports.env.table = new WebAssembly.Table({ initial: 16, element: 'anyfunc' }); // I'm not sure why this value changes.  I use the value I find in the .wast file I generate.

						// TODO: Custom imports go here
						imports.env.abort = wasmModule.libc.stdlib.abort; // I'm not sure why this is a required import now.  And no '_' ...
						imports.env._assert = wasmModule.libc.stdlib.assert;
						imports.env._malloc = wasmModule.libc.stdlib.malloc;
						imports.env._calloc = wasmModule.libc.stdlib.calloc;
						imports.env._free = wasmModule.libc.stdlib.free;
						imports.env._memcpy = wasmModule.libc.string.memcpy;
						imports.env._memset = wasmModule.libc.string.memset;

						WebAssembly.instantiate(module, imports).then(function(instance) {
							instance.exports.__post_instantiate();
							wasmModule.instance = instance;
							resolve(wasmModule.instance);
						}); // instantiate
					}); // compile
				}); // arrayBuffer
			}); // fetch
		}); // new Promise
	}; // createInstance

	return wasmModule;
})();

// ----------------------------------------------------------------
// EMULATOR LOGIC AND RENDERING
// ----------------------------------------------------------------

var emulator = (function() {
	var emulatorModule = {};

	// ----------------------------------------------------------------
	// RENDERER
	// ----------------------------------------------------------------

	var renderer = (function() {
		var rendererModule = {};

		var gl = document.getElementById('canvas').getContext('webgl', {preserveDrawingBuffer: true});

		var shader = {};
		var geometry;
		var texture;
		var texture_dataview;
		var texture_buffer;

		var createShaders = function() {
			var shaderScriptElemV = document.getElementById('shader_fullquad_v');
			var shaderScriptElemF = document.getElementById('shader_fullquad_f');

			var shaderV = gl.createShader(gl.VERTEX_SHADER);
			var shaderF = gl.createShader(gl.FRAGMENT_SHADER);

			gl.shaderSource(shaderV, shaderScriptElemV.text);
			gl.shaderSource(shaderF, shaderScriptElemF.text);

			gl.compileShader(shaderV);
			gl.compileShader(shaderF);

			console.log("vert: " + gl.getShaderParameter(shaderV, gl.COMPILE_STATUS));
			console.log("frag: " + gl.getShaderParameter(shaderF, gl.COMPILE_STATUS));

			shader.handle = gl.createProgram();
			gl.attachShader(shader.handle, shaderV);
			gl.attachShader(shader.handle, shaderF);
			gl.linkProgram(shader.handle);

			console.log("shader: " + gl.getProgramParameter(shader.handle, gl.LINK_STATUS));

			shader.attr = {};
			shader.attr.vertex = gl.getAttribLocation(shader.handle, 'vertex');
			gl.enableVertexAttribArray(shader.attr.vertex);
		};

		var createGeometry = function() {
			var verts = [
				-1.0, 1.0, 0.0, 0.0,
				1.0, -1.0, 1.0, 1.0,
				-1.0, -1.0, 0.0, 1.0,

				-1.0, 1.0, 0.0, 0.0,
				1.0, 1.0, 1.0, 0.0,
				1.0, -1.0, 1.0, 1.0,
			];

			geometry = gl.createBuffer();
			gl.bindBuffer(gl.ARRAY_BUFFER, geometry);
			gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(verts), gl.STATIC_DRAW);
		};

		var createTexture = function() {
			texture_buffer = wasm.libc.stdlib.malloc(128 * 96 * 4);
			texture_dataview = new Uint8Array(wasm.memory.buffer, texture_buffer);

			texture = gl.createTexture();
			gl.bindTexture(gl.TEXTURE_2D, texture);
			gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 128, 96, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture_dataview);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
			gl.bindTexture(gl.TEXTURE_2D, null);
		};

		rendererModule.updateTexture = function() {
			wasm.instance.exports["_lem1802_write_texture"](handleLEM1802, handle, texture_buffer);
			gl.bindTexture(gl.TEXTURE_2D, texture);
			gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 128, 96, 0, gl.RGBA, gl.UNSIGNED_BYTE, texture_dataview);
			gl.bindTexture(gl.TEXTURE_2D, null);
		};

		rendererModule.render = function() {
			gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

			gl.useProgram(shader.handle);

			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, texture);
			gl.uniform1i(gl.getUniformLocation(shader.handle, 'texture0'), 0);

			gl.bindBuffer(gl.ARRAY_BUFFER, geometry);
			gl.vertexAttribPointer(shader.attr.vertex, 4, gl.FLOAT, false, 0, 0);

			gl.drawArrays(gl.TRIANGLES, 0, 6);

			gl.bindTexture(gl.TEXTURE_2D, null);
		};

		rendererModule.initialize = function() {
			gl.clearColor(0.0, 0.0, 0.0, 1.0);
			createShaders();
			createGeometry();
			createTexture();
		};

		return rendererModule;
	})();

	// ----------------------------------------------------------------
	// LOGIC
	// ----------------------------------------------------------------

	var startStopButton = document.getElementById("emulator-control-start");
	var speedControl = document.getElementById("emulator-control-speed");
	var speedLabel = document.getElementById("speedLabel");

	var registerDisplays = [
		document.getElementById("RA"),
		document.getElementById("RB"),
		document.getElementById("RC"),
		document.getElementById("RX"),
		document.getElementById("RY"),
		document.getElementById("RZ"),
		document.getElementById("RI"),
		document.getElementById("RJ"),
		document.getElementById("PC"),
		document.getElementById("SP"),
		document.getElementById("EX"),
		document.getElementById("IA"),
	];

	var registerPrefix = [
		"RA: 0x",
		"RB: 0x",
		"RC: 0x",
		"RX: 0x",
		"RY: 0x",
		"RZ: 0x",
		"RI: 0x",
		"RJ: 0x",
		"PC: 0x",
		"SP: 0x",
		"EX: 0x",
		"IA: 0x",
	];

	var running = false;

	var cyclesPerFrame = 10;

	var handle = null;
	var handleLEM1802 = null;
	var handleClock = null;

	var binary = null;

	emulatorModule.initialize = function() {
		handle = wasm.instance.exports["_dcpu_create"]();

		// Attach a LEM1802 to the DCPU
		handleLEM1802 = wasm.instance.exports["_dcpu_attach"](handle);
		wasm.instance.exports["_lem1802_initialize"](handleLEM1802);

		// Attack a clock to the DCPU
		handleClock = wasm.instance.exports["_dcpu_attach"](handle);
		wasm.instance.exports["_clock_initialize"](handleClock);

		renderer.initialize();
		
		// The speed slider likes to "stick" to its previous value, force it to the default
		let defaultSpeed = 100;
		speedControl.value = defaultSpeed;
		emulatorModule.handleSpeedChange(defaultSpeed);

		// Load stripes sample as default, don't run it
		emulatorModule.runSample("samples/luigi.bin", false);
		//*
		fetch("samples/luigi.asm").then(function(response) {
			response.text().then(function(text) {
				document.getElementById("sourceView").textContent = text;
			});
		});
		//*/
	};

	var startRunning = function() {
		startStopButton.textContent = "Stop";
		if (running == false) {
			running = true;
			emulatorDriver();
		}
	};

	var stopRunning = function() {
		startStopButton.textContent = "Start";
		running = false;
	};

	emulatorModule.runSample = function(url, run = true) {
		fetch(url).then(function(response) {
			response.arrayBuffer().then(function(buffer) {
				binary = buffer;

				wasm.instance.exports["_dcpu_power_off"](handle);
				wasm.instance.exports["_dcpu_reset"](handle);

				var ptr = wasm.libc.stdlib.malloc(buffer.byteLength);
				new Uint8Array(wasm.memory.buffer).set(new Uint8Array(buffer), ptr);
				
				wasm.instance.exports["_dcpu_flash"](handle, ptr, buffer.byteLength);
				wasm.instance.exports["_dcpu_power_on"](handle);

				if (run)
				{
					startRunning();
				}
			});
		});
	};

	var emulatorDriver = function() {
		wasm.instance.exports["_dcpu_tick"](handle);
		wasm.instance.exports["_dcpu_process"](handle, cyclesPerFrame);

		renderer.updateTexture();
		renderer.render();
		updateRegisterDisplay();

		if (running) {
			requestAnimationFrame(emulatorDriver);
		}	
	};

	var updateRegisterDisplay = function() {
		var registerValues = [];

		for (var registerIndex = 0; registerIndex < 12; registerIndex++) {
			var registerValue = wasm.instance.exports["_dcpu_get_register"](handle, registerIndex);

			registerValues.push(registerPrefix[registerIndex] + (registerValue + 0x10000).toString(16).substr(-4).toUpperCase());

			// Only update the color when steping... gross at full speed.
			/*
			if (registerValues[registerIndex] == registerDisplays[registerIndex].innerHTML) {
				registerDisplays[registerIndex].className = "registerUnchanged";
			}
			else {
				registerDisplays[registerIndex].className = "registerUpdated";
			}
			*/

			registerDisplays[registerIndex].innerHTML = registerValues[registerIndex];
		}
	};

	emulatorModule.handleStartStop = function() {
		if (running == true) {
			stopRunning();
		}
		else {
			startRunning();
		}
	};

	emulatorModule.handleStep = function() {
		stopRunning();

		wasm.instance.exports["_dcpu_process"](handle, 1);

		renderer.updateTexture();
		renderer.render();
		updateRegisterDisplay();
	};
	
	emulatorModule.handleReset = function() {
		stopRunning();

		wasm.instance.exports["_dcpu_power_off"](handle);
		wasm.instance.exports["_dcpu_reset"](handle);

		if (binary)
		{
			var ptr = wasm.libc.stdlib.malloc(binary.byteLength);
			new Uint8Array(wasm.memory.buffer).set(new Uint8Array(binary), ptr);
		
			wasm.instance.exports["_dcpu_flash"](handle, ptr, binary.byteLength);
		}

		wasm.instance.exports["_dcpu_power_on"](handle);

		renderer.updateTexture();
		renderer.render();
		updateRegisterDisplay();
	};

	emulatorModule.handleSpeedChange = function(value) {
		var minp = 1;
		var maxp = 100;

		var minv = Math.log(1);
		var maxv = Math.log(1800);

		var scale = (maxv - minv) / (maxp / minp);

		cyclesPerFrame = Math.floor(Math.exp(minv + scale * (value - minp)));

		speedLabel.textContent = "Emulation Speed: " + cyclesPerFrame * 60 + "Hz";
	};

	return emulatorModule;
})();
