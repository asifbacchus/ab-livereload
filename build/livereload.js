// implement node-livereload over an HTTPS connection

// load livereload module
let livereload = require('livereload');

// set createServer options
const https = require('https');
const fs = require('fs');
const options = {
    https: {
        cert: fs.readFileSync('/certs/fullchain.pem'),
        key: fs.readFileSync('/certs/privkey.pem')
    },
    port: process.env.LR_PORT,
    exts: process.env.LR_EXTS,
    exclusions: process.env.LR_EXCLUDE,
    usePolling: true,
    delay: process.env.LR_DELAY
};

// start server
let server = livereload.createServer(options);
server.watch('/watch')

//#EOF
