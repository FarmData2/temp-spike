import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'

import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    viteStaticCopy({
      targets: [
        {
          src: 'module/*.yml',
          dest: '.',
        },
        {
          src: 'module/Controller',
          dest: 'src/',
        },
      ],
    }),
  ],
  publicDir: '../public',
  root: './farm_fd2/src',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    exclude: ['**/*.cy.js', '**/*.cy.comp.js'],
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./src/main/main.html', import.meta.url)),
        other: fileURLToPath(new URL('./src/other/other.html', import.meta.url)),
      },
      output: {
        // Ensures that the entry point and css names are not hashed.
        entryFileNames: '[name].js',
        assetFileNames: `[name].[ext]`,
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
