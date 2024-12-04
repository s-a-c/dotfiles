const { exec } = require('child_process');
const sanitize = require('sanitize-filename');

class RunGulpBeforeBuildPlugin {
	constructor(options) {
		this.options = options || {};
		this.watchMode = false;
	}

	apply(compiler) {
		const runGulpTask = (compilation, callback) => {
			if (this.watchMode) {
				console.log('Running Gulp task before build in watch mode...');
				const sanitizedTaskName = sanitize(this.options.taskName);
				exec('gulp ' + sanitizedTaskName, (err, stdout, stderr) => {
					if (err) {
						console.error(err);
					} else {
						console.log(stdout);
					}
					callback();
				});
			} else {
				callback();
			};
		};

		compiler.hooks.watchRun.tap('RunGulpBeforeBuildPlugin', () => {
			this.watchMode = true;
		});

		compiler.hooks.beforeCompile.tapAsync('RunGulpBeforeBuildPlugin', runGulpTask);
	};
};

module.exports = RunGulpBeforeBuildPlugin;
