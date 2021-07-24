// implement node-livereload over an HTTPS connection

// load livereload module
let livereload = require('livereload');

// set createServer options
const fs = require('fs');
const options = {
    port: process.env.LR_PORT,
    exts: process.env.LR_EXTS,
    exclusions: process.env.LR_EXCLUDE,
    usePolling: true,
    delay: process.env.LR_DELAY,
};

// set debugging output as per LR_DEBUG
if (process.env.LR_DEBUG === "true") {
    options.debug = true
}

// set HTTPS as per LR_HTTPS
if (process.env.LR_HTTPS === "true") {
    options.https = {
        cert: fs.readFileSync('/certs/fullchain.pem'),
        key: fs.readFileSync('/certs/privkey.pem')
    };
}

// start server
let server = livereload.createServer(options);
server.watch('/watch')

//#EOF
