import { fileURLToPath, URL } from 'node:url'
import path from 'node:path'
import glob from 'glob'
import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
let viteConfig = {
  root: 'modules/farm_fd2/src/entrypoints',
  publicDir: '../public',
  plugins: [
    vue(),
    viteStaticCopy({
      // Copy the Drupal module stuff...
      targets: [
        {
          src: '../module/*.yml',
          dest: '.',
        },
        {
          src: '../module/Controller',
          dest: 'src/',
        },
        {
          src: '../composer.json',
          dest: './composer.json',
        },
      ],
    }),
  ],
  build: {
    outDir: '../../dist',
    emptyOutDir: true,
    exclude: ['**/*.cy.js', '**/*.cy.comp.js', '**/*.cy.unit.js'],
    rollupOptions: {
      input: Object.fromEntries(
        glob.sync('modules/farm_fd2/src/entrypoints/*/*.html').map((file) => [
          path.basename(file, '.html'), // the prefix to .html, e.g. main
          file.slice('modules/farm_fd2/src/entrypoints/'),
        ])
      ),
      output: {
        // Ensures that the entry point and css names are not hashed.
        entryFileNames: '[name]/[name].js',
        assetFileNames: (assetInfo) => {
          let ext = assetInfo.name.split('.').at(1)
          if (ext === 'css') {
            return '[name]/[name].[ext]'
          } else {
            return 'shared/[name].[ext]'
          }
        },
        chunkFileNames: '[name]/[name].js',
      },
    },
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src/', import.meta.url)),
    },
  },
}

console.log('Building: ')
console.log(viteConfig.build.rollupOptions.input)

export default defineConfig(viteConfig)
