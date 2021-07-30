/*
 Implement node-livereload over HTTP or HTTPS connection with integrated
 health-check, signal handling and graceful socket shutdown.
 */

// load required modules
const livereload = require('livereload');
const fs = require('fs');
const http = require('http');

// health check object
const healthCheck = {
    app: healthCheckApp(),
    server: function () {
        return http.createServer(this.app);
    },
    start: function () {
        this.server().listen(3000);
    },
    stop: function (callback) {
        this.server().close(callback());
    }
};

// set LiveReload server options
const extraExclusions = process.env.LR_EXCLUDE.split(",");
extraExclusions.forEach((exclusion, idx) => {
    extraExclusions[idx] = new RegExp(exclusion);
});

// noinspection SpellCheckingInspection
const lrOptions = {
    port: process.env.LR_PORT,
    exts: process.env.LR_EXTS,
    exclusions: extraExclusions,
    usePolling: true,
    delay: process.env.LR_DELAY
};
if (process.env.LR_DEBUG === 'true') {
    lrOptions.debug = true;
    console.log("[Debug output ENABLED]");
}
if (process.env.LR_HTTPS === 'true') {
    lrOptions.https = {
        cert: fs.readFileSync('/certs/fullchain.pem'),
        key: fs.readFileSync('/certs/privkey.pem')
    };
    console.log("[HTTPS mode]");
}
else {
    console.log("[HTTP mode]");
}

// start LiveReload server
// noinspection JSVoidFunctionReturnValueUsed
const lrServer = livereload.createServer(lrOptions, healthCheck.start());
lrServer.watch('/watch');

// graceful termination on signals
const termSignals = {
    'SIGHUP': 1,
    'SIGINT': 2,
    'SIGTERM': 15
};
const shutdown = async (signal, value) => {
    console.log("shutting down...\n");
    await lrServer.close();
    await healthCheck.stop(() => {
        console.log("health-check STOPPED\n");
    });
    console.log(`server stopped after receiving ${signal}(${value}).`);
}
// iterate signals and create listener for each
Object.keys(termSignals).forEach((signal) => {
    process.on(signal, () => {
        console.log("\n! received signal:", signal, " !");
        shutdown(signal, termSignals[signal]).then(() => {
            process.exit(128 + termSignals[signal]);
        });
    });
});


//
// functions

function healthCheckApp() {
    const express = require('express');
    const app = express();
    const router = express.Router();

    router.use((req, res, next) => {
        res.header('Access-Control-Allow-Methods', 'GET');
        next();
    });
    router.get('/health', (req, res) => {
        res.status(200).send('Ok');
    });
    return app.use('/api/v1', router);
}
