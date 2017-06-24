// Note: You must restart bin/webpack-dev-server for changes to take effect

const webpack = require('webpack');
const merge = require('webpack-merge');
const CompressionPlugin = require('compression-webpack-plugin');
const BrotliPlugin = require('brotli-webpack-plugin');
const sharedConfig = require('./shared.js');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = merge(sharedConfig, {
  output: { filename: '[name]-[chunkhash].js' },
  devtool: 'source-map', // separate sourcemap file, suitable for production
  stats: 'normal',

  plugins: [
    new webpack.optimize.ModuleConcatenationPlugin(),
    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true,
      mangle: true,

      compress: {
        warnings: false,
      },

      output: {
        comments: false,
      },
    }),
    new CompressionPlugin({
      asset: '[path].gz[query]',
      algorithm: 'zopfli',
      test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/,
    }),
    new BrotliPlugin({
      asset: '[path].br[query]',
      test: /\.(js|css|html|json|ico|svg|eot|otf|ttf)$/,
      threshold: 10240,
      minRatio: 0.8,
    }),
    new BundleAnalyzerPlugin({ // generates report.html and stats.json
      analyzerMode: 'static',
      generateStatsFile: true,
      statsOptions: {
        // allows usage with http://chrisbateman.github.io/webpack-visualizer/
        chunkModules: true,
      },
      openAnalyzer: false,
      logLevel: 'silent', // do not bother Webpacker, who runs with --json and parses stdout
    }),
  ],
});
