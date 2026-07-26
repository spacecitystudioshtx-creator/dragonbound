import { defineConfig } from 'vite';

export default defineConfig({
  // Relative base so the same build works at github.io/dragonbound/ or any root.
  base: './',
  server: { port: 5173 },
  build: { target: 'es2020' },
});
