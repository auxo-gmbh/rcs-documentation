const {algorithms, databases} = require("./constants");
const {
    writeBarChartCsvFile, extractAmountNodesByDB,
    convertToRelativeTimestampMap,
    extractAlgByDB,
    writeTimeChartCsvFile
} = require("./utilities");
const {createSession} = require("./database");

const BAR_QUERY = `
MATCH (source:Device)-[s:SENT_TO]->(target:Device)
WHERE s.requestId IS NOT NULL AND source<>target
WITH s.requestId as reqID, collect(s) as requests
WHERE any(request in requests WHERE request.details="RESPONSE")
WITH reqID, requests
UNWIND requests as request
WITH reqID, max(size(request.path)) as pathSize
RETURN avg(pathSize) as value
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
        writeBarChartCsvFile(`data/hops_per_hit/${alg}.csv`, dbResult);

        const dbFailResult = await getBarChartDbResult(alg, true);
        writeBarChartCsvFile(`data/hops_per_hit/${alg}-fail.csv`, dbFailResult);
    }
};

const getTimeChartDbResult = async (db) => {
    const session = createSession(db);
    const queryResult = await session.run(TIME_QUERY);
    const result = queryResult.records
        .map(record => {
            const timestamp = record.get(0).toString();
            const averageServiceTime = record.get(1);
            return {timestamp, averageServiceTime};
        })
        .reduce((map, record) => {
            map[record.timestamp] = record.averageServiceTime;
            return map;
        }, {})
    await session.close();
    return convertToRelativeTimestampMap(result);
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
    await generateBarChartData();
    //await generateTimeChartData();
    console.log('FINISHED')
};

run().then().catch(console.error)
