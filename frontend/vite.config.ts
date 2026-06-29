import { defineConfig } from 'vite';
import react, { reactCompilerPreset } from '@vitejs/plugin-react';
import babel from '@rolldown/plugin-babel';

const backendPort = process.env.BACKEND_PORT ?? '8081';
const proxy = { '/api': { target: `http://localhost:${backendPort}` } };

export default defineConfig({
	plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
	server: { host: true, port: 8080, proxy },
	preview: { host: true, port: 8080, proxy, allowedHosts: ['.run.app'] },
});
