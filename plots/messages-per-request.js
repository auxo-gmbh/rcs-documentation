const {algorithms, databases} = require("./constants");
const {
    writeBarChartCsvFile, extractAmountNodesByDB,
    convertToRelativeTimestampMap,
    extractAlgByDB,
    writeTimeChartCsvFile
} = require("./utilities");
const {createSession} = require("./database");

const BAR_QUERY = `
MATCH (source: Device)-[r:SENT_TO]->(target: Device) 
WHERE source <> target AND r.requestId IS NOT NULL
WITH r.requestId as reqID, count(r) as n
RETURN avg(n) as value
`

const MAX_TIMESTAMP_PER_REQUEST_QUERY = `
MATCH (source: Device)-[request:SENT_TO]->(target: Device) 
WHERE source <> target AND request.requestId IS NOT NULL
RETURN DISTINCT request.requestId as reqID, max(request.sentAt) as time
ORDER BY time
`

const COUNT_MESSAGE_PER_REQUEST_AT_TIMESTAMP_QUERY = `
WITH $time as timestamp
MATCH (source: Device)-[r:SENT_TO]->(target: Device) 
WHERE source <> target AND r.sentAt<=timestamp
WITH timestamp,r.requestId as requestID, count(r) as n
RETURN timestamp, avg(n) as value
`

const getBarChartDbResult = async (alg, isFailureRun) => {
    const result = {};
    const filteredDbs =
        databases
            .filter(db => isFailureRun ? db.endsWith("-fail") : !db.endsWith("-fail"))
            .filter(db => db.startsWith(alg));
    for (const db of filteredDbs) {
        const amountNodes = extractAmountNodesByDB(db);
        const session = createSession(db);
        const queryResult = await session.run(BAR_QUERY);
        result[amountNodes] = queryResult.records[0].get(0);
        await session.close();
    }
    return result;
};

const generateBarChartData = async () => {
    for (const alg of algorithms) {
        const dbResult = await getBarChartDbResult(alg, false);
        writeBarChartCsvFile(`data/messages_per_request/${alg}.csv`, dbResult);

        const dbFailResult = await getBarChartDbResult(alg, true);
        writeBarChartCsvFile(`data/messages_per_request/${alg}-fail.csv`, dbFailResult);
    }
};

const getTimeChartDbResult = async (db) => {
    let session = createSession(db);
    const requestIdMaxSentAtQueryResult = await session.run(MAX_TIMESTAMP_PER_REQUEST_QUERY);
    await session.close();
    const result = requestIdMaxSentAtQueryResult.records
        .map(record => ({
            requestId: record.get(0),
            time: record.get(1).toNumber(),
        }))
    const map = {}
    for (const record of result) {
        const {time} = record
        session = createSession(db);
        const queryResult = await session.run(COUNT_MESSAGE_PER_REQUEST_AT_TIMESTAMP_QUERY, {time})
        await session.close();
        const timestamp = queryResult.records[0].get(0)
        map[timestamp] = queryResult.records[0].get(1)
    }
    return convertToRelativeTimestampMap(map);
}

const generateAverageTimeChartData = async (db, dbResult) => {
    const session = createSession(db);
    const averageQueryResult = await session.run(BAR_QUERY);
    const averageValue = averageQueryResult.records[0].get(0);
    await session.close();
    const map = {}
    Object
        .entries(dbResult)
        .map(([timestamp, _]) => map[timestamp] = averageValue);
    return map;
};

const generateTimeChartData = async () => {
    for (const db of databases) {
        if (!db.startsWith("gossips-100-fail")) {
            continue;
        }
        const alg = extractAlgByDB(db);
        const amountNodes = extractAmountNodesByDB(db);
        const dbResult = await getTimeChartDbResult(db);
        const averageDbResult = await generateAverageTimeChartData(db, dbResult);
        if (db.endsWith("-fail")) {
            writeTimeChartCsvFile(`data/messages_per_request/${alg}-n${amountNodes}-time-fail.csv`, dbResult);
            writeTimeChartCsvFile(`data/messages_per_request/${alg}-n${amountNodes}-time-fail-average.csv`, averageDbResult);
        } else {
            writeTimeChartCsvFile(`data/messages_per_request/${alg}-n${amountNodes}-time.csv`, dbResult);
            writeTimeChartCsvFile(`data/messages_per_request/${alg}-n${amountNodes}-time-average.csv`, averageDbResult);
        }
        console.log(`Finished with ${db}`)
    }
};

const run = async () => {
    // await generateBarChartData();
    await generateTimeChartData();
    console.log('FINISHED')
};

run().then().catch(console.error)
