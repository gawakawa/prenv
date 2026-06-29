import { defineConfig } from 'vite';
import react, { reactCompilerPreset } from '@vitejs/plugin-react';
import babel from '@rolldown/plugin-babel';

const proxy = { '/api': { target: 'http://localhost:8081' } };

export default defineConfig({
	plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
	server: { host: true, port: 8080, proxy },
	preview: { host: true, port: 8080, proxy },
});
