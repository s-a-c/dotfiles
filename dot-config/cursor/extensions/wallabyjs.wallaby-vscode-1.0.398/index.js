const vscode = require('vscode');
const path = require('path');

exports.activate = function (context) {
  const debugMode =
    vscode.workspace.getConfiguration() && vscode.workspace.getConfiguration().get('wallaby.debug', false);
  if (debugMode) {
    global.originalRequire = require;

    require('ts-node').register({
      swc: true,
      transpileOnly: true,
      project: path.join(path.relative(process.cwd(), __dirname), 'tsconfig.json'),
      ignore: ['(?:^|/)../', '(?:^|/)node_modules/'],
    });
  }

  return debugMode || path.basename(__dirname) === 'dist'
    ? require('./extension').activate(context)
    : ((global.originalRequire = require), require('./dist' + '/index').activate(context));
};
