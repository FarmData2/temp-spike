import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  publicDir: '../public',
  root: './fd2_spike/src',
  build: {
    outDir: '../dist',
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./src/main/index.html', import.meta.url)),
        other: fileURLToPath(new URL('./src/other/index.html', import.meta.url)),
      },
    },
  },
  resolve: {
    alias: {
      // For cypress tests.
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
})
