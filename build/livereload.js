// implement node-livereload over an HTTP or HTTPS connection

function healthcheck() {
    const express = require('express');
    const http = require('http');

    const app = express();
    const router = express.Router();

    router.use((req, res, next) =>{
        res.header('Access-Control-Allow-Methods', 'GET');
        next();
    });

    router.get('/health', (req, res) =>{
        res.status(200).send('Ok');
    });

    app.use('/api/v1', router);

    const hServer = http.createServer(app);
    hServer.listen(3000);
}

// load modules
const livereload = require('livereload');
const fs = require('fs');

// process from environment variable as array and convert elements to RegEx objects
const extraExclusions = process.env.LR_EXCLUDE.split(",");
extraExclusions.forEach((exclusion, idx) => {
    extraExclusions[idx] = new RegExp(exclusion);
});

// set createServer options
const options = {
    port: process.env.LR_PORT,
    exts: process.env.LR_EXTS,
    exclusions: extraExclusions,
    usePolling: true,
    delay: process.env.LR_DELAY,
};

// set debugging output as per LR_DEBUG
if (process.env.LR_DEBUG === "true") {
    options.debug = true
    console.log("[Debug output ENABLED]");
}

// set HTTPS as per LR_HTTPS
if (process.env.LR_HTTPS === "true") {
    options.https = {
        cert: fs.readFileSync('/certs/fullchain.pem'),
        key: fs.readFileSync('/certs/privkey.pem')
    };
    console.log("[HTTPS mode]");
}
else {
    console.log("[HTTP mode]");
}

// start server
const lrServer = livereload.createServer(options, healthcheck);
lrServer.watch('/watch')

//#EOF
