const neo4j = require('neo4j-driver');
const {uri, user, password} = require("./constants");

const driver = neo4j.driver(uri, neo4j.auth.basic(user, password));

const createSession = (database = 'neo4j') => {
    return driver.session({ database });
}

module.exports = { createSession };
