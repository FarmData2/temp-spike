import { fileURLToPath, URL } from 'node:url'
import path from 'node:path'
import glob from 'glob'
import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'
import vue from '@vitejs/plugin-vue'
import { exec } from 'child_process'


// NEED THIS TO ADD AN index.html if we get a raw path
// This is because the dev server sometimes randomly doesn't find index.html
// by default and gives a 404 instead.  But it always works with /index.html 
// on the end.
const middleware = () => {
  return {
    name: 'middleware',
    apply: 'serve',
    configureServer(viteDevServer) {
      return () => {
        viteDevServer.middlewares.use(async (req, res, next) => {
          console.log(req.originalUrl)
          if (!req.originalUrl.endsWith('index.html')) {
            if (req.originalUrl.endsWith('/')) {
              req.url = req.originalUrl + 'index.html'
            } else {
              req.url = req.originalUrl + '/index.html'
            }
          } else {
            req.url = req.originalUrl
          }
          console.log(req.url)
          next()
        })
      }
    },
  }
}

let viteConfig = {
  root: 'modules/farm_fd2/src/entrypoints',
  publicDir: '../public',
  base: '/fd2/',
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
    {
      // This plugin runs after a build and clears the drupal cache so that
      // the live farmos server shows the most recent content.
      name: 'afterBuild',
      closeBundle: async () => {
        await exec('docker exec fd2_farmos drush cr', (error, stderr, stdout) => {
          if (error) {
            console.error(`error:  ${error.message}`)
            return
          }
          if (stderr) {
            console.error(`stderr: ${stderr}`)
            return
          }
          console.log(`Rebuilding drupal cache...\n  ${stdout}`)
        })
      },
    },
    //middleware(),
  ],
  build: {
    outDir: '../../dist',
    emptyOutDir: true,
    exclude: ['**/*.cy.js', '**/*.cy.comp.js', '**/*.cy.unit.js'],
    rollupOptions: {
      input: Object.fromEntries(
        glob
          .sync('modules/farm_fd2/src/entrypoints/*')
          .map((dir) => [path.basename(dir), dir + '/index.html'])
      ),
      output: {
        // Ensures that the entry point and css names are not hashed.
        entryFileNames: '[name]/[name].js',
        assetFileNames: (assetInfo) => {
          let ext = assetInfo.name.split('.').at(1)
          if (ext === 'css') {
            return '[name]/[name].css'
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
      '@comps': fileURLToPath(new URL('../../components/', import.meta.url)),
      '@libs': fileURLToPath(new URL('../../libraries/', import.meta.url)),
    },
  },
}

console.log('Building: ')
console.log(viteConfig.build.rollupOptions.input)

export default defineConfig(viteConfig)
