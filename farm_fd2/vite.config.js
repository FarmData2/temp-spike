import { fileURLToPath, URL } from 'node:url'
import path from 'node:path'
import glob from 'glob'
import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'

import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    viteStaticCopy({
      // Copy the Drupal module stuff...
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
      input: Object.fromEntries(
        glob.sync('farm_fd2/src/**/*.html').map((file) => [
          path.basename(file, '.html'), // the prefix to .html, e.g. main
          fileURLToPath(new URL(file.slice('farm_fd2/'.length), import.meta.url)),
        ])
      ),
      output: {
        // Ensures that the entry point and css names are not hashed.
        entryFileNames: '[name].js',
        assetFileNames: '[name].[ext]',
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
