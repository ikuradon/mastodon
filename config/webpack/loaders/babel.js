const { resolve } = require('path');

const env = process.env.NODE_ENV || 'development';

module.exports = {
  test: /\.js$/,
  // include react-intl because transform-react-remove-prop-types needs to apply to it
  exclude: {
    test: /node_modules/,
    exclude: /react-intl[\/\\](?!locale-data)/,
  },
  loader: 'happypack/loader',
  options: {
    forceEnv: env,
    cacheDirectory: env === 'development' ? false : resolve(__dirname, '..', '..', '..', 'tmp', 'cache', 'babel-loader'),
  },
};
