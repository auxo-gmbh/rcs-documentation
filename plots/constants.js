const randomWalkerDBs = [
    "rw-10",
    "rw-10-fail",
    "rw-25",
    "rw-25-fail",
    "rw-50",
    "rw-50-fail",
    "rw-100",
    "rw-100-fail",
];

const acoDBs = [
    "aco-10",
    "aco-10-fail",
    "aco-25",
    "aco-25-fail",
    "aco-50",
    "aco-50-fail",
    "aco-100",
    "aco-100-fail",
];

const gossipsDBs = [
    "gossips-10",
    "gossips-10-fail",
    "gossips-25",
    "gossips-25-fail",
    "gossips-50",
    "gossips-50-fail",
    "gossips-100",
    "gossips-100-fail",
];

const queueSizes = [5, 10, 15]

module.exports = {
    uri: 'bolt://localhost:7687',
    user: 'neo4j',
    password: 'password',
    algorithms: ['rw', 'aco', 'gossips'],
    databases: [...randomWalkerDBs, ...acoDBs, ...gossipsDBs],
    queueSizes
};
